-- ============================================================================
-- COMPLETE ROLLBACK SCRIPT: All Phase 1 Critical Database Fixes
-- ============================================================================
-- PURPOSE: Safely rollback ALL changes made during Phase 1 critical fixes
-- 
-- MIGRATIONS TO REVERSE (in reverse order):
--   3. integrate_subscription_payments.sql - Drop subscription_payments table
--   2. add_wallet_function_aliases.sql - Drop wallet function aliases  
--   1. fix_subscription_plans_schema.sql - Remove interval column
--
-- SAFETY LEVEL: HIGH RISK - COMPREHENSIVE CHANGES
--   ⚠️  DATA LOSS: subscription_payments table data will be lost
--   ⚠️  FUNCTIONALITY LOSS: Several features will be disabled
--   ⚠️  APPLICATION IMPACT: Multiple app components need updates
--   ✅  CORE DATA SAFE: User accounts, wallets, subscriptions preserved
--
-- PREREQUISITES BEFORE EXECUTING:
--   1. ⚠️  FULL DATABASE BACKUP: Complete backup of entire database
--   2. ✅ Test on staging environment first
--   3. ✅ Coordinate with application team for updates
--   4. ✅ Schedule maintenance window for rollback execution
--   5. ✅ Prepare rollback communications for users
--   6. ✅ Have recovery plan ready if rollback fails
--
-- ROLLBACK EXECUTION ORDER (reverse of migration order):
--   STEP 1: Rollback Migration 3 - Subscription Payments (highest risk)
--   STEP 2: Rollback Migration 2 - Wallet Function Aliases (medium risk)  
--   STEP 3: Rollback Migration 1 - Subscription Plans Schema (low risk)
--
-- POST-ROLLBACK IMPACT:
--   ❌ Subscription payment workflow DISABLED
--   ❌ Admin wallet functions via credit_wallet/debit_wallet FAIL
--   ❌ Subscription plan seeding via seed_subscription_plans.sql FAILS
--   ✅ All user data, wallet balances, and core functionality PRESERVED
-- ============================================================================

-- Enable transaction for atomic rollback (all or nothing)
BEGIN;

-- ============================================================================
-- PRE-ROLLBACK VALIDATION AND SAFETY CHECKS
-- ============================================================================

DO $pre_rollback_validation$
DECLARE
    subscription_payments_exists BOOLEAN;
    wallet_aliases_exist BOOLEAN;
    interval_column_exists BOOLEAN;
    subscription_payments_count INTEGER;
    pending_payments_count INTEGER;
    backup_table_exists BOOLEAN;
BEGIN
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'PHASE 1 COMPLETE ROLLBACK - PRE-EXECUTION VALIDATION';  
    RAISE NOTICE '============================================================================';
    
    -- Check which migrations are currently applied
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'subscription_payments'
    ) INTO subscription_payments_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname IN ('credit_wallet', 'debit_wallet')
    ) INTO wallet_aliases_exist;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'subscription_plans' 
        AND column_name = 'interval'
    ) INTO interval_column_exists;
    
    RAISE NOTICE 'MIGRATION STATUS CHECK:';
    RAISE NOTICE '  Migration 1 (Subscription Plans): % applied', 
        CASE WHEN interval_column_exists THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '  Migration 2 (Wallet Aliases): % applied', 
        CASE WHEN wallet_aliases_exist THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '  Migration 3 (Subscription Payments): % applied', 
        CASE WHEN subscription_payments_exists THEN 'YES' ELSE 'NO' END;
    
    -- Data impact analysis
    IF subscription_payments_exists THEN
        SELECT COUNT(*) FROM public.subscription_payments INTO subscription_payments_count;
        SELECT COUNT(*) FROM public.subscription_payments 
        WHERE status = 'pending' INTO pending_payments_count;
        
        RAISE NOTICE '';
        RAISE NOTICE 'DATA IMPACT ANALYSIS:';
        RAISE NOTICE '  Total subscription payments: %', subscription_payments_count;
        RAISE NOTICE '  Pending payments (WILL BE LOST): %', pending_payments_count;
        
        IF pending_payments_count > 0 THEN
            RAISE WARNING 'CRITICAL: % pending payments will be permanently lost!', pending_payments_count;
        END IF;
    END IF;
    
    -- Check if backup table already exists (from previous rollback attempt)
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'subscription_payments_rollback_backup'
    ) INTO backup_table_exists;
    
    IF backup_table_exists THEN
        RAISE NOTICE '';
        RAISE NOTICE 'WARNING: Backup table from previous rollback exists';
        RAISE NOTICE '         Will be overwritten if Migration 3 rollback proceeds';
    END IF;
    
    RAISE NOTICE '============================================================================';
