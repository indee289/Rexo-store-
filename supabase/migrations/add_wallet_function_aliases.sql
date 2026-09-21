-- =============================================================================
-- Migration 2: Wallet RPC Function Aliases
-- =============================================================================
-- PURPOSE: Create alias wrapper functions to resolve function name mismatches
--
-- BUG CONDITION: 
--   isBugCondition(input) where input.operation = 'RPC_CALL' AND 
--   input.function_name IN ['credit_wallet', 'debit_wallet']
--
-- EXPECTED BEHAVIOR AFTER FIX:
--   - Successful wallet operations via alias functions
--   - Admin deposit/withdrawal approvals work correctly
--   - Original increment/decrement functions continue working unchanged
--
-- MIGRATION ORDER: SECOND (affects RPC function availability)
-- DEPENDENCIES: None (can run independently of other migrations)
--
-- PRESERVATION REQUIREMENTS:
--   - Existing increment/decrement wallet functions continue working unchanged
--   - Same admin-only security restrictions apply to new functions
--   - Same function parameters and return values
--   - Same balance validation logic (prevents negative balances)
-- =============================================================================

-- Create credit_wallet alias function (wrapper for increment_wallet_balance)
CREATE OR REPLACE FUNCTION credit_wallet(
  p_user_id UUID,
  p_amount NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delegate to the existing increment_wallet_balance function
  -- This preserves all existing logic, validation, and security checks
  RETURN increment_wallet_balance(p_user_id, p_amount);
END;
$$;

-- Create debit_wallet alias function (wrapper for decrement_wallet_balance)
CREATE OR REPLACE FUNCTION debit_wallet(
  p_user_id UUID,
  p_amount NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delegate to the existing decrement_wallet_balance function
  -- This preserves all existing logic, validation, and security checks
  RETURN decrement_wallet_balance(p_user_id, p_amount);
END;
$$;

-- Grant execute permissions to authenticated users for the new alias functions
-- The admin role check is enforced by the underlying functions, so even though
-- all authenticated users can call these functions, non-admin users will receive
-- an 'Unauthorized: admin role required' exception from the wrapped functions.
GRANT EXECUTE ON FUNCTION credit_wallet(UUID, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION debit_wallet(UUID, NUMERIC) TO authenticated;

-- Add comments for documentation
COMMENT ON FUNCTION credit_wallet(UUID, NUMERIC) IS 
'Alias wrapper for increment_wallet_balance. Used for deposit approval operations. Requires admin role.';

COMMENT ON FUNCTION debit_wallet(UUID, NUMERIC) IS 
'Alias wrapper for decrement_wallet_balance. Used for withdrawal approval operations. Requires admin role. Prevents negative balances.';

-- =============================================================================
-- ROLLBACK INSTRUCTIONS
-- =============================================================================
-- To rollback this migration, execute the following commands:
--
-- 1. Drop the alias functions:
--    DROP FUNCTION IF EXISTS credit_wallet(UUID, NUMERIC);
--    DROP FUNCTION IF EXISTS debit_wallet(UUID, NUMERIC);
--
-- 2. Verify the original functions still exist and work:
--    SELECT increment_wallet_balance('00000000-0000-0000-0000-000000000000'::UUID, 10.00);
--    SELECT decrement_wallet_balance('00000000-0000-0000-0000-000000000000'::UUID, 5.00);
--
-- IMPORTANT: The rollback will NOT affect the original increment_wallet_balance 
-- and decrement_wallet_balance functions - they will continue to work normally.
--
-- Only applications calling credit_wallet or debit_wallet will be affected and 
-- will need to be updated to use the original function names.
-- =============================================================================

-- Migration validation queries (for testing purposes)
-- These can be used to verify the migration was applied correctly:

-- Check that all four functions exist:
-- SELECT proname FROM pg_proc WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance', 'credit_wallet', 'debit_wallet');

-- Verify function signatures match:
-- SELECT proname, pg_get_function_identity_arguments(oid) as args FROM pg_proc WHERE proname IN ('credit_wallet', 'debit_wallet');

-- Test alias function behavior (requires valid user_id and admin role):
-- SELECT credit_wallet('valid-user-uuid', 1.00);
-- SELECT debit_wallet('valid-user-uuid', 1.00);