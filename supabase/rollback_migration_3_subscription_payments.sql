-- ============================================================================
-- ROLLBACK SCRIPT: Migration 3 - Subscription Payments Table Integration
-- ============================================================================
-- PURPOSE: Safely rollback changes made by integrate_subscription_payments.sql
-- 
-- ORIGINAL MIGRATION: integrate_subscription_payments.sql
-- CHANGES TO REVERSE:
--   - Drop 'subscription_payments' table
--   - Remove all associated RLS policies
--   - Remove all indexes
--   - Clean up comments and metadata
--
-- SAFETY LEVEL: HIGH RISK - DATA LOSS
--   ⚠️  DESTROYS ALL DATA: All subscription payment records will be permanently lost
--   ⚠️  BREAKS FUNCTIONALITY: Subscription payment workflow will be disabled
--   ✅  NO CASCADE IMPACT: No foreign key dependencies to other tables
--
-- PREREQUISITES BEFORE EXECUTING:
--   1. ⚠️  BACKUP DATA: Export all subscription_payments records if needed
--   2. ✅ Verify no critical pending payments exist
--   3. ✅ Confirm subscription payment functionality can be disabled
--   4. ✅ Update applications to handle missing table gracefully
--   5. ✅ Test rollback on staging environment first
--
-- POST-ROLLBACK IMPACT:
--   ❌ subscription_payments table will NOT EXIST
--   ❌ Users CANNOT submit subscription payments
--   ❌ Admins CANNOT review/approve subscription payments
--   ✅ All other subscription functionality preserved (plans, user_subscriptions)
--   ✅ Other wallet and admin functionality unaffected
-- ============================================================================

-- Enable transaction for atomic rollback
BEGIN;

-- ============================================================================
-- STEP 1: VALIDATION CHECKS BEFORE ROLLBACK
-- ============================================================================

-- Verify the migration was actually applied (table exists)
DO $validation$
DECLARE
    table_exists BOOLEAN;
    record_count INTEGER;
    pending_count INTEGER;
BEGIN
    -- Check if subscription_payments table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'subscription_payments'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE EXCEPTION 'ROLLBACK ABORTED: subscription_payments table does not exist. Migration 3 may not have been applied or already rolled back.';
    END IF;
    
    -- Count total records
    SELECT COUNT(*) FROM public.subscription_payments INTO record_count;
    
    -- Count pending payments (critical to review)
    SELECT COUNT(*) FROM public.subscription_payments 
    WHERE status = 'pending' INTO pending_count;
    
    RAISE NOTICE 'VALIDATION INFO: Found % total payment records, % pending payments', record_count, pending_count;
    
    IF pending_count > 0 THEN
        RAISE WARNING 'CRITICAL WARNING: % pending subscription payments exist! These will be PERMANENTLY LOST if rollback continues.', pending_count;
    END IF;
    
    RAISE NOTICE 'VALIDATION PASSED: subscription_payments table exists, proceeding with rollback';
END $validation$;

-- ============================================================================
-- STEP 2: DATA BACKUP (CRITICAL - preventing data loss)
-- ============================================================================

-- Create backup table with all subscription payment data
-- This provides recovery option if rollback needs to be undone
CREATE TABLE IF NOT EXISTS subscription_payments_rollback_backup AS 
SELECT 
    id,
    user_id,
    plan_id,
    plan_name,
    amount,
    duration_days,
    payment_method,
    transaction_ref,
    proof_url,
    status,
    admin_notes,
    created_at,
    processed_at,
    NOW() as backup_created_at
FROM public.subscription_payments;

-- Log backup results
DO $backup_log$
DECLARE
    backup_count INTEGER;
    pending_in_backup INTEGER;
BEGIN
    SELECT COUNT(*) FROM subscription_payments_rollback_backup INTO backup_count;
    
    SELECT COUNT(*) FROM subscription_payments_rollback_backup 
    WHERE status = 'pending' INTO pending_in_backup;
    
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'DATA BACKUP CREATED: subscription_payments_rollback_backup';
    RAISE NOTICE '  - Backed up % total records', backup_count;
    RAISE NOTICE '  - Backed up % pending payments', pending_in_backup;
    RAISE NOTICE '  - Backup created at %', NOW();
    RAISE NOTICE '============================================================================';
END $backup_log$;

-- ============================================================================
-- STEP 3: DROP RLS POLICIES (must be done before dropping table)
-- ============================================================================

-- Drop all RLS policies for subscription_payments table
DROP POLICY IF EXISTS "Users can create own subscription payments" 
    ON public.subscription_payments;

DROP POLICY IF EXISTS "Users can read own subscription payments" 
    ON public.subscription_payments;

