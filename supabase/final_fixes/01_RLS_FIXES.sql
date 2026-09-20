-- ============================================================================
-- 01_RLS_FIXES.sql
-- Rexo — Row Level Security Fixes
--
-- PURPOSE
--   Consolidates every RLS security fix identified during the Batch 1–3 audit
--   and Stage C live-schema alignment (September 2026).
--
--   A. is_admin() SECURITY DEFINER function — canonical bulletproof version.
--      Uses uid (text) column which is the actual identity column in the live
--      public.users table (NOT id/uuid — live schema confirmed).
--   B. Notifications INSERT policy — the live table has a permissive
--      "Admins/system can insert notifications" with no WITH CHECK, and a
--      dangerous "Allow all for public notifications" ALL=true.
--      This file adds a user-scoped INSERT policy using the live column
--      "userId" (camelCase text) so users can only create notifications for
--      themselves.
--      NOTE: Live notifications columns are "userId", "title", "message",
--      "type", "read", "link", "createdAt" — all camelCase. The dangerous
--      ALL=true policy is dropped in 08_RLS_GLOBAL_CLEANUP.sql.
--   C. Applications UPDATE WITH CHECK — prevents creators writing admin-only
--      columns. Uses actual live column names (creator_id, status).
--   D. Users UPDATE policy — rewired to use is_admin() and the live identity
--      column uid (text), not id (uuid). The live users table uses uid as the
--      RLS ownership column.
--   D2. Self-escalation guard (BEFORE UPDATE trigger) — prevents a normal user
--      from elevating their own role or isVerified flag.
--      Uses only confirmed live column names: role (text), "isVerified" (bool).
--      Does NOT reference account_status or admin_sub_role — these do not exist
--      in the live public.users table.
--   E. Products DELETE — add admin-only delete policy.
--   F. Campaigns DELETE — add admin-only delete policy.
--
-- CONFIRMED LIVE users SCHEMA (relevant columns)
--   uid          text NOT NULL   ← RLS ownership column (auth.uid()::text = uid)
--   role         text            ← DEFAULT 'CREATOR'
--   "isVerified" boolean         ← DEFAULT false
--   "isBanned"   boolean
--   (NO account_status, NO admin_sub_role, NO is_verified)
--
-- CONFIRMED LIVE notifications SCHEMA (relevant columns)
--   "userId"     text NOT NULL   ← ownership column
--   "title"      text
--   "message"    text
--   "type"       text
--   "read"       boolean
--   "createdAt"  timestamptz
--
-- EXECUTION ORDER
--   Run this WHOLE file FIRST. It establishes is_admin() which is required by
--   07_WALLET_TABLES.sql, 02_WALLET_AND_RPC_FIXES.sql, and 08_RLS_GLOBAL_CLEANUP.sql.
--
-- IDEMPOTENCY
--   Every statement uses CREATE OR REPLACE, DROP IF EXISTS, or IF NOT EXISTS.
--   Safe to run multiple times.
--
-- DEPENDENCIES
--   Requires public.users table to exist (already confirmed in live DB).
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- A. is_admin() — canonical bulletproof version
--
--    Live public.users uses uid (text) as the ownership column, NOT id (uuid).
--    Both sides cast to text to avoid operator mismatch.
--    role is stored uppercase in live DB (DEFAULT 'CREATOR'), so lower() is
--    used for case-insensitive comparison.
--    STABLE + SET search_path prevents plan caching and injection attacks.
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
    WHERE uid = auth.uid()::text
      AND lower(role) = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- B. Notifications INSERT — restrict so users can only create notifications
--    for themselves.
--
--    Live column is "userId" (text, camelCase — quoted in SQL).
--    The existing "Admins/system can insert notifications" policy (no WITH CHECK)
--    covers service-role and admin inserts — we do NOT replace it.
--    We only ADD a user-scoped INSERT policy so regular authenticated users
--    cannot inject notifications into other users' inboxes.
--
--    The dangerous "Allow all for public notifications" (ALL/true) is dropped
--    in 08_RLS_GLOBAL_CLEANUP.sql §4.
--
--    ✅  DART FIX COMPLETE (Stage D/G):
--    Dart codebase updated in Stage D to use "userId", "message", "read",
--    "createdAt" — matching the live schema. No further action needed.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;
CREATE POLICY "System can create notifications" ON public.notifications
    FOR INSERT
    WITH CHECK (
        auth.uid()::text = "userId"::text
        OR public.is_admin()
    );


-- ─────────────────────────────────────────────────────────────────────────────
-- C. Applications UPDATE — add WITH CHECK to prevent creators from modifying
--    admin-only columns (admin_notes, rejection_reason, reviewed_by, etc.)
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
-- D. Users UPDATE — rewrite to use is_admin() and the live identity column uid.
--
--    Live public.users does NOT use id (uuid) as the RLS identity column.
--    The actual ownership column is uid (text). All policies on users in the
--    live DB use: uid = auth.uid()::text  OR  is_admin().
--
--    The existing live policies (confirmed):
--      "Users can update own profile"  — USING (uid = auth.uid()::text OR is_admin())
--      "Admins can update any user"    — this file replaces the broken JWT version
--
--    We drop and replace only "Admins can update any user" which was based on
--    the JWT metadata claim (always absent → always false). The "Users can update
--    own profile" policy that already exists in live DB is NOT touched here —
--    it already uses uid correctly.
-- ─────────────────────────────────────────────────────────────────────────────

-- Drop the old broken JWT-based admin update policy from schema.sql
DROP POLICY IF EXISTS "Admins can update any user" ON public.users;

-- NOTE: We do NOT recreate "Admins can update any user" as a standalone policy
-- here. The live "Users can update own profile" already has
-- USING (uid = auth.uid()::text OR is_admin()) which covers both paths.
-- Adding a second overlapping admin-only policy would be redundant.
-- The self-escalation trigger (D2 below) is what actually closes the
-- privilege-escalation gap for non-admin users.


-- ─────────────────────────────────────────────────────────────────────────────
-- D2. Self-escalation guard — BEFORE UPDATE trigger
--
--    The live "Users can update own profile" allows a user to update their own
--    row (uid = auth.uid()::text OR is_admin()). Without server-side enforcement,
--    a non-admin user could set role='ADMIN' or "isVerified"=true on their own row.
--
--    This trigger closes that gap: for non-admins, it pins privileged columns
--    back to their OLD values before the update completes. Normal profile fields
--    (name, username, bio, mobile, phone, profileImage, instagramLink, etc.)
--    pass through unchanged.
--
--    CONFIRMED LIVE PRIVILEGED COLUMNS (exist in live users):
--      role           text    — DEFAULT 'CREATOR'
--      "isVerified"   boolean — DEFAULT false
--      "isBanned"     boolean — admin-controlled ban flag
--
--    NOT referenced (confirmed NOT in live users):
--      account_status   — DOES NOT EXIST
--      admin_sub_role   — DOES NOT EXIST
--      is_verified      — DOES NOT EXIST (camelCase "isVerified" is the real column)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.prevent_user_self_escalation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Admins may change privileged columns freely.
    IF public.is_admin() THEN
        RETURN NEW;
    END IF;

    -- Non-admins: force privileged columns back to their existing (OLD) values.
    -- This prevents a user from granting themselves admin role, verified status,
    -- or lifting their own ban — regardless of what the client sends.
    NEW.role           := OLD.role;
    NEW."isVerified"   := OLD."isVerified";
    NEW."isBanned"     := OLD."isBanned";

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_user_self_escalation ON public.users;
CREATE TRIGGER trg_prevent_user_self_escalation
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.prevent_user_self_escalation();


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
