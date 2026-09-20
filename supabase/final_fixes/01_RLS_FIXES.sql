-- ============================================================================
-- 01_RLS_FIXES.sql
-- Rexo — Row Level Security Fixes
--
-- PURPOSE
--   Consolidates every RLS security fix identified during the Batch 1–3 audit:
--
--   A. is_admin() SECURITY DEFINER function — the canonical bulletproof version
--      (text-cast on both sides, lower() for case-insensitivity, SET search_path)
--   B. Notifications INSERT policy — was WITH CHECK (TRUE), allowing any
--      authenticated user to inject notifications into any other user's inbox.
--      Fixed: restricted to own user_id OR admin.
--   C. Applications UPDATE WITH CHECK — was missing, allowing creators to write
--      arbitrary columns (admin_notes, rejection_reason, reviewed_by, etc.).
--      Fixed: WITH CHECK restricts to own row AND status IN ('pending','withdrawn').
--   D. Admin user update policy — rewired to use is_admin() instead of JWT
--      metadata claim (which was always absent and silently failing).
--   E. Products DELETE policy — was missing; admins could not delete products.
--   F. Campaigns DELETE policy — was missing; admins could not delete campaigns.
--
-- EXECUTION ORDER
--   Run this WHOLE file first. It establishes is_admin() which is required
--   by 02_WALLET_AND_RPC_FIXES.sql and later files.
--
-- IDEMPOTENCY
--   Every statement uses CREATE OR REPLACE, DROP IF EXISTS, or IF NOT EXISTS.
--   Safe to run multiple times.
--
-- DEPENDENCIES
--   Requires: schema.sql already applied (users, notifications, applications,
--             campaigns, products tables must exist).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- A. is_admin() — canonical bulletproof version
--    Casts both sides to text to avoid the uuid = text 42883 operator mismatch.
--    STABLE + SET search_path = public prevents search-path injection.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id::text = auth.uid()::text
      AND lower(role) = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- B. Notifications INSERT — restrict to own user_id OR admin
--    (was WITH CHECK (TRUE) — allowed any authenticated user to spam any inbox)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;
CREATE POLICY "System can create notifications" ON public.notifications
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        OR public.is_admin()
    );


-- ─────────────────────────────────────────────────────────────────────────────
-- C. Applications UPDATE — add WITH CHECK to prevent creators from
--    modifying admin-only columns (admin_notes, rejection_reason, reviewed_by)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Creators can update own applications" ON public.applications;
CREATE POLICY "Creators can update own applications" ON public.applications
    FOR UPDATE
    USING (auth.uid() = creator_id)
    WITH CHECK (
        auth.uid() = creator_id
        AND status IN ('pending', 'withdrawn')
    );


-- ─────────────────────────────────────────────────────────────────────────────
-- D. Users UPDATE — rewrite to use is_admin() instead of JWT metadata
--    (the JWT 'user_metadata.role' claim is not set by this app; the check
--     always returned false, silently blocking every admin user-management action)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Admins can update any user" ON public.users;
CREATE POLICY "Admins can update any user" ON public.users
    FOR UPDATE
    USING (public.is_admin() OR auth.uid() = id)
    WITH CHECK (public.is_admin() OR auth.uid() = id);


-- ─────────────────────────────────────────────────────────────────────────────
-- E. Products DELETE — add admin-only delete policy (was missing)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Admins can delete products" ON public.products;
CREATE POLICY "Admins can delete products" ON public.products
    FOR DELETE
    USING (public.is_admin());


-- ─────────────────────────────────────────────────────────────────────────────
-- F. Campaigns DELETE — add admin-only delete policy (was missing)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Admins can delete campaigns" ON public.campaigns;
CREATE POLICY "Admins can delete campaigns" ON public.campaigns
    FOR DELETE
    USING (public.is_admin());


-- ─────────────────────────────────────────────────────────────────────────────
-- G. Reload PostgREST schema cache
-- ─────────────────────────────────────────────────────────────────────────────

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