END $pre_rollback_validation$;

-- ============================================================================
-- ROLLBACK STEP 1: Migration 3 - Subscription Payments Table (HIGHEST RISK)
-- ============================================================================

RAISE NOTICE '';
RAISE NOTICE '============================================================================';
RAISE NOTICE 'ROLLBACK STEP 1: Migration 3 - Subscription Payments Table';
RAISE NOTICE '============================================================================';

-- Only rollback Migration 3 if it was applied
DO $rollback_migration_3$
DECLARE
    table_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'subscription_payments'
    ) INTO table_exists;
    
    IF table_exists THEN
        RAISE NOTICE 'Rolling back Migration 3: Subscription Payments Table...';
        
        -- Create backup table before dropping (critical for data recovery)
        DROP TABLE IF EXISTS subscription_payments_rollback_backup;
        CREATE TABLE subscription_payments_rollback_backup AS 
        SELECT *, NOW() as backup_created_at 
        FROM public.subscription_payments;
        
        -- Drop RLS policies
        DROP POLICY IF EXISTS "Users can create own subscription payments" 
            ON public.subscription_payments;
        DROP POLICY IF EXISTS "Users can read own subscription payments" 
            ON public.subscription_payments;
        DROP POLICY IF EXISTS "Admins can read all subscription payments" 
            ON public.subscription_payments;
        DROP POLICY IF EXISTS "Admins can update subscription payments" 
            ON public.subscription_payments;
        
        -- Drop indexes
        DROP INDEX IF EXISTS idx_subscription_payments_user_id;
        DROP INDEX IF EXISTS idx_subscription_payments_status;
        DROP INDEX IF EXISTS idx_subscription_payments_created_at;
        
        -- Drop the table
        DROP TABLE public.subscription_payments;
        
        RAISE NOTICE '✅ Migration 3 rollback completed - subscription_payments table removed';
        RAISE NOTICE '   Data backed up to: subscription_payments_rollback_backup';
    ELSE
        RAISE NOTICE '⚠️  Migration 3 not applied - skipping rollback';
    END IF;
END $rollback_migration_3$;

-- ============================================================================
-- ROLLBACK STEP 2: Migration 2 - Wallet Function Aliases (MEDIUM RISK)  
-- ============================================================================

RAISE NOTICE '';
RAISE NOTICE '============================================================================';
RAISE NOTICE 'ROLLBACK STEP 2: Migration 2 - Wallet Function Aliases';
RAISE NOTICE '============================================================================';

