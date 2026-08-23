-- ============================================================================
-- FIX: Admin "Delete Campaign" (a hard DELETE on public.campaigns) was always
--      blocked because the campaigns table has SELECT / INSERT / UPDATE
--      policies but NO DELETE policy under Row Level Security.
--
-- FIX: Add an admin-only DELETE policy that reuses the SECURITY DEFINER helper
--      public.is_admin() defined in supabase/fix_admin_rls.sql. Only a user
--      whose users.role = 'admin' passes is_admin(), so this does NOT open
--      deletes to regular users, does NOT disable RLS, and does NOT trust any
--      client-side flag.
--
-- PREREQUISITE: supabase/fix_admin_rls.sql must have been applied first (it
--      creates public.is_admin()).
--
-- Idempotent: safe to run multiple times.
-- ============================================================================

DROP POLICY IF EXISTS "Admins can delete campaigns" ON public.campaigns;
CREATE POLICY "Admins can delete campaigns" ON public.campaigns
    FOR DELETE
    USING (public.is_admin());

-- ============================================================================
-- VERIFICATION (run AFTER applying, logged in as an admin account):
--
--   -- Confirms the policy exists:
--   SELECT policyname, cmd FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'campaigns'
--   ORDER BY policyname;
--
--   -- Real admin action test (replace the UUID with a real campaign id):
--   DELETE FROM public.campaigns WHERE id = '<campaign-uuid>';
--   -- Expect: DELETE 1  (row actually removed). Before the fix this was 0.
-- ============================================================================
