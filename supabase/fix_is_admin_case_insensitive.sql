-- ============================================================================
-- FIX: is_admin() returned false even for users whose role was 'ADMIN'
-- (uppercase) because the function compared against lowercase 'admin'.
--
-- Two-part fix:
--   1. Normalize any existing role values to lowercase.
--   2. Make is_admin() case-insensitive so it never breaks again.
-- Idempotent: safe to run multiple times.
-- ============================================================================

-- 1) Normalize existing role values to the lowercase form the CHECK expects
UPDATE public.users
SET role = lower(role)
WHERE role <> lower(role);

-- 2) Case-insensitive admin check
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND lower(role) = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ============================================================================
-- NOTE ON TESTING is_admin():
-- Running "SELECT public.is_admin();" in the Supabase SQL Editor will return
-- FALSE even for an admin — because the SQL Editor runs as the postgres role,
-- NOT as your app-authenticated user, so auth.uid() is NULL there.
--
-- The REAL test is inside the app: log in with the admin email and the Jobs /
-- Manage Jobs / Post Job / Banners screens should now load and work.
--
-- To verify the role value in the DB directly:
--   SELECT email, role FROM public.users WHERE email = 'rexoagency.in@gmail.com';
--   -- role must be lowercase 'admin'
-- ============================================================================
