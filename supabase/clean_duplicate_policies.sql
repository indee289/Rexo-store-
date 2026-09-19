-- ============================================================================
-- CLEAN UP DUPLICATE / CONFLICTING POLICIES on jobs, job_applications, banners
--
-- The pg_policies list showed 14 policies including old duplicates like
-- "Manage jobs policy", "Public view jobs", "Insert applications policy",
-- "View applications policy", "Update applications policy",
-- "Delete applications policy". These were created by an earlier run and may
-- carry conditions that block access. This script removes ALL policies on the
-- three tables and recreates exactly the correct set.
--
-- Run the WHOLE script in Supabase SQL Editor. Idempotent.
-- ============================================================================

-- Make sure is_admin() exists and is case-insensitive
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND lower(role) = 'admin'
  );
$$;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ─── DROP EVERY EXISTING POLICY on the three tables ──────────────────────────
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT policyname, tablename
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('jobs','job_applications','banners')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
  END LOOP;
END $$;

-- ─── RECREATE CORRECT POLICIES ───────────────────────────────────────────────
-- JOBS
CREATE POLICY "jobs_select" ON public.jobs
  FOR SELECT TO authenticated
  USING (status = 'active' OR public.is_admin());

CREATE POLICY "jobs_admin_all" ON public.jobs
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- JOB APPLICATIONS
CREATE POLICY "japp_select" ON public.job_applications
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "japp_insert" ON public.job_applications
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "japp_update" ON public.job_applications
  FOR UPDATE TO authenticated
  USING ((auth.uid() = user_id AND status = 'applied') OR public.is_admin())
  WITH CHECK ((auth.uid() = user_id) OR public.is_admin());

CREATE POLICY "japp_admin_all" ON public.job_applications
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- BANNERS
CREATE POLICY "banners_select" ON public.banners
  FOR SELECT TO authenticated
  USING (is_visible = true OR public.is_admin());

CREATE POLICY "banners_admin_all" ON public.banners
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─── VERIFY — should now show EXACTLY 8 rows ─────────────────────────────────
-- SELECT tablename, policyname, cmd FROM pg_policies
-- WHERE schemaname='public' AND tablename IN ('jobs','job_applications','banners')
-- ORDER BY tablename, cmd;
--
-- Expected:
--   banners          | banners_admin_all | ALL
--   banners          | banners_select    | SELECT
--   job_applications | japp_admin_all    | ALL
--   job_applications | japp_insert       | INSERT
--   job_applications | japp_select       | SELECT
--   job_applications | japp_update       | UPDATE
--   jobs             | jobs_admin_all    | ALL
--   jobs             | jobs_select       | SELECT
-- ============================================================================