DROP POLICY IF EXISTS "Admins can read all subscription payments" 
    ON public.subscription_payments;

DROP POLICY IF EXISTS "Admins can update subscription payments" 
    ON public.subscription_payments;

RAISE NOTICE 'ROLLBACK STEP 3: Dropped all RLS policies for subscription_payments';

-- ============================================================================
-- STEP 4: DROP INDEXES
-- ============================================================================

-- Drop performance indexes that were created with the table
DROP INDEX IF EXISTS idx_subscription_payments_user_id;
DROP INDEX IF EXISTS idx_subscription_payments_status;  
DROP INDEX IF EXISTS idx_subscription_payments_created_at;

RAISE NOTICE 'ROLLBACK STEP 4: Dropped all indexes for subscription_payments';

-- ============================================================================
-- STEP 5: DROP SUBSCRIPTION_PAYMENTS TABLE
-- ============================================================================

-- Drop the main subscription_payments table
DROP TABLE IF EXISTS public.subscription_payments;

RAISE NOTICE 'ROLLBACK STEP 5: Dropped subscription_payments table';

-- ============================================================================
-- STEP 6: VALIDATION AFTER ROLLBACK
-- ============================================================================

-- Verify the rollback completed successfully
DO $validation_final$
DECLARE
    table_exists BOOLEAN;
    backup_table_exists BOOLEAN;
    backup_record_count INTEGER;
    policy_count INTEGER;
    index_count INTEGER;
BEGIN
    -- Check main table no longer exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'subscription_payments'
    ) INTO table_exists;
    
    -- Check backup table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'subscription_payments_rollback_backup'
    ) INTO backup_table_exists;
    
    -- Count backup records
    IF backup_table_exists THEN
        SELECT COUNT(*) FROM subscription_payments_rollback_backup INTO backup_record_count;
    ELSE
        backup_record_count := 0;
    END IF;
    
    -- Check policies were removed  
    SELECT COUNT(*) FROM pg_policies 
    WHERE tablename = 'subscription_payments' INTO policy_count;
    
    -- Check indexes were removed
    SELECT COUNT(*) FROM pg_indexes 
    WHERE tablename = 'subscription_payments' INTO index_count;
    
    IF table_exists THEN
        RAISE EXCEPTION 'ROLLBACK FAILED: subscription_payments table still exists';
    END IF;
    
    IF NOT backup_table_exists THEN
        RAISE WARNING 'ROLLBACK WARNING: Backup table not created - data recovery may not be possible';
    END IF;
    
    IF policy_count > 0 THEN
        RAISE WARNING 'ROLLBACK WARNING: % RLS policies still exist for subscription_payments', policy_count;
    END IF;
    
    IF index_count > 0 THEN
        RAISE WARNING 'ROLLBACK WARNING: % indexes still exist for subscription_payments', index_count;
    END IF;
    
    RAISE NOTICE 'ROLLBACK VALIDATION PASSED: subscription_payments table removed, % records backed up', backup_record_count;
END $validation_final$;

-- ============================================================================
-- STEP 7: SUMMARY AND NEXT STEPS
-- ============================================================================

RAISE NOTICE '============================================================================';
RAISE NOTICE 'ROLLBACK COMPLETED: Migration 3 (Subscription Payments Table) successfully rolled back';
RAISE NOTICE '============================================================================';
RAISE NOTICE 'CHANGES REVERTED:';
RAISE NOTICE '  ✅ Dropped subscription_payments table';
RAISE NOTICE '  ✅ Removed all RLS policies';
RAISE NOTICE '  ✅ Removed all performance indexes';
RAISE NOTICE '  ✅ Created backup table: subscription_payments_rollback_backup';
RAISE NOTICE '';
RAISE NOTICE 'IMMEDIATE IMPACT:';
RAISE NOTICE '  ❌ Subscription payment functionality DISABLED';
RAISE NOTICE '  ❌ Users CANNOT submit subscription payments';
RAISE NOTICE '  ❌ Admins CANNOT review/approve payments';
RAISE NOTICE '  ✅ All other subscription functionality preserved';
RAISE NOTICE '  ✅ User subscriptions and billing unaffected';
RAISE NOTICE '';
RAISE NOTICE 'REQUIRED FOLLOW-UP ACTIONS:';
RAISE NOTICE '  1. Update Flutter app to hide subscription payment UI';
RAISE NOTICE '  2. Update admin dashboard to remove payment review features';
RAISE NOTICE '  3. Implement alternative payment workflow if needed';
RAISE NOTICE '  4. Consider using separate migration file approach';
RAISE NOTICE '  5. Update API documentation to reflect disabled functionality';
RAISE NOTICE '';
RAISE NOTICE 'DATA RECOVERY OPTIONS:';
RAISE NOTICE '  - Backup table: subscription_payments_rollback_backup';
RAISE NOTICE '  - To restore data: re-apply Migration 3, then restore from backup';