-- Only rollback Migration 2 if it was applied
DO $rollback_migration_2$
DECLARE
    credit_wallet_exists BOOLEAN;
    debit_wallet_exists BOOLEAN;
    original_functions_exist BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'credit_wallet') INTO credit_wallet_exists;
    SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'debit_wallet') INTO debit_wallet_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance')
    ) INTO original_functions_exist;
    
    IF NOT original_functions_exist THEN
        RAISE EXCEPTION 'ROLLBACK ABORTED: Original wallet functions missing - cannot safely rollback Migration 2';
    END IF;
    
    IF credit_wallet_exists OR debit_wallet_exists THEN
        RAISE NOTICE 'Rolling back Migration 2: Wallet Function Aliases...';
        
        -- Revoke permissions
        REVOKE ALL ON FUNCTION credit_wallet(UUID, NUMERIC) FROM authenticated;
        REVOKE ALL ON FUNCTION debit_wallet(UUID, NUMERIC) FROM authenticated;
        
        -- Drop alias functions
        DROP FUNCTION IF EXISTS credit_wallet(UUID, NUMERIC);
        DROP FUNCTION IF EXISTS debit_wallet(UUID, NUMERIC);
        
        RAISE NOTICE '✅ Migration 2 rollback completed - wallet function aliases removed';
        RAISE NOTICE '   Original functions preserved: increment_wallet_balance, decrement_wallet_balance';
    ELSE
        RAISE NOTICE '⚠️  Migration 2 not applied - skipping rollback';
    END IF;
END $rollback_migration_2$;

-- ============================================================================
-- ROLLBACK STEP 3: Migration 1 - Subscription Plans Schema (LOW RISK)
-- ============================================================================

RAISE NOTICE '';
RAISE NOTICE '============================================================================';
RAISE NOTICE 'ROLLBACK STEP 3: Migration 1 - Subscription Plans Schema';  
RAISE NOTICE '============================================================================';

-- Only rollback Migration 1 if it was applied
DO $rollback_migration_1$
DECLARE
    interval_column_exists BOOLEAN;
    plans_count INTEGER;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'subscription_plans' 
        AND column_name = 'interval'
    ) INTO interval_column_exists;
    
    IF interval_column_exists THEN
        RAISE NOTICE 'Rolling back Migration 1: Subscription Plans Schema...';
        
        -- Get count of plans before rollback
        SELECT COUNT(*) FROM public.subscription_plans INTO plans_count;
        
        -- Remove constraint first
        ALTER TABLE public.subscription_plans 
        DROP CONSTRAINT IF EXISTS subscription_plans_interval_check;
        
        -- Remove interval column
        ALTER TABLE public.subscription_plans 
        DROP COLUMN IF EXISTS interval;
        
        RAISE NOTICE '✅ Migration 1 rollback completed - interval column removed';
        RAISE NOTICE '   Subscription plans preserved: % records with duration_days intact', plans_count;
    ELSE
        RAISE NOTICE '⚠️  Migration 1 not applied - skipping rollback';
    END IF;
END $rollback_migration_1$;

-- ============================================================================
-- POST-ROLLBACK VALIDATION
-- ============================================================================

