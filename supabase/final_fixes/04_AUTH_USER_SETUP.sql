-- ============================================================================
-- 04_AUTH_USER_SETUP.sql
-- Rexo — Auth ↔ Public Users Synchronisation
--
-- PURPOSE
--   Ensures every auth.users signup automatically creates a row in public.users
--   AND a wallet row. Without this trigger, new signups see empty profile
--   screens and wallet queries fail.
--
-- CONFIRMED LIVE public.users SCHEMA (columns used by this file)
--   uid          text NOT NULL   — RLS identity column (auth.uid()::text = uid)
--   id           uuid            — primary key (references auth.users.id)
--   email        text NOT NULL
--   name         text NOT NULL
--   role         text            — DEFAULT 'CREATOR' (stored uppercase)
--
--   COLUMNS THAT DO NOT EXIST IN LIVE DB — do not reference:
--     account_status  — DOES NOT EXIST
--     admin_sub_role  — DOES NOT EXIST
--     is_verified     — DOES NOT EXIST (live column is "isVerified")
--
--   NOTE ON ADMIN SETUP (Step 5):
--   The live admin account setup only sets `role` and `"isVerified"`.
--   `admin_sub_role` does not exist in the live schema and is omitted.
--   `"isVerified"` is the camelCase live column; it must be double-quoted.
--
-- IDEMPOTENCY
--   CREATE OR REPLACE FUNCTION, DROP TRIGGER IF EXISTS, INSERT ... ON CONFLICT.
--   Safe to run multiple times.
--
-- DEPENDENCIES
--   01_RLS_FIXES.sql must run first (is_admin() and correct users policies).
--   07_WALLET_TABLES.sql must run first (wallets table must exist for Step 4).
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 1 — Ensure users.name has a safe default so the trigger never fails
--          if the auth user has no display name metadata.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.users ALTER COLUMN name SET DEFAULT '';


-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 2 — Trigger function: create public.users row on auth signup
--
--    Inserts into only the columns that are confirmed to exist in the live
--    public.users table. Does NOT reference account_status, admin_sub_role,
--    or is_verified.
--
--    The uid column (text) receives the auth user's UUID cast to text.
--    The id column (uuid) receives the auth user's UUID directly.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.users (id, uid, email, name, role)
    VALUES (
        NEW.id,
        NEW.id::text,
        NEW.email,
        COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            split_part(NEW.email, '@', 1)
        ),
        COALESCE(NEW.raw_user_meta_data->>'role', 'CREATOR')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_auth_user();


-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 3 — Wallet auto-creation is handled by 07_WALLET_TABLES.sql.
--          handle_new_user_wallet() and its trigger already exist in live DB.
--          No duplicate definition here.
-- ─────────────────────────────────────────────────────────────────────────────


-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 4 — Backfill: create public.users rows for existing auth users
--          who do not yet have a profile row.
--
--          Only inserts confirmed live columns. ON CONFLICT (id) DO NOTHING
--          ensures existing rows are never overwritten.
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO public.users (id, uid, email, name, role)
SELECT
    au.id,
    au.id::text,
    au.email,
    COALESCE(
        au.raw_user_meta_data->>'full_name',
        au.raw_user_meta_data->>'name',
        split_part(au.email, '@', 1)
    ),
    'CREATOR'
FROM auth.users au
LEFT JOIN public.users pu ON pu.id = au.id
WHERE pu.id IS NULL
ON CONFLICT (id) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 5 — Backfill: create wallets for any users missing one
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO public.wallets (user_id)
SELECT u.id
FROM public.users u
LEFT JOIN public.wallets w ON w.user_id = u.id
WHERE w.id IS NULL
ON CONFLICT (user_id) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 6 — Set admin role for the platform admin account
--
--   Sets only confirmed live columns: role and "isVerified" (camelCase, quoted).
--   Does NOT set admin_sub_role (column does not exist in live DB).
--   Does NOT set is_verified (column does not exist; camelCase "isVerified" used).
--
--   ⚠️  This uses UPDATE with a known email. It is NOT a security boundary —
--   the actual enforcement is done by is_admin() in RLS. Idempotent.
--
--   ⚠️  DART FIX COMPLETE (Stage D/G):
--   Dart admin screens now use "isVerified", "isBanned", and .eq('uid', ...).
--   All Dart-side schema mismatches against public.users have been resolved.
-- ─────────────────────────────────────────────────────────────────────────────

UPDATE public.users
SET
    role           = 'admin',
    "isVerified"   = true
WHERE email = 'rexoagency.in@gmail.com';
