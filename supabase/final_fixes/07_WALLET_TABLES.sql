-- ============================================================================
-- 07_WALLET_TABLES.sql
-- Rexo — Wallet, Deposits, and Withdrawals Tables
--
-- PURPOSE
--   The three core financial tables that the Flutter app depends on.
--
-- LIVE DB STATE (confirmed September 2026)
--   wallets, deposits, and withdrawals ALL EXIST in the live database.
--   CREATE TABLE IF NOT EXISTS is used so this file is safe to re-run —
--   table creation is silently skipped when the table already exists.
--
--   Confirmed live schemas:
--     wallets:     id, user_id, available_balance, escrow_balance,
--                  total_earnings, total_withdrawn, is_frozen, currency,
--                  created_at, updated_at
--     deposits:    id, user_id, amount, payment_method, transaction_ref,
--                  proof_url, status, admin_notes, created_at, processed_at
--     withdrawals: id, user_id, amount, method, payout_details (JSONB),
--                  status, transaction_ref, admin_notes, created_at, processed_at
--
-- EXISTING LIVE POLICIES (confirmed — these already exist, do not duplicate)
--   wallets:
--     "Users can read own wallet"      SELECT  auth.uid() = user_id
--     "Admins can read all wallets"    SELECT  is_admin()
--     "Admins can update wallets"      UPDATE  is_admin()
--   deposits:
--     "Users can read own deposits"    SELECT  auth.uid() = user_id
--     "Admins can read all deposits"   SELECT  is_admin()
--     "Users can create deposits"      INSERT  no WITH CHECK   ← SECURITY GAP
--     "Admins can update deposits"     UPDATE  is_admin()
--   withdrawals:
--     "Users can read own withdrawals" SELECT  auth.uid() = user_id
--     "Admins can read all withdrawals"SELECT  is_admin()
--     "Users can create withdrawals"   INSERT  no WITH CHECK   ← SECURITY GAP
--     "Admins can update withdrawals"  UPDATE  is_admin()
--
-- SECURITY GAPS FIXED BY THIS FILE
--   "Users can create deposits" and "Users can create withdrawals" have no
--   WITH CHECK clause in the live DB, meaning a user could insert a
--   deposit/withdrawal on behalf of another user by passing a different
--   user_id. This file uses DROP + CREATE to add WITH CHECK (auth.uid() = user_id).
--
--   The Dart client explicitly passes user_id in both insert payloads
--   (confirmed in wallet_provider.dart). The WITH CHECK enforces this
--   server-side so the field cannot be forged.
--
-- IDEMPOTENCY
--   All CREATE TABLE use IF NOT EXISTS.
--   All CREATE POLICY use DROP POLICY IF EXISTS immediately before.
--   Safe to run multiple times.
--
-- DEPENDENCIES
--   01_RLS_FIXES.sql must run first (defines public.is_admin()).
--   Correct order: 01 → 07 → 02 → 08 (see README.md).
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: wallets
--   CREATE TABLE IF NOT EXISTS — silently skipped if already exists.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.wallets (
    id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID          NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    available_balance DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    escrow_balance    DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_earnings    DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_withdrawn   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    is_frozen         BOOLEAN       NOT NULL DEFAULT FALSE,
    currency          TEXT          NOT NULL DEFAULT 'INR',
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON public.wallets(user_id);

ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

-- Wallets policies — existing live policies are preserved by using
-- DROP IF EXISTS + CREATE so they are refreshed idempotently.
-- These match what already exists in the live DB (confirmed).

DROP POLICY IF EXISTS "Users can read own wallet" ON public.wallets;
CREATE POLICY "Users can read own wallet" ON public.wallets
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can read all wallets" ON public.wallets;
CREATE POLICY "Admins can read all wallets" ON public.wallets
    FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can update wallets" ON public.wallets;
CREATE POLICY "Admins can update wallets" ON public.wallets
    FOR UPDATE USING (public.is_admin());

-- No INSERT policy: wallets are created only by the trigger below.
-- No DELETE policy: wallets cascade-delete with users.


-- ─────────────────────────────────────────────────────────────────────────────
-- TRIGGER: auto-create wallet for every new user
--   handle_new_user_wallet() already exists in the live DB.
--   CREATE OR REPLACE FUNCTION + DROP/CREATE TRIGGER are safe to re-run.
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

-- Backfill: create wallets for existing users who don't have one yet.
-- ON CONFLICT DO NOTHING makes this safe to re-run.
INSERT INTO public.wallets (user_id)
SELECT u.id
FROM public.users u
LEFT JOIN public.wallets w ON w.user_id = u.id
WHERE w.id IS NULL
ON CONFLICT (user_id) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: deposits
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.deposits (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID          NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount          DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    payment_method  TEXT,
    transaction_ref TEXT,
    proof_url       TEXT,
    status          TEXT          NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes     TEXT,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    processed_at    TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_deposits_user_id ON public.deposits(user_id);
CREATE INDEX IF NOT EXISTS idx_deposits_status  ON public.deposits(status);
CREATE INDEX IF NOT EXISTS idx_deposits_created ON public.deposits(created_at DESC);

ALTER TABLE public.deposits ENABLE ROW LEVEL SECURITY;

-- Deposits policies.
-- "Users can create deposits" had no WITH CHECK in live DB — recreated with one.
-- All others match the live DB exactly and are refreshed idempotently.

DROP POLICY IF EXISTS "Users can read own deposits" ON public.deposits;
CREATE POLICY "Users can read own deposits" ON public.deposits
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can read all deposits" ON public.deposits;
CREATE POLICY "Admins can read all deposits" ON public.deposits
    FOR SELECT USING (public.is_admin());

-- SECURITY FIX: add WITH CHECK so a user cannot forge user_id on insert.
-- Dart client (wallet_provider.dart) already sends the correct user_id —
-- this clause enforces it server-side.
DROP POLICY IF EXISTS "Users can create deposits" ON public.deposits;
CREATE POLICY "Users can create deposits" ON public.deposits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can update deposits" ON public.deposits;
CREATE POLICY "Admins can update deposits" ON public.deposits
    FOR UPDATE USING (public.is_admin());


-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: withdrawals
--
-- Flutter admin writes status 'completed' (NOT 'approved') when approving.
-- status CHECK: pending | processing | completed | rejected
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.withdrawals (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID          NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount          DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    method          TEXT,
    payout_details  JSONB,
    status          TEXT          NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
    transaction_ref TEXT,
    admin_notes     TEXT,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    processed_at    TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_withdrawals_user_id ON public.withdrawals(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawals_status  ON public.withdrawals(status);
CREATE INDEX IF NOT EXISTS idx_withdrawals_created ON public.withdrawals(created_at DESC);

ALTER TABLE public.withdrawals ENABLE ROW LEVEL SECURITY;

-- Withdrawals policies.
-- "Users can create withdrawals" had no WITH CHECK in live DB — recreated with one.

DROP POLICY IF EXISTS "Users can read own withdrawals" ON public.withdrawals;
CREATE POLICY "Users can read own withdrawals" ON public.withdrawals
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can read all withdrawals" ON public.withdrawals;
CREATE POLICY "Admins can read all withdrawals" ON public.withdrawals
    FOR SELECT USING (public.is_admin());

-- SECURITY FIX: add WITH CHECK so a user cannot forge user_id on insert.
DROP POLICY IF EXISTS "Users can create withdrawals" ON public.withdrawals;
CREATE POLICY "Users can create withdrawals" ON public.withdrawals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can update withdrawals" ON public.withdrawals;
CREATE POLICY "Admins can update withdrawals" ON public.withdrawals
    FOR UPDATE USING (public.is_admin());


-- ─────────────────────────────────────────────────────────────────────────────
-- Reload PostgREST schema cache
-- ─────────────────────────────────────────────────────────────────────────────

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
