-- ============================================================================
-- PERMANENT FIX (v2) — bulletproof. Copy the WHOLE thing, run once.
--
-- Previous attempts failed with 42883 (uuid = text) no matter which side we
-- cast. The bulletproof approach: cast BOTH sides to text. text = text always
-- works regardless of whether the columns are uuid or text.
--
-- Idempotent: safe to run any number of times.
-- ============================================================================

-- is_admin() — case-insensitive. Compares users.id (text-cast) with auth.uid()
-- (text-cast) so it can never hit a uuid/text mismatch.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id::text = auth.uid()::text AND lower(role) = 'admin'
  );
$$;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- Drop EVERY existing policy on the three tables (removes all duplicates).
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

-- Recreate the correct 8 policies. All user-id comparisons cast BOTH sides to
-- text so no uuid/text operator error is possible.

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
  USING (auth.uid()::text = user_id::text OR public.is_admin());

CREATE POLICY "japp_insert" ON public.job_applications
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "japp_update" ON public.job_applications
  FOR UPDATE TO authenticated
  USING ((auth.uid()::text = user_id::text AND status = 'applied') OR public.is_admin())
  WITH CHECK ((auth.uid()::text = user_id::text) OR public.is_admin());

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

-- Verify — must show EXACTLY 8 rows.
SELECT tablename, policyname, cmd FROM pg_policies
WHERE schemaname='public' AND tablename IN ('jobs','job_applications','banners')
ORDER BY tablename, cmd;