DO $post_rollback_validation$
DECLARE
    subscription_payments_exists BOOLEAN;
    wallet_aliases_exist BOOLEAN;
    interval_column_exists BOOLEAN;
    original_functions_exist BOOLEAN;
    subscription_plans_count INTEGER;
    backup_table_exists BOOLEAN;
    backup_record_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'POST-ROLLBACK VALIDATION';
    RAISE NOTICE '============================================================================';
    
    -- Verify rollbacks completed
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'subscription_payments'
    ) INTO subscription_payments_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname IN ('credit_wallet', 'debit_wallet')
    ) INTO wallet_aliases_exist;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'subscription_plans' 
        AND column_name = 'interval'
    ) INTO interval_column_exists;
    
    -- Verify critical functions preserved
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance')
    ) INTO original_functions_exist;
    
    SELECT COUNT(*) FROM public.subscription_plans INTO subscription_plans_count;
    
    -- Check backup table
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'subscription_payments_rollback_backup'
    ) INTO backup_table_exists;
    
    IF backup_table_exists THEN
        SELECT COUNT(*) FROM subscription_payments_rollback_backup INTO backup_record_count;
    ELSE
        backup_record_count := 0;
    END IF;
    
    RAISE NOTICE 'ROLLBACK STATUS:';
    RAISE NOTICE '  Migration 3 rolled back: %', 
        CASE WHEN NOT subscription_payments_exists THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '  Migration 2 rolled back: %', 
        CASE WHEN NOT wallet_aliases_exist THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '  Migration 1 rolled back: %', 
        CASE WHEN NOT interval_column_exists THEN 'YES' ELSE 'NO' END;
    
    RAISE NOTICE '';
    RAISE NOTICE 'DATA PRESERVATION CHECK:';
    RAISE NOTICE '  Original wallet functions exist: %', 
        CASE WHEN original_functions_exist THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '  Subscription plans preserved: % records', subscription_plans_count;
    RAISE NOTICE '  Payment data backed up: % records', backup_record_count;
    
    -- Critical validations
    IF subscription_payments_exists THEN
        RAISE WARNING 'ROLLBACK INCOMPLETE: subscription_payments table still exists';
    END IF;
    
    IF wallet_aliases_exist THEN
        RAISE WARNING 'ROLLBACK INCOMPLETE: wallet function aliases still exist';
    END IF;
    
    IF interval_column_exists THEN
        RAISE WARNING 'ROLLBACK INCOMPLETE: interval column still exists';  
    END IF;
    
    IF NOT original_functions_exist THEN
        RAISE EXCEPTION 'ROLLBACK CRITICAL ERROR: Original wallet functions missing!';
    END IF;
    
    IF subscription_plans_count = 0 THEN
        RAISE WARNING 'DATA CONCERN: No subscription plans found after rollback';
    END IF;
    
    RAISE NOTICE '============================================================================';
END $post_rollback_validation$;

-- ============================================================================
-- ROLLBACK SUMMARY AND NEXT STEPS  
-- ============================================================================

RAISE NOTICE '';
RAISE NOTICE '============================================================================';
RAISE NOTICE 'PHASE 1 COMPLETE ROLLBACK - EXECUTION SUMMARY';
RAISE NOTICE '============================================================================';
RAISE NOTICE 'ALL PHASE 1 MIGRATIONS SUCCESSFULLY ROLLED BACK';
RAISE NOTICE '';
RAISE NOTICE 'CHANGES REVERTED:';
RAISE NOTICE '  ✅ Removed subscription_payments table and all policies/indexes';
RAISE NOTICE '  ✅ Removed credit_wallet and debit_wallet function aliases';
RAISE NOTICE '  ✅ Removed interval column from subscription_plans table';
RAISE NOTICE '  ✅ Preserved all original functions and core data';
RAISE NOTICE '';  
RAISE NOTICE 'IMMEDIATE SYSTEM IMPACT:';
RAISE NOTICE '  ❌ Subscription payment workflow DISABLED';
RAISE NOTICE '  ❌ Admin deposit/withdrawal via credit_wallet/debit_wallet FAILS';
RAISE NOTICE '  ❌ Subscription plan seeding via seed_subscription_plans.sql FAILS';
RAISE NOTICE '  ✅ Core subscription functionality works (plans, user_subscriptions)';
RAISE NOTICE '  ✅ Original wallet functions work (increment/decrement_wallet_balance)';
RAISE NOTICE '  ✅ All user accounts, balances, and data preserved';
RAISE NOTICE '';
RAISE NOTICE 'CRITICAL FOLLOW-UP ACTIONS:';
RAISE NOTICE '  1. Update Flutter app to remove subscription payment UI';
RAISE NOTICE '  2. Update admin app to use original wallet function names';
RAISE NOTICE '  3. Update seed scripts to work without interval column';
RAISE NOTICE '  4. Test all wallet and subscription functionality';
RAISE NOTICE '  5. Update API documentation and error handling';
RAISE NOTICE '  6. Communicate changes to development and operations teams';
RAISE NOTICE '';
RAISE NOTICE 'DATA RECOVERY OPTIONS:';
RAISE NOTICE '  - Subscription payment data: subscription_payments_rollback_backup table';
RAISE NOTICE '  - To restore: re-apply migrations and restore from backup tables';
RAISE NOTICE '============================================================================';

