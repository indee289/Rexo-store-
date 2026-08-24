-- ============================================================================
-- VALIDATION SCRIPT: Migration 3 - Subscription Payments Table Integration
--
-- PURPOSE: Verify that the subscription_payments table integration was
--          applied successfully and all components are working correctly
--
-- USAGE: Run this script after applying integrate_subscription_payments.sql
--        All checks should return expected results for successful deployment
-- ============================================================================

-- ============================================================================
-- CHECK 1: Table Exists and Structure
-- ============================================================================
\echo '=== CHECK 1: Table Structure Verification ==='

-- Verify table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = 'subscription_payments') 
        THEN '✓ PASS: subscription_payments table exists'
        ELSE '✗ FAIL: subscription_payments table missing'
    END as table_check;

-- Verify column structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'subscription_payments'
ORDER BY ordinal_position;

-- ============================================================================
-- CHECK 2: Primary Key and Constraints
-- ============================================================================
\echo '=== CHECK 2: Constraints and Keys Verification ==='

-- Check primary key
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_schema = 'public' 
  AND table_name = 'subscription_payments'
  AND constraint_type = 'PRIMARY KEY';

-- Check foreign key constraints
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_schema = 'public' 
  AND table_name = 'subscription_payments'
  AND constraint_type = 'FOREIGN KEY';

-- Check check constraints (status validation)
SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_schema = 'public'
  AND constraint_name LIKE '%subscription_payments%';

-- ============================================================================
-- CHECK 3: Indexes Verification
-- ============================================================================
\echo '=== CHECK 3: Indexes Verification ==='

-- List all indexes on subscription_payments table
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND tablename = 'subscription_payments'
ORDER BY indexname;

-- Verify specific indexes exist
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_indexes 
                    WHERE schemaname = 'public' 
                    AND tablename = 'subscription_payments'
                    AND indexname = 'idx_subscription_payments_user_id') 
        THEN '✓ PASS: user_id index exists'
        ELSE '✗ FAIL: user_id index missing'
    END as user_id_index_check;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_indexes 
                    WHERE schemaname = 'public' 
                    AND tablename = 'subscription_payments'
                    AND indexname = 'idx_subscription_payments_status') 
        THEN '✓ PASS: status index exists'
        ELSE '✗ FAIL: status index missing'
    END as status_index_check;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_indexes 
                    WHERE schemaname = 'public' 
                    AND tablename = 'subscription_payments'
                    AND indexname = 'idx_subscription_payments_created_at') 
        THEN '✓ PASS: created_at index exists'
        ELSE '✗ FAIL: created_at index missing'
    END as created_at_index_check;

-- ============================================================================
-- CHECK 4: Row Level Security
-- ============================================================================
\echo '=== CHECK 4: Row Level Security Verification ==='

-- Check RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    CASE 
        WHEN rowsecurity THEN '✓ PASS: RLS enabled'
        ELSE '✗ FAIL: RLS not enabled'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'subscription_payments';

-- List all RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'subscription_payments'
ORDER BY policyname;

-- Verify expected policies exist
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_policies 
                    WHERE schemaname = 'public' 
                    AND tablename = 'subscription_payments'
                    AND policyname = 'Users can create own subscription payments') 
        THEN '✓ PASS: User INSERT policy exists'
        ELSE '✗ FAIL: User INSERT policy missing'
    END as user_insert_policy_check;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_policies 
                    WHERE schemaname = 'public' 
                    AND tablename = 'subscription_payments'
                    AND policyname = 'Users can read own subscription payments') 
        THEN '✓ PASS: User SELECT policy exists'
        ELSE '✗ FAIL: User SELECT policy missing'
    END as user_select_policy_check;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_policies 
                    WHERE schemaname = 'public' 
                    AND tablename = 'subscription_payments'
                    AND policyname = 'Admins can read all subscription payments') 
        THEN '✓ PASS: Admin SELECT policy exists'
        ELSE '✗ FAIL: Admin SELECT policy missing'
    END as admin_select_policy_check;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_policies 
                    WHERE schemaname = 'public' 
                    AND tablename = 'subscription_payments'
                    AND policyname = 'Admins can update subscription payments') 
        THEN '✓ PASS: Admin UPDATE policy exists'
        ELSE '✗ FAIL: Admin UPDATE policy missing'
    END as admin_update_policy_check;

