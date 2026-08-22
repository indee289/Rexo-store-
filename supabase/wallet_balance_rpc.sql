-- =============================================================================
-- Wallet Balance RPC Functions
-- =============================================================================
-- These functions provide atomic wallet balance operations to prevent race
-- conditions from concurrent client-side read-then-write patterns.
--
-- USAGE: Call via Supabase client `.rpc('increment_wallet_balance', {...})`
-- instead of fetching balance, computing new value, and writing it back.
--
-- IMPORTANT: Deploy these functions to your Supabase project via the SQL Editor
-- in the Supabase Dashboard before switching the Dart code to use .rpc().
-- =============================================================================

-- Atomically increment a user's wallet balance (used for deposit approval)
CREATE OR REPLACE FUNCTION increment_wallet_balance(
  p_user_id UUID,
  p_amount NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_balance NUMERIC;
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  UPDATE wallets
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

-- Atomically decrement a user's wallet balance (used for withdrawal approval)
-- Includes a check to prevent negative balances.
CREATE OR REPLACE FUNCTION decrement_wallet_balance(
  p_user_id UUID,
  p_amount NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_balance NUMERIC;
  v_new_balance NUMERIC;
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  -- Lock the row to prevent concurrent modifications
  SELECT available_balance INTO v_current_balance
  FROM wallets
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found for user %', p_user_id;
  END IF;

  IF v_current_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance. Available: %, Requested: %', v_current_balance, p_amount;
  END IF;

  UPDATE wallets
  SET available_balance = available_balance - p_amount,
      updated_at = NOW()
  WHERE user_id = p_user_id
  RETURNING available_balance INTO v_new_balance;

  RETURN v_new_balance;
END;
$$;

-- Grant execute permissions to authenticated users (admin role check should be
-- enforced at the application level or via a custom claims check within the function)
GRANT EXECUTE ON FUNCTION increment_wallet_balance(UUID, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION decrement_wallet_balance(UUID, NUMERIC) TO authenticated;
