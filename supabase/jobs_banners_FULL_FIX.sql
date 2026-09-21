-- ============================================================================
-- FULL FIX for Jobs + Banners "not found" errors
-- Run this ENTIRE script in Supabase SQL Editor.
--
-- ROOT CAUSE: the RLS policies on jobs/job_applications/banners call
-- public.is_admin(). If that function was never created (fix_admin_rls.sql
-- not run), EVERY policy that references it errors out, and both SELECT and
-- INSERT fail with a "not found" / permission error.
--
-- This script:
--   1. (Re)creates is_admin() so it always exists
--   2. Ensures the three tables exist
--   3. Drops & recreates all policies cleanly
--   4. Re-adds the slot + updated_at triggers
-- Idempotent: safe to run multiple times.
-- ============================================================================

-- ─── 1. ADMIN HELPER (must exist before any policy uses it) ──────────────────
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ─── 2. JOBS TABLE ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  category text,
  payment_amount numeric NOT NULL CHECK (payment_amount > 0),
  max_slots integer CHECK (max_slots IS NULL OR max_slots > 0),
  deadline timestamptz,
  cover_image_url text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','closed','draft')),
  created_by uuid NOT NULL REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.job_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'applied'
    CHECK (status IN ('applied','submitted','approved','rejected')),
  submission_type text CHECK (submission_type IN ('link','photo','pdf','video')),
  submission_url text,
  submission_note text,
  rejection_reason text,
  applied_at timestamptz NOT NULL DEFAULT now(),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid REFERENCES public.users(id),
  UNIQUE (job_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.banners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text,
  image_url text NOT NULL,
  link_type text CHECK (link_type IN ('none','campaign','page')),
  link_campaign_id uuid REFERENCES public.campaigns(id) ON DELETE SET NULL,
  link_page text,
  is_visible boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_by uuid REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ─── 3. ENABLE RLS ───────────────────────────────────────────────────────────
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;

-- ─── 4. DROP OLD POLICIES ────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Everyone can view active jobs, admins see all" ON public.jobs;
DROP POLICY IF EXISTS "Admins manage all jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users view own applications" ON public.job_applications;
DROP POLICY IF EXISTS "Users insert own applications" ON public.job_applications;
DROP POLICY IF EXISTS "Users update own applications" ON public.job_applications;
DROP POLICY IF EXISTS "Admins manage all applications" ON public.job_applications;
DROP POLICY IF EXISTS "Everyone can view visible banners" ON public.banners;
DROP POLICY IF EXISTS "Admins manage all banners" ON public.banners;

-- ─── 5. JOBS POLICIES ────────────────────────────────────────────────────────
-- Anyone authenticated can read active jobs; admins can read all.
CREATE POLICY "Everyone can view active jobs, admins see all"
  ON public.jobs FOR SELECT
  TO authenticated
  USING (status = 'active' OR public.is_admin());

CREATE POLICY "Admins manage all jobs"
  ON public.jobs FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── 6. JOB APPLICATIONS POLICIES ────────────────────────────────────────────
CREATE POLICY "Users view own applications"
  ON public.job_applications FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users insert own applications"
  ON public.job_applications FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own applications"
  ON public.job_applications FOR UPDATE
  TO authenticated
  USING ((auth.uid() = user_id AND status = 'applied') OR public.is_admin())
  WITH CHECK ((auth.uid() = user_id) OR public.is_admin());

CREATE POLICY "Admins manage all applications"
  ON public.job_applications FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── 7. BANNERS POLICIES ─────────────────────────────────────────────────────
CREATE POLICY "Everyone can view visible banners"
  ON public.banners FOR SELECT
  TO authenticated
  USING (is_visible = true OR public.is_admin());

CREATE POLICY "Admins manage all banners"
  ON public.banners FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── 8. SLOT ENFORCEMENT TRIGGER ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.check_job_slots()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_max_slots integer;
  v_count     integer;
BEGIN
  SELECT max_slots INTO v_max_slots FROM public.jobs WHERE id = NEW.job_id;
  IF v_max_slots IS NOT NULL THEN
    SELECT COUNT(*) INTO v_count
    FROM public.job_applications
    WHERE job_id = NEW.job_id AND status IN ('applied','submitted','approved');
    IF v_count >= v_max_slots THEN
      RAISE EXCEPTION 'This job has no slots remaining.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_job_slots ON public.job_applications;
CREATE TRIGGER enforce_job_slots
  BEFORE INSERT ON public.job_applications
  FOR EACH ROW EXECUTE FUNCTION public.check_job_slots();

-- ─── 9. UPDATED_AT TRIGGERS ──────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_jobs_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

DROP TRIGGER IF EXISTS set_jobs_updated_at ON public.jobs;
CREATE TRIGGER set_jobs_updated_at
  BEFORE UPDATE ON public.jobs
  FOR EACH ROW EXECUTE FUNCTION public.update_jobs_updated_at();

CREATE OR REPLACE FUNCTION public.update_banners_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

DROP TRIGGER IF EXISTS set_banners_updated_at ON public.banners;
CREATE TRIGGER set_banners_updated_at
  BEFORE UPDATE ON public.banners
  FOR EACH ROW EXECUTE FUNCTION public.update_banners_updated_at();

-- ─── 10. INDEXES ─────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS jobs_status_idx ON public.jobs(status);
CREATE INDEX IF NOT EXISTS jobs_category_idx ON public.jobs(category);
CREATE INDEX IF NOT EXISTS jobs_created_at_idx ON public.jobs(created_at DESC);
CREATE INDEX IF NOT EXISTS job_applications_user_id_idx ON public.job_applications(user_id);
CREATE INDEX IF NOT EXISTS job_applications_job_id_idx ON public.job_applications(job_id);
CREATE INDEX IF NOT EXISTS job_applications_status_idx ON public.job_applications(status);
CREATE INDEX IF NOT EXISTS banners_visible_idx ON public.banners(is_visible);
CREATE INDEX IF NOT EXISTS banners_sort_idx ON public.banners(sort_order);

-- ============================================================================
-- VERIFICATION — run these one at a time AFTER the script above:
--
--   -- 1. Confirm is_admin() exists and returns your admin status (must be logged in):
--   SELECT public.is_admin();
--   -- Expected: true  (if you're the admin) — if it errors, is_admin() is missing.
--
--   -- 2. Confirm your user row has role='admin':
--   SELECT id, email, role FROM public.users WHERE id = auth.uid();
--   -- Expected: role = 'admin'.  If it's 'creator', run:
--   --   UPDATE public.users SET role='admin' WHERE email='YOUR_ADMIN_EMAIL';
--
--   -- 3. Confirm policies exist:
--   SELECT tablename, policyname, cmd FROM pg_policies
--   WHERE schemaname='public' AND tablename IN ('jobs','job_applications','banners')
--   ORDER BY tablename, cmd;
-- ============================================================================
