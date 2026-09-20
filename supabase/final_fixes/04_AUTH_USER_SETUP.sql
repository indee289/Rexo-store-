-- ============================================================================
-- 04_AUTH_USER_SETUP.sql
-- Rexo — Auth ↔ Public Users Synchronisation
--
-- PURPOSE
--   Ensures every auth.users signup automatically creates a row in public.users
--   AND a wallet row. Without this trigger, new signups see empty profile
--   screens and wallet queries fail.
--
--   Also sets the admin role for the known admin email. The email is NOT a
--   security boundary — the actual security is enforced by is_admin() in RLS.
--
-- IDEMPOTENCY
--   CREATE OR REPLACE FUNCTION, DROP TRIGGER IF EXISTS, INSERT ... ON CONFLICT.
--   Safe to run multiple times.
--
-- DEPENDENCIES
--   01_RLS_FIXES.sql must have been run first (users table must have its
--   correct RLS policies; wallets table must exist).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 1 — Make users.name nullable / default to '' so trigger never fails
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.users ALTER COLUMN name SET DEFAULT '';
ALTER TABLE public.users ALTER COLUMN name DROP NOT NULL;


-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 2 — Trigger function: create public.users row on auth signup
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.users (id, email, name, role, account_status)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            split_part(NEW.email, '@', 1)
        ),
        COALESCE(NEW.raw_user_meta_data->>'role', 'creator'),
        'active'
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
-- STEP 3 — Trigger function: auto-create wallet for every new user
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_user_wallet()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.wallets (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_user_created_create_wallet ON public.users;
CREATE TRIGGER on_user_created_create_wallet
    AFTER INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_wallet();


-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 4 — Backfill: create public.users rows for existing auth users
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO public.users (id, email, name, role, account_status)
SELECT
    au.id,
    au.email,
    COALESCE(
        au.raw_user_meta_data->>'full_name',
        au.raw_user_meta_data->>'name',
        split_part(au.email, '@', 1)
    ),
    'creator',
    'active'
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
--   ⚠️  This uses UPDATE with a known email. It is NOT a security boundary —
--   the actual enforcement is done by is_admin() in RLS. This is a convenience
--   operation only and is idempotent.
-- ─────────────────────────────────────────────────────────────────────────────

UPDATE public.users
SET
    role             = 'admin',
    admin_sub_role   = 'super_admin',
    is_verified      = true
WHERE email = 'rexoagency.in@gmail.com';
