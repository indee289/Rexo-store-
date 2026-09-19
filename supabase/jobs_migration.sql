-- ============================================================
-- Jobs Feature Migration
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- ─── 1. JOBS TABLE ────────────────────────────────────────────────────────────
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

-- ─── 2. JOB APPLICATIONS TABLE ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.job_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'applied' CHECK (status IN ('applied','submitted','approved','rejected')),
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

-- ─── 3. ROW LEVEL SECURITY ────────────────────────────────────────────────────
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;

-- Jobs policies
CREATE POLICY "Everyone can view active jobs, admins see all" ON public.jobs
  FOR SELECT USING (status = 'active' OR is_admin());
CREATE POLICY "Admins manage all jobs" ON public.jobs
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- Job applications policies
CREATE POLICY "Users view own applications" ON public.job_applications
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own applications" ON public.job_applications
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own applications" ON public.job_applications
  FOR UPDATE USING (auth.uid() = user_id AND status = 'applied');
CREATE POLICY "Admins manage all applications" ON public.job_applications
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- ─── 4. SLOT ENFORCEMENT TRIGGER ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.check_job_slots()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  job_max_slots integer;
  current_count integer;
BEGIN
  SELECT max_slots INTO job_max_slots FROM public.jobs WHERE id = NEW.job_id;

  IF job_max_slots IS NOT NULL THEN
    SELECT COUNT(*) INTO current_count
    FROM public.job_applications
    WHERE job_id = NEW.job_id AND status IN ('applied','submitted','approved');

    IF current_count >= job_max_slots THEN
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

-- ─── 5. UPDATED_AT AUTO-UPDATE TRIGGER ────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_jobs_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_jobs_updated_at ON public.jobs;
CREATE TRIGGER set_jobs_updated_at
  BEFORE UPDATE ON public.jobs
  FOR EACH ROW EXECUTE FUNCTION public.update_jobs_updated_at();

-- ─── 6. PERFORMANCE INDEXES ───────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS jobs_status_idx ON public.jobs(status);
CREATE INDEX IF NOT EXISTS jobs_category_idx ON public.jobs(category);
CREATE INDEX IF NOT EXISTS jobs_created_at_idx ON public.jobs(created_at DESC);
CREATE INDEX IF NOT EXISTS job_applications_user_id_idx ON public.job_applications(user_id);
CREATE INDEX IF NOT EXISTS job_applications_job_id_idx ON public.job_applications(job_id);
CREATE INDEX IF NOT EXISTS job_applications_status_idx ON public.job_applications(status);

-- ─── 7. VERIFICATION QUERY ────────────────────────────────────────────────────
-- Run this after the migration to confirm all policies were created:
--
-- SELECT tablename, policyname, cmd FROM pg_policies
-- WHERE schemaname = 'public' AND tablename IN ('jobs','job_applications')
-- ORDER BY tablename;
--
-- Expected 5 rows:
--   job_applications | Admins manage all applications | ALL
--   job_applications | Users insert own applications  | INSERT
--   job_applications | Users update own applications  | UPDATE
--   job_applications | Users view own applications    | SELECT
--   jobs             | Admins manage all jobs         | ALL
--   jobs             | Everyone can view active jobs, admins see all | SELECT