-- Commit the rollback transaction
COMMIT;

-- ============================================================================
-- ROLLBACK VERIFICATION QUERIES
-- ============================================================================
-- Run these queries after rollback to verify success:

-- 1. Verify subscription_payments table no longer exists:
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' AND table_name = 'subscription_payments';
-- Expected: No rows returned

-- 2. Verify backup table exists and contains data:
-- SELECT COUNT(*) as backup_record_count, 
--        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count
-- FROM subscription_payments_rollback_backup;
-- Expected: Shows record counts from original table

-- 3. Verify RLS policies removed:
-- SELECT policyname FROM pg_policies WHERE tablename = 'subscription_payments';
-- Expected: No rows returned

-- 4. Verify indexes removed:
-- SELECT indexname FROM pg_indexes WHERE tablename = 'subscription_payments';
-- Expected: No rows returned

-- 5. Test that table operations fail (expected after rollback):
-- INSERT INTO public.subscription_payments (user_id, plan_id, amount) 
-- VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000001', 100.00);
-- Expected: ERROR: relation "subscription_payments" does not exist

-- ============================================================================
-- RECOVERY PROCEDURE (if rollback needs to be undone)
-- ============================================================================
-- If you need to re-apply Migration 3 after this rollback:
--
-- 1. Re-run the original migration:
--    \i supabase/migrations/integrate_subscription_payments.sql
--
-- 2. Restore data from backup (if needed):
--    INSERT INTO public.subscription_payments 
--    (id, user_id, plan_id, plan_name, amount, duration_days, payment_method, 
--     transaction_ref, proof_url, status, admin_notes, created_at, processed_at)
--    SELECT id, user_id, plan_id, plan_name, amount, duration_days, payment_method,
--           transaction_ref, proof_url, status, admin_notes, created_at, processed_at
--    FROM subscription_payments_rollback_backup;
--
-- 3. Clean up backup table:
--    DROP TABLE subscription_payments_rollback_backup;
--
-- 4. Verify functionality:
--    SELECT COUNT(*) FROM public.subscription_payments;

-- ============================================================================
-- DATA EXPORT SCRIPT (run BEFORE rollback if external backup needed)
-- ============================================================================
-- If you need to export data to external file before rollback:
--
-- \copy (SELECT * FROM public.subscription_payments) TO '/tmp/subscription_payments_export.csv' WITH CSV HEADER;
--
-- To restore from CSV after re-applying migration:
-- \copy public.subscription_payments FROM '/tmp/subscription_payments_export.csv' WITH CSV HEADER;

-- ============================================================================
-- APPLICATION UPDATE GUIDE
-- ============================================================================
-- Applications need these updates after rollback:
--
-- FLUTTER APP CHANGES:
--   - Remove subscription payment submission forms
--   - Hide payment method selection UI
--   - Update subscription flow to use alternative payment method
--   - Add error handling for missing table operations
--
-- ADMIN DASHBOARD CHANGES:
--   - Remove subscription payment review page
--   - Remove pending payments notifications
--   - Update admin navigation menu
--   - Hide subscription payment approval buttons
--
-- API/BACKEND CHANGES:
--   - Disable subscription payment endpoints
--   - Update error responses for missing table
--   - Remove subscription payment validation logic
--   - Update API documentation

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 
-- ROLLBACK ORDER DEPENDENCY:
--   This rollback can be executed independently - Migration 3 has no dependencies
--   on Migration 1 (subscription plans) or Migration 2 (wallet functions)
--
-- DATA LOSS RISK:
--   HIGH RISK - All subscription payment data will be permanently deleted
--   Backup table created automatically but verify backup before proceeding
--
-- BUSINESS IMPACT:
--   Subscription payment workflow will be completely disabled
--   Users will need alternative payment methods for subscriptions
--   Admin payment review functionality will be unavailable
--
-- SECURITY IMPLICATIONS:
--   No security vulnerabilities introduced by rollback
--   RLS policies cleanly removed with no orphaned permissions
--
-- PRODUCTION DEPLOYMENT:
--   Execute during maintenance window due to functionality removal
--   Coordinate with business team regarding payment workflow alternatives
--   Test thoroughly on staging environment first
--   Prepare customer communication about disabled functionality
--
-- ALTERNATIVE APPROACHES:
--   Consider keeping separate migration file instead of rollback
--   Implement feature flags to disable functionality without schema changes
--   Use table renaming instead of dropping for safer rollback
--
-- ============================================================================