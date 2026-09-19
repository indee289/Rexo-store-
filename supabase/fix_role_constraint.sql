-- ============================================================================
-- FIX: users_role_check keeps failing.
--
-- ROOT CAUSE: some rows store role in a case/whitespace form NOT in the
-- allowed set, e.g. 'ADMIN' or 'Creator'. The CHECK is:
--     role IN ('creator','brand','admin')
-- so ANY update that re-validates such a row fails with 23514 — even an
-- unrelated update, because Postgres re-checks the whole row.
--
-- STRATEGY (safe, ordered so no step ever violates the live constraint):
--   1. DROP the CHECK constraint (so we can clean the data freely).
--   2. Normalize every role to a valid lowercase value; anything unknown
--      falls back to 'creator'.
--   3. RE-ADD the CHECK constraint.
--   4. (Re)create the case-insensitive is_admin().
-- Idempotent: safe to run multiple times.
-- ============================================================================

-- 1) Remove the constraint so cleaning can't trip it
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;

-- 2) Normalize all role values to the canonical lowercase set
UPDATE public.users
SET role = CASE
  WHEN lower(trim(role)) = 'admin'   THEN 'admin'
  WHEN lower(trim(role)) = 'brand'   THEN 'brand'
  WHEN lower(trim(role)) = 'creator' THEN 'creator'
  ELSE 'creator'   -- fallback for any unexpected value
END;

-- 3) Re-add the constraint now that data is clean
ALTER TABLE public.users
  ADD CONSTRAINT users_role_check
  CHECK (role IN ('creator','brand','admin'));

-- 4) Ensure the admin account is 'admin'
UPDATE public.users
SET role = 'admin'
WHERE email = 'rexoagency.in@gmail.com'
  AND role <> 'admin';

-- 5) Case-insensitive is_admin() (defensive; role is now lowercase anyway)
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
-- VERIFY:
--   SELECT email, role FROM public.users WHERE email = 'rexoagency.in@gmail.com';
--   -- role must be exactly 'admin' (lowercase)
--
--   SELECT DISTINCT role FROM public.users;
--   -- must only show: creator, brand, admin
--
-- Then test INSIDE THE APP (SQL Editor's is_admin() is always false there).
-- ============================================================================
