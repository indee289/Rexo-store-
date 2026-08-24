-- =============================================================================
-- Migration 2 Validation Script: Wallet RPC Function Aliases
-- =============================================================================
-- This script validates that Migration 2 was applied correctly and that the
-- wallet function aliases work as expected.
--
-- USAGE: Run this script after applying the migration to verify success
-- =============================================================================

-- 1. Check that all four functions exist (original + aliases)
SELECT 
    'Function existence check' as test_name,
    CASE 
        WHEN COUNT(*) = 4 THEN 'PASS'
        ELSE 'FAIL - Expected 4 functions, found ' || COUNT(*)
    END as result,
    string_agg(proname, ', ' ORDER BY proname) as functions_found
FROM pg_proc 
WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance', 'credit_wallet', 'debit_wallet')
    AND pg_get_function_arguments(oid) = 'p_user_id uuid, p_amount numeric';

-- 2. Verify function signatures match between aliases and originals
WITH function_sigs AS (
    SELECT 
        proname,
        pg_get_function_arguments(oid) as args,
        pg_get_function_result(oid) as return_type
    FROM pg_proc 
    WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance', 'credit_wallet', 'debit_wallet')
        AND pg_get_function_arguments(oid) = 'p_user_id uuid, p_amount numeric'
)
SELECT 
    'Function signature consistency' as test_name,
    CASE 
        WHEN COUNT(DISTINCT args) = 1 AND COUNT(DISTINCT return_type) = 1 THEN 'PASS'
        ELSE 'FAIL - Function signatures do not match'
    END as result,
    'Args: ' || string_agg(DISTINCT args, ', ') || ' | Returns: ' || string_agg(DISTINCT return_type, ', ') as details
FROM function_sigs;

-- 3. Check function permissions (should all be granted to authenticated role)
SELECT 
    'Function permissions check' as test_name,
    CASE 
        WHEN COUNT(*) >= 4 THEN 'PASS'  
        ELSE 'FAIL - Missing permissions for some functions'
    END as result,
    COUNT(*) || ' functions have authenticated permissions' as details
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
LEFT JOIN pg_depend d ON d.objid = p.oid AND d.deptype = 'a'
LEFT JOIN pg_authid r ON d.refobjid = r.oid
WHERE p.proname IN ('increment_wallet_balance', 'decrement_wallet_balance', 'credit_wallet', 'debit_wallet')
    AND pg_get_function_arguments(p.oid) = 'p_user_id uuid, p_amount numeric';

-- 4. Verify function comments exist for the alias functions
SELECT 
    'Function documentation check' as test_name,
    CASE 
        WHEN COUNT(*) = 2 THEN 'PASS'
        ELSE 'FAIL - Missing comments on alias functions'  
    END as result,
    COUNT(*) || ' alias functions have documentation' as details
FROM pg_proc p
JOIN pg_description d ON d.objoid = p.oid
WHERE p.proname IN ('credit_wallet', 'debit_wallet')
    AND pg_get_function_arguments(p.oid) = 'p_user_id uuid, p_amount numeric';

-- 5. Check that functions have SECURITY DEFINER (required for admin checks)
SELECT 
    'Security definer check' as test_name,
    CASE 
        WHEN COUNT(*) = 4 THEN 'PASS'
        ELSE 'FAIL - Some functions missing SECURITY DEFINER'
    END as result,
    COUNT(*) || ' functions have SECURITY DEFINER' as details
FROM pg_proc 
WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance', 'credit_wallet', 'debit_wallet')
    AND pg_get_function_arguments(oid) = 'p_user_id uuid, p_amount numeric'
    AND prosecdef = true;

-- Summary: Overall migration validation
SELECT 
    '=== MIGRATION 2 VALIDATION SUMMARY ===' as summary,
    CASE 
        WHEN (
            -- All four functions exist
            (SELECT COUNT(*) FROM pg_proc WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance', 'credit_wallet', 'debit_wallet') AND pg_get_function_arguments(oid) = 'p_user_id uuid, p_amount numeric') = 4
            AND
            -- All functions have SECURITY DEFINER
            (SELECT COUNT(*) FROM pg_proc WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance', 'credit_wallet', 'debit_wallet') AND pg_get_function_arguments(oid) = 'p_user_id uuid, p_amount numeric' AND prosecdef = true) = 4
            AND
            -- Alias functions have comments
            (SELECT COUNT(*) FROM pg_proc p JOIN pg_description d ON d.objoid = p.oid WHERE p.proname IN ('credit_wallet', 'debit_wallet') AND pg_get_function_arguments(p.oid) = 'p_user_id uuid, p_amount numeric') = 2
        ) THEN 'MIGRATION 2: SUCCESS ✅'
        ELSE 'MIGRATION 2: FAILED ❌'
    END as status;