-- ============================================================================
-- ROLLBACK SCRIPT: Migration 2 - Wallet RPC Function Aliases
-- ============================================================================
-- PURPOSE: Safely rollback changes made by add_wallet_function_aliases.sql
-- 
-- ORIGINAL MIGRATION: add_wallet_function_aliases.sql
-- CHANGES TO REVERSE:
--   - Drop 'credit_wallet' alias function
--   - Drop 'debit_wallet' alias function
--   - Remove function permissions (GRANT EXECUTE statements)
--
-- SAFETY LEVEL: LOW RISK
--   ✅  NO DATA LOSS: Only removes function aliases, no data affected
--   ✅  PRESERVES ORIGINALS: increment_wallet_balance & decrement_wallet_balance untouched
--   ⚠️  BREAKS APPLICATIONS: Apps calling credit_wallet/debit_wallet will fail
--
-- PREREQUISITES BEFORE EXECUTING:
--   1. ✅ Identify all applications calling credit_wallet() or debit_wallet()
--   2. ✅ Update applications to use increment_wallet_balance() and decrement_wallet_balance()
--   3. ✅ Test application changes on staging environment
--   4. ✅ Coordinate rollback with application deployment
--
-- POST-ROLLBACK IMPACT:
--   ❌ credit_wallet() and debit_wallet() function calls will FAIL
--   ✅ increment_wallet_balance() and decrement_wallet_balance() continue working normally
--   ✅ All wallet data, balances, and transaction history preserved
--   ✅ Admin wallet approval functionality preserved (if using original functions)
-- ============================================================================

-- Enable transaction for atomic rollback
BEGIN;

-- ============================================================================
-- STEP 1: VALIDATION CHECKS BEFORE ROLLBACK
-- ============================================================================

-- Verify the migration was actually applied (alias functions exist)
DO $validation$
DECLARE
    credit_wallet_exists BOOLEAN;
    debit_wallet_exists BOOLEAN;
    original_functions_exist BOOLEAN;
BEGIN
    -- Check if alias functions exist
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'credit_wallet'
    ) INTO credit_wallet_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'debit_wallet'
    ) INTO debit_wallet_exists;
    
    -- Verify original functions still exist (critical safety check)
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance')
    ) INTO original_functions_exist;
    
    IF NOT original_functions_exist THEN
        RAISE EXCEPTION 'ROLLBACK ABORTED: Original wallet functions missing. Cannot safely rollback without increment_wallet_balance and decrement_wallet_balance functions.';
    END IF;
    
    IF NOT (credit_wallet_exists AND debit_wallet_exists) THEN
        RAISE WARNING 'ROLLBACK WARNING: One or both alias functions do not exist. Migration 2 may not have been applied or already rolled back.';
    ELSE
        RAISE NOTICE 'VALIDATION PASSED: Alias functions exist and original functions preserved, proceeding with rollback';
    END IF;
END $validation$;

-- ============================================================================
-- STEP 2: FUNCTION USAGE ANALYSIS
-- ============================================================================

-- Log function signatures for audit trail
DO $analysis$
BEGIN
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'FUNCTION ANALYSIS BEFORE ROLLBACK:';
    RAISE NOTICE '============================================================================';
    
    -- Show all wallet-related functions before rollback
    RAISE NOTICE 'Functions to be removed:';
    PERFORM 
        RAISE NOTICE '  - %(%)', 
        proname, 
        pg_get_function_identity_arguments(oid)
    FROM pg_proc 
    WHERE proname IN ('credit_wallet', 'debit_wallet');
    
    RAISE NOTICE '';
    RAISE NOTICE 'Functions to be preserved:';
    PERFORM 
        RAISE NOTICE '  - %(%)', 
        proname, 
        pg_get_function_identity_arguments(oid)
    FROM pg_proc 
    WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance');
    
    RAISE NOTICE '============================================================================';
END $analysis$;

-- ============================================================================
-- STEP 3: REVOKE PERMISSIONS (cleanup before dropping functions)
-- ============================================================================

-- Revoke EXECUTE permissions that were granted to the alias functions
-- This step is technically optional since dropping the function removes permissions,
-- but it's good practice for clean rollback
REVOKE ALL ON FUNCTION credit_wallet(UUID, NUMERIC) FROM authenticated;
REVOKE ALL ON FUNCTION debit_wallet(UUID, NUMERIC) FROM authenticated;

RAISE NOTICE 'ROLLBACK STEP 3: Revoked permissions for alias functions';