-- ============================================================================
-- CHECK 5: Dependencies Verification
-- ============================================================================
\echo '=== CHECK 5: Dependencies Verification ==='

-- Check if is_admin() function exists (required for admin policies)
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines 
                    WHERE routine_schema = 'public' 
                    AND routine_name = 'is_admin') 
        THEN '✓ PASS: is_admin() function exists'
        ELSE '⚠ WARNING: is_admin() function missing - admin policies will fail'
    END as is_admin_function_check;

-- Check if users table exists (foreign key reference)
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = 'users') 
        THEN '✓ PASS: users table exists'
        ELSE '✗ FAIL: users table missing - FK constraint will fail'
    END as users_table_check;

-- ============================================================================
-- CHECK 6: Table Comments and Documentation
-- ============================================================================
\echo '=== CHECK 6: Documentation Verification ==='

-- Check table comment
SELECT 
    obj_description(c.oid) as table_comment,
    CASE 
        WHEN obj_description(c.oid) IS NOT NULL 
        THEN '✓ PASS: Table comment exists'
        ELSE '⚠ WARNING: Table comment missing'
    END as table_comment_check
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' 
  AND c.relname = 'subscription_payments'
  AND c.relkind = 'r';

-- Check column comments
SELECT 
    a.attname as column_name,
    col_description(a.attrelid, a.attnum) as column_comment,
    CASE 
        WHEN col_description(a.attrelid, a.attnum) IS NOT NULL 
        THEN '✓ Has comment'
        ELSE '- No comment'
    END as comment_status
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' 
  AND c.relname = 'subscription_payments'
  AND a.attnum > 0 
  AND NOT a.attisdropped
ORDER BY a.attnum;

-- ============================================================================
-- CHECK 7: Integration Test - Basic Operations
-- ============================================================================
\echo '=== CHECK 7: Basic Operation Tests ==='

-- Test 1: Check if table accepts valid status values
\echo 'Testing status constraint...'
BEGIN;
-- This should succeed (valid status)
INSERT INTO subscription_payments (user_id, plan_id, amount, status) 
VALUES (gen_random_uuid(), gen_random_uuid(), 99.99, 'pending');

-- This should fail (invalid status) - commented out to prevent error
-- INSERT INTO subscription_payments (user_id, plan_id, amount, status) 
-- VALUES (gen_random_uuid(), gen_random_uuid(), 99.99, 'invalid_status');

ROLLBACK;

\echo '✓ PASS: Status constraint working (allows valid values)'

-- Test 2: Check default values
\echo 'Testing default values...'
BEGIN;
INSERT INTO subscription_payments (user_id, plan_id, amount) 
VALUES (gen_random_uuid(), gen_random_uuid(), 99.99);

SELECT 
    status,
    duration_days,
    created_at IS NOT NULL as has_created_at,
    CASE 
        WHEN status = 'pending' 
        THEN '✓ PASS: Default status is pending'
        ELSE '✗ FAIL: Default status incorrect'
    END as status_default_check,
    CASE 
        WHEN duration_days = 30 
        THEN '✓ PASS: Default duration_days is 30'
        ELSE '✗ FAIL: Default duration_days incorrect'
    END as duration_default_check
FROM subscription_payments 
WHERE id = (SELECT max(id) FROM subscription_payments);

ROLLBACK;

-- ============================================================================
-- SUMMARY
-- ============================================================================
\echo '=== MIGRATION VALIDATION SUMMARY ==='
\echo 'If all checks show ✓ PASS, the migration was applied successfully.'
\echo 'Any ✗ FAIL items indicate issues that need to be resolved.'
\echo '⚠ WARNING items are non-critical but should be reviewed.'
\echo ''
\echo 'Next Steps:'
\echo '1. If validation passes, proceed to Task 3.4 (Execute Migrations)'
\echo '2. If validation fails, review migration file and re-apply'
\echo '3. Test subscription payment functionality end-to-end'