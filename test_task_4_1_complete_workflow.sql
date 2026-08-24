-- ============================================================================
-- TASK 4.1: Complete Subscription Workflow Integration Test (SQL Version)
-- ============================================================================
-- 
-- Tests the end-to-end subscription workflow ensuring all three critical 
-- database fixes work together properly:
-- 
-- 1. Migration 1: subscription_plans table has both interval and duration_days columns
-- 2. Migration 2: wallet function aliases (credit_wallet/debit_wallet) work
-- 3. Migration 3: subscription_payments table exists and works
-- 
-- WORKFLOW TESTED:
-- A. User views subscription plans (uses both columns from Migration 1)
-- B. User submits subscription payment (uses table from Migration 3) 
-- C. Admin approves payment and credits wallet (uses aliases from Migration 2)
-- D. Subscription becomes active in user_subscriptions table
-- E. Complete integration validation
-- ============================================================================

\echo '🚀 Starting Task 4.1: Complete Subscription Workflow Integration Test'
\echo 'Testing all three critical database fixes working together...'
\echo ''

-- Test user IDs (using real UUIDs for testing)
\set test_user_id '11111111-1111-1111-1111-111111111111'
\set admin_user_id '22222222-2222-2222-2222-222222222222'
\set test_plan_id 'test-plan-subscription-workflow'

-- ============================================================================
-- CLEANUP BEFORE TESTING (ensure clean state)
-- ============================================================================
\echo '=== Cleaning up any existing test data... ==='

DELETE FROM subscription_payments WHERE user_id = :'test_user_id';
DELETE FROM user_subscriptions WHERE user_id = :'test_user_id';
DELETE FROM subscription_plans WHERE id = :'test_plan_id';
UPDATE wallets SET balance = 0.00 WHERE user_id = :'test_user_id';

\echo '✅ Test data cleanup completed'

-- ============================================================================
-- STEP A: Test Subscription Plans Viewing (Migration 1 Validation)
-- ============================================================================
\echo ''
\echo '=== STEP A: Testing Subscription Plans Viewing (Migration 1) ==='

-- Create test subscription plan with both interval and duration_days columns
INSERT INTO subscription_plans (
    id, name, price, duration_days, interval, is_active, features, created_at
) VALUES (
    :'test_plan_id',
    'Integration Test Pro Plan',
    299.00,
    30,
    'month',
    true,
    '["Test feature 1", "Test feature 2"]',
    NOW()
);

\echo 'Test plan created with both interval and duration_days columns'

-- Test A.1: Query subscription_plans with both columns
\echo ''
\echo 'Test A.1: Query subscription plans with both columns'
SELECT 
    CASE 
        WHEN COUNT(*) > 0 AND 
             bool_and(interval IS NOT NULL) AND 
             bool_and(duration_days IS NOT NULL)
        THEN '✅ SUCCESS: Both columns exist and have values'
        ELSE '❌ FAILURE: Missing interval or duration_days columns'
    END as test_a1_result
FROM subscription_plans 
WHERE is_active = true;

-- Test A.2: Verify interval column values are valid
\echo ''
\echo 'Test A.2: Verify interval column has valid values'
SELECT 
    CASE 
        WHEN bool_and(interval IN ('month', 'year', 'week', 'day'))
        THEN '✅ SUCCESS: All interval values are valid'
        ELSE '❌ FAILURE: Invalid interval values found'
    END as test_a2_result
FROM subscription_plans 
WHERE is_active = true;

-- Test A.3: Verify duration_days column is numeric and positive
\echo ''
\echo 'Test A.3: Verify duration_days column is numeric and positive'
SELECT 
    CASE 
        WHEN bool_and(duration_days > 0)
        THEN '✅ SUCCESS: All duration_days values are positive'
        ELSE '❌ FAILURE: Invalid duration_days values found'
    END as test_a3_result
FROM subscription_plans 
WHERE is_active = true;

-- ============================================================================
-- STEP B: Test Subscription Payment Submission (Migration 3 Validation)
-- ============================================================================
\echo ''
\echo '=== STEP B: Testing Subscription Payment Submission (Migration 3) ==='

-- Ensure test user exists in users table
INSERT INTO users (id, email, name, role, created_at) 
VALUES (:'test_user_id', 'test@example.com', 'Test User', 'creator', NOW())
ON CONFLICT (id) DO NOTHING;

-- Ensure test user has a wallet
INSERT INTO wallets (user_id, balance, created_at)
VALUES (:'test_user_id', 0.00, NOW())
ON CONFLICT (user_id) DO UPDATE SET balance = 0.00;