-- ============================================================================
-- STEP 4: DROP ALIAS FUNCTIONS
-- ============================================================================

-- Drop credit_wallet alias function
DROP FUNCTION IF EXISTS credit_wallet(UUID, NUMERIC);
RAISE NOTICE 'ROLLBACK STEP 4a: Dropped credit_wallet(UUID, NUMERIC) function';

-- Drop debit_wallet alias function  
DROP FUNCTION IF EXISTS debit_wallet(UUID, NUMERIC);
RAISE NOTICE 'ROLLBACK STEP 4b: Dropped debit_wallet(UUID, NUMERIC) function';

-- ============================================================================
-- STEP 5: VALIDATION AFTER ROLLBACK
-- ============================================================================

-- Verify the rollback completed successfully
DO $validation_final$
DECLARE
    credit_wallet_exists BOOLEAN;
    debit_wallet_exists BOOLEAN;
    original_functions_exist BOOLEAN;
    increment_function_count INTEGER;
    decrement_function_count INTEGER;
BEGIN
    -- Check alias functions no longer exist
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'credit_wallet'
    ) INTO credit_wallet_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'debit_wallet'
    ) INTO debit_wallet_exists;
    
    -- Verify original functions still exist (critical!)
    SELECT COUNT(*) FROM pg_proc 
    WHERE proname = 'increment_wallet_balance' 
    INTO increment_function_count;
    
    SELECT COUNT(*) FROM pg_proc 
    WHERE proname = 'decrement_wallet_balance' 
    INTO decrement_function_count;
    
    IF credit_wallet_exists OR debit_wallet_exists THEN
        RAISE EXCEPTION 'ROLLBACK FAILED: Alias functions still exist';
    END IF;
    
    IF increment_function_count = 0 OR decrement_function_count = 0 THEN
        RAISE EXCEPTION 'ROLLBACK CRITICAL ERROR: Original wallet functions missing! Database integrity compromised.';
    END IF;
    
    RAISE NOTICE 'ROLLBACK VALIDATION PASSED: Alias functions removed, original functions preserved';
END $validation_final$;

-- ============================================================================
-- STEP 6: FUNCTIONAL TESTING (optional - requires valid test data)
-- ============================================================================

-- Test that original functions still work (uncomment if you have test data)
-- DO $functional_test$
-- DECLARE
--     test_user_id UUID := '00000000-0000-0000-0000-000000000000'; -- Replace with valid test user ID
--     result_balance NUMERIC;
-- BEGIN
--     -- Test increment function
--     SELECT increment_wallet_balance(test_user_id, 1.00) INTO result_balance;
--     RAISE NOTICE 'FUNCTIONAL TEST: increment_wallet_balance returned %', result_balance;
--     
--     -- Test decrement function
--     SELECT decrement_wallet_balance(test_user_id, 1.00) INTO result_balance;
--     RAISE NOTICE 'FUNCTIONAL TEST: decrement_wallet_balance returned %', result_balance;
--     
--     RAISE NOTICE 'FUNCTIONAL TEST PASSED: Original wallet functions working correctly';
-- EXCEPTION
--     WHEN OTHERS THEN
--         RAISE NOTICE 'FUNCTIONAL TEST SKIPPED: % (ensure test user exists for full validation)', SQLERRM;
-- END $functional_test$;

-- ============================================================================
-- STEP 7: SUMMARY AND NEXT STEPS
-- ============================================================================

RAISE NOTICE '============================================================================';
RAISE NOTICE 'ROLLBACK COMPLETED: Migration 2 (Wallet Function Aliases) successfully rolled back';
RAISE NOTICE '============================================================================';
RAISE NOTICE 'CHANGES REVERTED:';
RAISE NOTICE '  ✅ Removed credit_wallet(UUID, NUMERIC) function';
RAISE NOTICE '  ✅ Removed debit_wallet(UUID, NUMERIC) function';
RAISE NOTICE '  ✅ Revoked function permissions';
RAISE NOTICE '  ✅ Preserved increment_wallet_balance and decrement_wallet_balance functions';
RAISE NOTICE '';
RAISE NOTICE 'IMMEDIATE IMPACT:';
RAISE NOTICE '  ❌ Applications calling credit_wallet() will FAIL';
RAISE NOTICE '  ❌ Applications calling debit_wallet() will FAIL';  
RAISE NOTICE '  ✅ Applications using increment_wallet_balance() continue working';
RAISE NOTICE '  ✅ Applications using decrement_wallet_balance() continue working';
RAISE NOTICE '  ✅ All wallet data and balances preserved';
RAISE NOTICE '';
RAISE NOTICE 'REQUIRED FOLLOW-UP ACTIONS:';
RAISE NOTICE '  1. Update Flutter admin app to use increment_wallet_balance/decrement_wallet_balance';
RAISE NOTICE '  2. Update any APIs or services calling credit_wallet/debit_wallet functions';
RAISE NOTICE '  3. Test admin wallet approval workflows';
RAISE NOTICE '  4. Update API documentation to reflect function name changes';
RAISE NOTICE '  5. Consider updating variable names in code for consistency';

