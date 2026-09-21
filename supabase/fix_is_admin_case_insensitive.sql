-- ============================================================================
-- FIX: is_admin() returned false even for the 'ADMIN' user because the
-- function compared against lowercase 'admin'.
--
-- NOTE: We do NOT bulk-lowercase every row (a previous attempt hit
-- users_role_check because some rows hold values outside the allowed set).
-- Instead we make is_admin() itself case-insensitive, which is all that's
-- needed, and fix ONLY the known admin account.
-- Idempotent: safe to run multiple times.
-- ============================================================================

-- 1) Case-insensitive admin check (the real fix — no table-wide update needed)
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

-- 2) Ensure the admin account's role is the canonical lowercase 'admin'.
--    Scoped to the single admin email so it can't trip the role CHECK for
--    any other row.
UPDATE public.users
SET role = 'admin'
WHERE email = 'rexoagency.in@gmail.com'
  AND role <> 'admin';

-- ============================================================================
-- TESTING:
-- "SELECT public.is_admin();" in the SQL Editor returns FALSE for everyone
-- (auth.uid() is NULL there). The real test is inside the app: log in with the
-- admin email; Jobs / Manage Jobs / Post Job / Banners should now work.
--
-- Verify the admin row directly:
--   SELECT email, role FROM public.users WHERE email = 'rexoagency.in@gmail.com';
--   -- role must be 'admin'
-- ============================================================================