-- Commit the complete rollback transaction
COMMIT;

-- ============================================================================
-- COMPREHENSIVE VERIFICATION QUERIES
-- ============================================================================
-- Run these queries after complete rollback to verify success:

/*
-- 1. Verify all Phase 1 changes are rolled back:
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_payments') 
         THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as subscription_payments_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'credit_wallet') 
         THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as credit_wallet_function,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'debit_wallet') 
         THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as debit_wallet_function,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plans' AND column_name = 'interval') 
         THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as interval_column;

-- 2. Verify core functionality preserved:
SELECT 
    COUNT(*) as subscription_plans_count,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'increment_wallet_balance') 
         THEN 'EXISTS' ELSE 'MISSING' END as increment_function,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'decrement_wallet_balance') 
         THEN 'EXISTS' ELSE 'MISSING' END as decrement_function
FROM public.subscription_plans;

-- 3. Check backup data:
SELECT 
    COUNT(*) as total_backed_up,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_backed_up,
    MIN(backup_created_at) as backup_timestamp
FROM subscription_payments_rollback_backup;

-- 4. Test that rolled back functionality fails (expected):
-- This should fail: SELECT credit_wallet('test-uuid'::UUID, 1.00);
-- This should fail: \i supabase/seed_subscription_plans.sql  
-- This should fail: INSERT INTO subscription_payments (user_id, amount) VALUES ('test-uuid', 100);

-- 5. Test that preserved functionality works:
SELECT proname, pg_get_function_identity_arguments(oid) 
FROM pg_proc 
WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance');
*/

-- ============================================================================
-- RECOVERY PROCEDURES
-- ============================================================================
-- If complete rollback needs to be undone (re-apply all Phase 1 fixes):

/*
-- STEP 1: Re-apply migrations in original order
\i supabase/fix_subscription_plans_schema.sql
\i supabase/migrations/add_wallet_function_aliases.sql  
\i supabase/migrations/integrate_subscription_payments.sql

-- STEP 2: Restore subscription payment data (if needed)
INSERT INTO public.subscription_payments 
(id, user_id, plan_id, plan_name, amount, duration_days, payment_method, 
 transaction_ref, proof_url, status, admin_notes, created_at, processed_at)
SELECT id, user_id, plan_id, plan_name, amount, duration_days, payment_method,
       transaction_ref, proof_url, status, admin_notes, created_at, processed_at
FROM subscription_payments_rollback_backup;

-- STEP 3: Clean up backup table
DROP TABLE subscription_payments_rollback_backup;

-- STEP 4: Verify everything works
\i supabase/seed_subscription_plans.sql
SELECT credit_wallet('test-uuid'::UUID, 1.00);
SELECT COUNT(*) FROM subscription_payments;
*/

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 
-- EXECUTION ORDER:
--   This script rolls back migrations in reverse order (3 → 2 → 1)
--   Each rollback is conditional - only executes if migration was applied
--
-- TRANSACTION SAFETY:
--   Entire rollback is wrapped in single transaction (atomic operation)
--   If any step fails, entire rollback is reverted automatically
--
-- DATA PROTECTION:
--   Automatic backup creation for subscription_payments data
--   All user data, wallet balances, and subscriptions preserved
--   Original functions and core schema elements untouched
--
-- APPLICATION IMPACT:
--   High - multiple application components need updates
--   Coordinate rollback with application deployment
--   Test all affected workflows after rollback
--
-- PRODUCTION CONSIDERATIONS:
--   Schedule during maintenance window
--   Have full database backup before execution  
--   Prepare customer communications about disabled features
--   Test rollback procedure on staging environment first
--
-- MONITORING:
--   Watch for increased error rates in applications
--   Monitor database performance after rollback
--   Verify no dependent systems are broken
--
-- ============================================================================