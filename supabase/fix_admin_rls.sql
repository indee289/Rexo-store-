-- ============================================================================
-- FIX: Admin write actions (Verify / Suspend / Ban / Change Role / Delete
--      Product) were silently failing because of Row Level Security.
--
-- ROOT CAUSES
--   1) The "Admins can update any user" policy checked the admin role from the
--      JWT: (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'.
--      The app stores role in the users.role COLUMN, not in auth user_metadata,
--      so that claim is absent -> the policy evaluated FALSE -> every admin
--      UPDATE on another user's row was blocked (0 rows changed, no error).
--   2) The products table had SELECT / INSERT / UPDATE policies but NO DELETE
--      policy, so admin "Delete Product" (a hard DELETE) was always blocked.
--
-- FIX STRATEGY (secure, minimal, RLS stays ON)
--   - Add a SECURITY DEFINER helper `public.is_admin()` that reads users.role
--     for the current auth.uid(). SECURITY DEFINER runs as the function owner
--     and bypasses RLS on `users`, so using it inside a policy ON `users` does
--     NOT cause infinite recursion (the reason the JWT hack was used before).
--   - Rewrite the users UPDATE policy to use is_admin() (admins) OR self.
--   - Add an admin DELETE policy for products.
--
-- This does NOT disable RLS, does NOT make anything public, and does NOT trust
-- any client-side flag. Only a user whose users.role = 'admin' passes is_admin().
--
-- Idempotent: safe to run multiple times.
-- ============================================================================

-- 1) Admin check helper -------------------------------------------------------
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

-- Allow authenticated clients to execute the helper (it only returns a boolean
-- about the *current* user; it never leaks other rows).
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- 2) Users: admins can update ANY user; everyone can still update themselves ---
DROP POLICY IF EXISTS "Admins can update any user" ON public.users;
CREATE POLICY "Admins can update any user" ON public.users
    FOR UPDATE
    USING (public.is_admin() OR auth.uid() = id)
    WITH CHECK (public.is_admin() OR auth.uid() = id);

-- 3) Products: allow admins to DELETE (previously no DELETE policy existed) ----
DROP POLICY IF EXISTS "Admins can delete products" ON public.products;
CREATE POLICY "Admins can delete products" ON public.products
    FOR DELETE
    USING (public.is_admin());

-- ============================================================================
-- VERIFICATION (run these AFTER applying, logged in as an admin account):
--
--   -- Should return true when the current session is an admin:
--   SELECT public.is_admin();
--
--   -- Confirms the policies exist:
--   SELECT policyname, cmd FROM pg_policies
--   WHERE schemaname = 'public' AND tablename IN ('users','products')
--   ORDER BY tablename, policyname;
--
--   -- Real admin action test (replace the UUID with a real target user):
--   UPDATE public.users SET is_verified = true WHERE id = '<target-user-uuid>';
--   -- Expect: UPDATE 1  (row actually changed). Before the fix this was 0.
-- ============================================================================
