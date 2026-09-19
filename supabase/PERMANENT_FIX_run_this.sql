-- ============================================================================
-- PERMANENT FIX — run this ONE script. Copy the WHOLE thing.
--
-- Fixes for good:
--   * ERROR 42883 (uuid = text) — via a current_uid() helper that ALWAYS
--     returns uuid, so no policy ever needs a manual ::uuid cast again.
--   * duplicate/conflicting policies — drops ALL and recreates the correct 8.
--   * is_admin() case-insensitivity.
--
-- Idempotent: safe to run any number of times.
-- ============================================================================

-- 1) Helper: current user id, ALWAYS typed as uuid.
CREATE OR REPLACE FUNCTION public.current_uid()
RETURNS uuid
LANGUAGE sql STABLE
AS $$
  SELECT auth.uid()::uuid;
$$;
GRANT EXECUTE ON FUNCTION public.current_uid() TO authenticated;

-- 2) is_admin() — case-insensitive, uses the uuid helper.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = public.current_uid() AND lower(role) = 'admin'
  );
$$;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- 3) Drop EVERY existing policy on the three tables (kills all duplicates).
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT policyname, tablename FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('jobs','job_applications','banners')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
  END LOOP;
END $$;

-- 4) Recreate exactly the correct 8 policies.
--    All user-id comparisons use current_uid() (uuid) — no cast headaches.

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
  USING (public.current_uid() = user_id OR public.is_admin());

CREATE POLICY "japp_insert" ON public.job_applications
  FOR INSERT TO authenticated
  WITH CHECK (public.current_uid() = user_id);

CREATE POLICY "japp_update" ON public.job_applications
  FOR UPDATE TO authenticated
  USING ((public.current_uid() = user_id AND status = 'applied') OR public.is_admin())
  WITH CHECK ((public.current_uid() = user_id) OR public.is_admin());

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

-- 5) Verify — must show EXACTLY 8 rows.
SELECT tablename, policyname, cmd FROM pg_policies
WHERE schemaname='public' AND tablename IN ('jobs','job_applications','banners')
ORDER BY tablename, cmd;
