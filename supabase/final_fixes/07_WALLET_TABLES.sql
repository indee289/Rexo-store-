-- ============================================================================
-- 07_WALLET_TABLES.sql
-- Rexo — Wallet, Deposits, and Withdrawals Tables
--
-- PURPOSE
--   Creates the three core financial tables that the Flutter app depends on.
--   Live Supabase verification confirmed these tables DO NOT EXIST in the live DB.
--   This file creates them with correct schema, constraints, RLS, indexes,
--   and the wallet auto-creation trigger.
--
-- CRITICAL
--   Run this file BEFORE any other file in this package that references
--   wallets, deposits, or withdrawals (including 02_WALLET_AND_RPC_FIXES.sql).
--
-- EXECUTION ORDER: Run AS FIRST FILE (before 01_RLS_FIXES.sql)
--
-- FLUTTER CONTRACT
--   wallet_provider.dart reads:
--     wallets: available_balance, escrow_balance, total_earnings, is_frozen
--     deposits: user_id, amount, payment_method, transaction_ref, proof_url, status, created_at
--     withdrawals: user_id, amount, method, payout_details, status, created_at
--
--   admin_provider.dart writes:
--     deposits: status = 'approved' | 'rejected'
--     withdrawals: status = 'completed' | 'rejected'
--     wallets: is_frozen = true  (via direct UPDATE)
--     wallets: available_balance (via credit_wallet / debit_wallet RPCs)
--
-- IDEMPOTENCY
--   CREATE TABLE IF NOT EXISTS, DROP POLICY IF EXISTS + CREATE POLICY.
--   Safe to run multiple times.
--
-- DEPENDENCIES
--   users table must exist (from schema.sql).
--   Run AFTER 01_RLS_FIXES.sql — the wallet/deposit/withdrawal RLS policies
--   below reference public.is_admin(), which is created in 01_RLS_FIXES.sql.
--   Running this file before 01 fails with "function public.is_admin() does
--   not exist". Correct order: 01 → 07 → 02 → 08 (see README.md).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: wallets
--   One row per user. Tracks available, escrow, and earnings balances.
--   is_frozen: admin can freeze a wallet to block withdrawals.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.wallets (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID        NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    available_balance DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    escrow_balance    DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total_earnings    DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total_withdrawn   DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    is_frozen         BOOLEAN     NOT NULL DEFAULT FALSE,
    currency          TEXT        NOT NULL DEFAULT 'INR',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON public.wallets(user_id);

ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

-- Users can read only their own wallet
DROP POLICY IF EXISTS "Users can read own wallet" ON public.wallets;
CREATE POLICY "Users can read own wallet" ON public.wallets
    FOR SELECT USING (auth.uid() = user_id);

-- Admins can read all wallets (for admin wallet management screen)
DROP POLICY IF EXISTS "Admins can read all wallets" ON public.wallets;
CREATE POLICY "Admins can read all wallets" ON public.wallets
    FOR SELECT USING (public.is_admin());

-- Only admins may update wallets directly (freeze, balance via RPC)
-- Users CANNOT update their own wallet balance directly — only via RPCs.
DROP POLICY IF EXISTS "Admins can update wallets" ON public.wallets;
CREATE POLICY "Admins can update wallets" ON public.wallets
    FOR UPDATE USING (public.is_admin());

-- No INSERT policy needed: wallets are created only by the trigger below.
-- No DELETE policy: wallets should never be deleted (cascade from users.delete).


-- ─────────────────────────────────────────────────────────────────────────────
-- TRIGGER: auto-create wallet for every new user
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

-- Backfill: create wallets for existing users who don't have one yet
INSERT INTO public.wallets (user_id)
SELECT u.id
FROM public.users u
LEFT JOIN public.wallets w ON w.user_id = u.id
WHERE w.id IS NULL
ON CONFLICT (user_id) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: deposits
--   User submits a deposit request with payment proof.
--   Admin approves → credit_wallet RPC credits available_balance.
--   status: pending → approved | rejected
--
-- Flutter inserts: user_id, amount, payment_method, transaction_ref, proof_url, status
-- Admin updates:   status = 'approved' | 'rejected'
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.deposits (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount          DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    payment_method  TEXT,                 -- 'UPI', 'Bank Transfer', 'Other'
    transaction_ref TEXT,                 -- user-provided payment reference
    proof_url       TEXT,                 -- R2 URL of payment screenshot/receipt
    status          TEXT        NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at    TIMESTAMPTZ           -- set when admin approves/rejects
);

CREATE INDEX IF NOT EXISTS idx_deposits_user_id  ON public.deposits(user_id);
CREATE INDEX IF NOT EXISTS idx_deposits_status   ON public.deposits(status);
CREATE INDEX IF NOT EXISTS idx_deposits_created  ON public.deposits(created_at DESC);

ALTER TABLE public.deposits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own deposits"    ON public.deposits;
DROP POLICY IF EXISTS "Admins can read all deposits"   ON public.deposits;
DROP POLICY IF EXISTS "Users can create deposits"      ON public.deposits;
DROP POLICY IF EXISTS "Admins can update deposits"     ON public.deposits;

-- Users read only their own deposits
CREATE POLICY "Users can read own deposits" ON public.deposits
    FOR SELECT USING (auth.uid() = user_id);

-- Admins read all pending/history deposits
CREATE POLICY "Admins can read all deposits" ON public.deposits
    FOR SELECT USING (public.is_admin());

-- Users may INSERT only for themselves; amount > 0 enforced by CHECK
CREATE POLICY "Users can create deposits" ON public.deposits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Only admins may update status (approve/reject)
CREATE POLICY "Admins can update deposits" ON public.deposits
    FOR UPDATE USING (public.is_admin());


-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE: withdrawals
--   User requests to withdraw funds. Admin approves → debit_wallet RPC.
--   status: pending → processing → completed | rejected
--
-- Flutter inserts: user_id, amount, method, payout_details (JSONB), status
-- Admin updates:   status = 'completed' | 'rejected'
--
-- NOTE: Flutter admin_provider writes 'completed' (not 'approved') — confirmed
--       correct after Batch 1 fix.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.withdrawals (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount          DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    method          TEXT,                 -- 'UPI', 'Bank Transfer'
    payout_details  JSONB,                -- {upi_id} or {account_number, ifsc_code, ...}
    status          TEXT        NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
    transaction_ref TEXT,                 -- admin-filled reference after processing
    admin_notes     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at    TIMESTAMPTZ           -- set when admin completes/rejects
);

CREATE INDEX IF NOT EXISTS idx_withdrawals_user_id ON public.withdrawals(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawals_status  ON public.withdrawals(status);
CREATE INDEX IF NOT EXISTS idx_withdrawals_created ON public.withdrawals(created_at DESC);

ALTER TABLE public.withdrawals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own withdrawals"   ON public.withdrawals;
DROP POLICY IF EXISTS "Admins can read all withdrawals"  ON public.withdrawals;
DROP POLICY IF EXISTS "Users can create withdrawals"     ON public.withdrawals;
DROP POLICY IF EXISTS "Admins can update withdrawals"    ON public.withdrawals;

-- Users read only their own withdrawal history
CREATE POLICY "Users can read own withdrawals" ON public.withdrawals
    FOR SELECT USING (auth.uid() = user_id);

-- Admins read all pending/history withdrawals
CREATE POLICY "Admins can read all withdrawals" ON public.withdrawals
    FOR SELECT USING (public.is_admin());

-- Users may INSERT only for themselves; amount > 0 enforced by CHECK
CREATE POLICY "Users can create withdrawals" ON public.withdrawals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Only admins may update status (complete/reject)
CREATE POLICY "Admins can update withdrawals" ON public.withdrawals
    FOR UPDATE USING (public.is_admin());


-- ─────────────────────────────────────────────────────────────────────────────
-- Reload PostgREST schema cache so new tables are immediately accessible
-- ─────────────────────────────────────────────────────────────────────────────

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