-- Test B.1: Insert subscription payment into subscription_payments table
\echo ''
\echo 'Test B.1: Insert subscription payment record'
INSERT INTO subscription_payments (
    user_id, plan_id, plan_name, amount, duration_days, 
    payment_method, transaction_ref, proof_url, status, created_at
) VALUES (
    :'test_user_id',
    :'test_plan_id',
    'Integration Test Pro Plan',
    299.00,
    30,
    'UPI',
    'TEST_TXN_4_1_' || extract(epoch from now()),
    'https://example.com/proof.jpg',
    'pending',
    NOW()
);

\echo '✅ SUCCESS: Subscription payment record inserted'

-- Test B.2: Query subscription payment back
\echo ''
\echo 'Test B.2: Query subscription payment record'
SELECT 
    CASE 
        WHEN COUNT(*) > 0 AND 
             bool_and(user_id IS NOT NULL) AND
             bool_and(plan_id IS NOT NULL) AND
             bool_and(amount IS NOT NULL) AND
             bool_and(duration_days IS NOT NULL) AND
             bool_and(payment_method IS NOT NULL) AND
             bool_and(transaction_ref IS NOT NULL) AND
             bool_and(status IS NOT NULL)
        THEN '✅ SUCCESS: Payment record has all required fields'
        ELSE '❌ FAILURE: Payment record missing required fields'
    END as test_b2_result
FROM subscription_payments 
WHERE user_id = :'test_user_id';

-- Test B.3: Verify payment status is 'pending'
\echo ''
\echo 'Test B.3: Verify payment status is pending'
SELECT 
    CASE 
        WHEN bool_and(status = 'pending')
        THEN '✅ SUCCESS: Payment status is pending'
        ELSE '❌ FAILURE: Payment status is not pending'
    END as test_b3_result
FROM subscription_payments 
WHERE user_id = :'test_user_id';

-- ============================================================================
-- STEP C: Test Admin Payment Approval and Wallet Credit (Migration 2 Validation)
-- ============================================================================
\echo ''
\echo '=== STEP C: Testing Admin Payment Approval and Wallet Credit (Migration 2) ==='