-- Commit the rollback transaction
COMMIT;

-- ============================================================================
-- ROLLBACK VERIFICATION QUERIES
-- ============================================================================
-- Run these queries after rollback to verify success:

-- 1. Verify alias functions no longer exist:
-- SELECT proname, pg_get_function_identity_arguments(oid) as signature
-- FROM pg_proc 
-- WHERE proname IN ('credit_wallet', 'debit_wallet');
-- Expected: No rows returned

-- 2. Verify original functions still exist:
-- SELECT proname, pg_get_function_identity_arguments(oid) as signature
-- FROM pg_proc 
-- WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance');
-- Expected: 2 rows returned with full function signatures

-- 3. Test original functions work (replace with valid user_id):
-- SELECT increment_wallet_balance('your-test-user-uuid'::UUID, 0.01);
-- SELECT decrement_wallet_balance('your-test-user-uuid'::UUID, 0.01);
-- Expected: Both return updated wallet balance

-- 4. Verify alias functions fail (expected after rollback):
-- SELECT credit_wallet('your-test-user-uuid'::UUID, 0.01);
-- Expected: ERROR: function credit_wallet(uuid, numeric) does not exist

-- ============================================================================
-- RECOVERY PROCEDURE (if rollback needs to be undone)
-- ============================================================================
-- If you need to re-apply Migration 2 after this rollback:
--
-- 1. Re-run the original migration:
--    \i supabase/migrations/add_wallet_function_aliases.sql
--
-- 2. Verify all functions exist:
--    SELECT proname FROM pg_proc WHERE proname IN 
--    ('increment_wallet_balance', 'decrement_wallet_balance', 'credit_wallet', 'debit_wallet');
--
-- 3. Test alias functions work:
--    SELECT credit_wallet('test-uuid'::UUID, 1.00);
--    SELECT debit_wallet('test-uuid'::UUID, 1.00);

-- ============================================================================
-- APPLICATION MIGRATION GUIDE
-- ============================================================================
-- For applications affected by this rollback, update function calls:
--
-- FLUTTER/DART CODE CHANGES:
--   Before: await supabase.rpc('credit_wallet', {'p_user_id': userId, 'p_amount': amount})
--   After:  await supabase.rpc('increment_wallet_balance', {'p_user_id': userId, 'p_amount': amount})
--
--   Before: await supabase.rpc('debit_wallet', {'p_user_id': userId, 'p_amount': amount})
--   After:  await supabase.rpc('decrement_wallet_balance', {'p_user_id': userId, 'p_amount': amount})
--
-- JAVASCRIPT CODE CHANGES:
--   Before: const { data } = await supabase.rpc('credit_wallet', {p_user_id: userId, p_amount: amount})
--   After:  const { data } = await supabase.rpc('increment_wallet_balance', {p_user_id: userId, p_amount: amount})
--
-- SQL DIRECT CALLS:
--   Before: SELECT credit_wallet(user_id, 100.00);
--   After:  SELECT increment_wallet_balance(user_id, 100.00);

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 
-- ROLLBACK ORDER DEPENDENCY:
--   This rollback can be executed independently - Migration 2 has no dependencies
--   on Migration 1 (subscription plans) or Migration 3 (subscription_payments)
--
-- ZERO DATA LOSS:
--   This rollback affects only function definitions, not data
--   All wallet balances, transaction history, and user data preserved
--
-- APPLICATION COMPATIBILITY:
--   Applications using original function names are unaffected
--   Applications using alias function names will break and need code updates
--
-- SECURITY IMPLICATIONS:
--   Same security model preserved - admin role still required for wallet operations
--   No change to RLS policies or user permissions
--
-- PRODUCTION DEPLOYMENT:
--   Coordinate with application deployment to avoid service interruption
--   Test thoroughly on staging environment first
--   Consider feature flags to control wallet functionality during transition
--
-- ============================================================================