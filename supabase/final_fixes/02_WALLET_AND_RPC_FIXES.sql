-- ============================================================================
-- 02_WALLET_AND_RPC_FIXES.sql
-- Rexo — Wallet RPC Functions
--
-- PURPOSE
--   Defines the atomic wallet balance operations used by the Flutter admin
--   panel for deposit/withdrawal approvals. Prevents race conditions that
--   would result from a non-atomic client-side read-then-write pattern.
--
--   Flutter calls: .rpc('credit_wallet', {...}) and .rpc('debit_wallet', {...})
--   These functions wrap the underlying increment/decrement_wallet_balance
--   functions and enforce admin-only access inside the function body.
--
-- EXECUTION ORDER
--   Run AFTER 01_RLS_FIXES.sql (depends on public wallets table existing).
--
-- IDEMPOTENCY
--   All CREATE OR REPLACE. Safe to run multiple times.
--
-- DEPENDENCIES
--   wallets table must exist (from schema.sql).
--   users table must exist (for admin role check).
--
-- WITHDRAWAL STATUS NOTE
--   The withdrawals.status CHECK constraint allows:
--     pending | processing | completed | rejected
--   The Flutter admin panel uses 'completed' (not 'approved') when approving
--   a withdrawal. This was fixed in Batch 1. Confirmed correct.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- Base functions: increment and decrement
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.increment_wallet_balance(
    p_user_id UUID,
    p_amount   NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_new_balance NUMERIC;
BEGIN
    -- Enforce admin-only access inside the function body.
    IF NOT EXISTS (
        SELECT 1 FROM public.users
        WHERE id::text = auth.uid()::text AND lower(role) = 'admin'
    ) THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be positive';
    END IF;

    UPDATE public.wallets
    SET available_balance = available_balance + p_amount,
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING available_balance INTO v_new_balance;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found for user %', p_user_id;
    END IF;

    RETURN v_new_balance;
END;
$$;


CREATE OR REPLACE FUNCTION public.decrement_wallet_balance(
    p_user_id UUID,
    p_amount   NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current_balance NUMERIC;
    v_new_balance     NUMERIC;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.users
        WHERE id::text = auth.uid()::text AND lower(role) = 'admin'
    ) THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be positive';
    END IF;

    -- Row-level lock to prevent concurrent modifications.
    SELECT available_balance INTO v_current_balance
    FROM public.wallets
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found for user %', p_user_id;
    END IF;

    IF v_current_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance. Available: %, Requested: %',
            v_current_balance, p_amount;
    END IF;

    UPDATE public.wallets
    SET available_balance = available_balance - p_amount,
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING available_balance INTO v_new_balance;

    RETURN v_new_balance;
END;
$$;


GRANT EXECUTE ON FUNCTION public.increment_wallet_balance(UUID, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decrement_wallet_balance(UUID, NUMERIC) TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- Alias functions: credit_wallet / debit_wallet
-- Flutter calls these names directly via .rpc('credit_wallet', ...).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.credit_wallet(
    p_user_id UUID,
    p_amount   NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN public.increment_wallet_balance(p_user_id, p_amount);
END;
$$;


CREATE OR REPLACE FUNCTION public.debit_wallet(
    p_user_id UUID,
    p_amount   NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN public.decrement_wallet_balance(p_user_id, p_amount);
END;
$$;


GRANT EXECUTE ON FUNCTION public.credit_wallet(UUID, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.debit_wallet(UUID, NUMERIC) TO authenticated;

COMMENT ON FUNCTION public.credit_wallet(UUID, NUMERIC) IS
'Atomic wallet credit (deposit approval). Admin-only. Wraps increment_wallet_balance.';

COMMENT ON FUNCTION public.debit_wallet(UUID, NUMERIC) IS
'Atomic wallet debit (withdrawal approval). Admin-only. Prevents negative balances. Wraps decrement_wallet_balance.';