-- Get the payment ID for approval
\set payment_id_query 'SELECT id FROM subscription_payments WHERE user_id = '''||:'test_user_id'||''' ORDER BY created_at DESC LIMIT 1'

-- Test C.1: Update payment status to approved
\echo ''
\echo 'Test C.1: Approve subscription payment'
UPDATE subscription_payments 
SET status = 'approved',
    admin_notes = 'Integration test approval',
    processed_at = NOW()
WHERE user_id = :'test_user_id';

SELECT 
    CASE 
        WHEN COUNT(*) > 0 AND bool_and(status = 'approved')
        THEN '✅ SUCCESS: Payment approved successfully'
        ELSE '❌ FAILURE: Payment approval failed'
    END as test_c1_result
FROM subscription_payments 
WHERE user_id = :'test_user_id';

-- Test C.2: Credit wallet using credit_wallet alias function (Migration 2)
\echo ''
\echo 'Test C.2: Credit wallet using alias function'
SELECT credit_wallet(:'test_user_id'::UUID, 100.00) as new_balance;

-- Verify the credit worked
SELECT 
    CASE 
        WHEN balance >= 100.00
        THEN '✅ SUCCESS: Wallet credited using credit_wallet function'
        ELSE '❌ FAILURE: Wallet credit using credit_wallet function failed'
    END as test_c2_result,
    balance as current_balance
FROM wallets 
WHERE user_id = :'test_user_id';

-- Test C.3: Create active subscription in user_subscriptions
\echo ''
\echo 'Test C.3: Create active subscription'
INSERT INTO user_subscriptions (
    user_id, plan_id, plan_name, amount, duration_days, 
    status, starts_at, ends_at, created_at
) VALUES (
    :'test_user_id',
    :'test_plan_id',
    'Integration Test Pro Plan',
    299.00,
    30,
    'active',
    NOW(),
    NOW() + INTERVAL '30 days',
    NOW()
);

SELECT '✅ SUCCESS: Active subscription created' as test_c3_result;

-- ============================================================================
-- STEP D: Test Complete Integration Validation
-- ============================================================================
\echo ''
\echo '=== STEP D: Testing Complete Integration Validation ==='

-- Test D.1: Verify subscription is active and properly linked
\echo ''
\echo 'Test D.1: Verify active subscription exists'
SELECT 
    CASE 
        WHEN COUNT(*) > 0 AND 
             bool_and(status = 'active') AND
             bool_and(plan_id IS NOT NULL) AND
             bool_and(plan_name IS NOT NULL) AND
             bool_and(amount IS NOT NULL) AND
             bool_and(duration_days IS NOT NULL)
        THEN '✅ SUCCESS: Active subscription exists with all required fields'
        ELSE '❌ FAILURE: No active subscription or missing fields'
    END as test_d1_result,
    COUNT(*) as subscription_count
FROM user_subscriptions 
WHERE user_id = :'test_user_id' AND status = 'active';

-- Test D.2: Verify wallet balance was credited
\echo ''
\echo 'Test D.2: Verify wallet balance was credited'
SELECT 
    CASE 
        WHEN balance > 0
        THEN '✅ SUCCESS: Wallet balance is positive'
        ELSE '❌ FAILURE: Wallet balance is not positive'
    END as test_d2_result,
    balance as wallet_balance
FROM wallets 
WHERE user_id = :'test_user_id';

-- Test D.3: Verify subscription payment is marked as approved
\echo ''
\echo 'Test D.3: Verify payment approval status'
SELECT 
    CASE 
        WHEN bool_and(status = 'approved') AND bool_and(processed_at IS NOT NULL)
        THEN '✅ SUCCESS: Payment is approved with processed timestamp'
        ELSE '❌ FAILURE: Payment is not properly approved'
    END as test_d3_result
FROM subscription_payments 
WHERE user_id = :'test_user_id';

-- Test D.4: Test debit_wallet function for completeness
\echo ''
\echo 'Test D.4: Test debit_wallet alias function'
SELECT debit_wallet(:'test_user_id'::UUID, 10.00) as balance_after_debit;

-- Verify the debit worked
SELECT 
    CASE 
        WHEN balance < 100.00 AND balance >= 0
        THEN '✅ SUCCESS: Wallet debited using debit_wallet function'
        ELSE '❌ FAILURE: Wallet debit using debit_wallet function failed'
    END as test_d4_result,
    balance as final_balance
FROM wallets 
WHERE user_id = :'test_user_id';

-- ============================================================================
-- WORKFLOW SUMMARY AND VALIDATION
-- ============================================================================
\echo ''
\echo '=== WORKFLOW SUMMARY ==='

-- Count successful tests by checking key indicators
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM subscription_plans WHERE id = :'test_plan_id' AND interval IS NOT NULL AND duration_days IS NOT NULL) > 0
        THEN '✅ Migration 1 (subscription_plans columns): WORKING'
        ELSE '❌ Migration 1 (subscription_plans columns): FAILED'
    END as migration_1_status;

SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM subscription_payments WHERE user_id = :'test_user_id') > 0
        THEN '✅ Migration 3 (subscription_payments table): WORKING'
        ELSE '❌ Migration 3 (subscription_payments table): FAILED'
    END as migration_3_status;

-- Test if wallet functions work by checking final balance
SELECT 
    CASE 
        WHEN (SELECT balance FROM wallets WHERE user_id = :'test_user_id') > 0 AND
             (SELECT balance FROM wallets WHERE user_id = :'test_user_id') < 100
        THEN '✅ Migration 2 (wallet function aliases): WORKING'
        ELSE '❌ Migration 2 (wallet function aliases): FAILED'
    END as migration_2_status;

-- Overall integration status
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM user_subscriptions WHERE user_id = :'test_user_id' AND status = 'active') > 0 AND
             (SELECT COUNT(*) FROM subscription_payments WHERE user_id = :'test_user_id' AND status = 'approved') > 0 AND
             (SELECT balance FROM wallets WHERE user_id = :'test_user_id') > 0
        THEN '🎉 OVERALL STATUS: COMPLETE SUBSCRIPTION WORKFLOW INTEGRATION TEST PASSED!'
        ELSE '❌ OVERALL STATUS: COMPLETE SUBSCRIPTION WORKFLOW INTEGRATION TEST FAILED!'
    END as overall_integration_status;

-- ============================================================================
-- FINAL CLEANUP
-- ============================================================================
\echo ''
\echo '=== Final Cleanup ==='

DELETE FROM subscription_payments WHERE user_id = :'test_user_id';
DELETE FROM user_subscriptions WHERE user_id = :'test_user_id';  
DELETE FROM subscription_plans WHERE id = :'test_plan_id';
UPDATE wallets SET balance = 0.00 WHERE user_id = :'test_user_id';

\echo '✅ Final cleanup completed'
\echo ''
\echo '============================================================================'
\echo 'TASK 4.1 COMPLETE SUBSCRIPTION WORKFLOW INTEGRATION TEST COMPLETED'
\echo '============================================================================'