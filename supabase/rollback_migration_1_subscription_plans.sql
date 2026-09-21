-- ============================================================================
-- ROLLBACK SCRIPT: Migration 1 - Subscription Plans Schema Alignment
-- ============================================================================
-- PURPOSE: Safely rollback changes made by fix_subscription_plans_schema.sql
-- 
-- ORIGINAL MIGRATION: fix_subscription_plans_schema.sql
-- CHANGES TO REVERSE:
--   - Remove 'interval' column added for seed script compatibility
--   - Remove constraint 'subscription_plans_interval_check'
--   - Restore original schema state
--
-- SAFETY LEVEL: MEDIUM RISK
--   ⚠️  REMOVES COLUMN DATA: The 'interval' column and its data will be lost
--   ✅  PRESERVES CRITICAL DATA: duration_days and all subscription functionality preserved
--   ✅  NO FOREIGN KEY IMPACT: No dependent tables use the interval column
--
-- PREREQUISITES BEFORE EXECUTING:
--   1. ✅ Verify no applications are actively using the 'interval' column
--   2. ✅ Confirm seed_subscription_plans.sql can be run without interval column (will fail)
--   3. ✅ Backup database or take snapshot before rollback
--   4. ✅ Test rollback on staging environment first
--
-- POST-ROLLBACK IMPACT:
--   ❌ seed_subscription_plans.sql will FAIL with "column interval does not exist"
--   ✅ All existing subscription functionality continues working
--   ✅ User subscriptions, billing, and plan management unaffected
-- ============================================================================

-- Enable transaction for atomic rollback
BEGIN;

-- ============================================================================
-- STEP 1: VALIDATION CHECKS BEFORE ROLLBACK
-- ============================================================================

-- Verify the migration was actually applied (interval column exists)
DO $validation$
DECLARE
    column_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'subscription_plans' 
        AND column_name = 'interval'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        RAISE EXCEPTION 'ROLLBACK ABORTED: interval column does not exist. Migration 1 may not have been applied or already rolled back.';
    END IF;
    
    RAISE NOTICE 'VALIDATION PASSED: interval column exists, proceeding with rollback';
END $validation$;

-- ============================================================================
-- STEP 2: DATA BACKUP (for audit trail)
-- ============================================================================

-- Log current interval values before deletion (for recovery if needed)
DO $backup$
DECLARE
    record_count INTEGER;
BEGIN
    SELECT COUNT(*) FROM public.subscription_plans WHERE interval IS NOT NULL
    INTO record_count;
    
    RAISE NOTICE 'BACKUP INFO: % subscription plan records have interval data that will be lost', record_count;
    
    -- Could optionally create a backup table here if data recovery needed later:
    -- CREATE TABLE subscription_plans_interval_backup AS 
    -- SELECT id, name, interval, created_at FROM public.subscription_plans WHERE interval IS NOT NULL;
END $backup$;

-- ============================================================================
-- STEP 3: REMOVE CONSTRAINT
-- ============================================================================

-- Remove interval column constraint (must be done before dropping column)
ALTER TABLE public.subscription_plans 
DROP CONSTRAINT IF EXISTS subscription_plans_interval_check;

RAISE NOTICE 'ROLLBACK STEP 3: Removed subscription_plans_interval_check constraint';

-- ============================================================================
-- STEP 4: REMOVE INTERVAL COLUMN
-- ============================================================================

-- Remove the interval column that was added by the migration
ALTER TABLE public.subscription_plans 
DROP COLUMN IF EXISTS interval;

RAISE NOTICE 'ROLLBACK STEP 4: Removed interval column from subscription_plans table';

-- ============================================================================
-- STEP 5: VALIDATION AFTER ROLLBACK
-- ============================================================================

-- Verify the rollback completed successfully
DO $validation_final$
DECLARE
    interval_column_exists BOOLEAN;
    constraint_exists BOOLEAN;
    row_count INTEGER;
BEGIN
    -- Check interval column no longer exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'subscription_plans' 
        AND column_name = 'interval'
    ) INTO interval_column_exists;
    
    -- Check constraint no longer exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE table_schema = 'public' 
        AND table_name = 'subscription_plans' 
        AND constraint_name = 'subscription_plans_interval_check'
    ) INTO constraint_exists;
    
    -- Check that original data is preserved
    SELECT COUNT(*) FROM public.subscription_plans INTO row_count;
    
    IF interval_column_exists THEN
        RAISE EXCEPTION 'ROLLBACK FAILED: interval column still exists';
    END IF;
    
    IF constraint_exists THEN
        RAISE EXCEPTION 'ROLLBACK FAILED: constraint still exists';
    END IF;
    
    IF row_count = 0 THEN
        RAISE WARNING 'WARNING: No subscription plans found after rollback - verify this is expected';
    END IF;
    
    RAISE NOTICE 'ROLLBACK VALIDATION PASSED: interval column and constraint removed, % subscription plans preserved', row_count;
END $validation_final$;

-- ============================================================================
-- STEP 6: SUMMARY AND NEXT STEPS
-- ============================================================================

RAISE NOTICE '============================================================================';
RAISE NOTICE 'ROLLBACK COMPLETED: Migration 1 (Subscription Plans Schema) successfully rolled back';
RAISE NOTICE '============================================================================';
RAISE NOTICE 'CHANGES REVERTED:';
RAISE NOTICE '  ✅ Removed interval TEXT column';
RAISE NOTICE '  ✅ Removed subscription_plans_interval_check constraint';
RAISE NOTICE '  ✅ Restored original subscription_plans table schema';
RAISE NOTICE '';
RAISE NOTICE 'IMMEDIATE IMPACT:';
RAISE NOTICE '  ❌ seed_subscription_plans.sql will FAIL if executed';
RAISE NOTICE '  ✅ All subscription functionality continues working normally';
RAISE NOTICE '  ✅ User subscriptions and billing unaffected';
RAISE NOTICE '';
RAISE NOTICE 'REQUIRED FOLLOW-UP ACTIONS:';
RAISE NOTICE '  1. Update deployment scripts to handle seed_subscription_plans.sql failure';
RAISE NOTICE '  2. Consider modifying seed_subscription_plans.sql to use duration_days instead of interval';
RAISE NOTICE '  3. Update documentation to reflect schema rollback';
RAISE NOTICE '  4. Test application functionality to ensure no regressions';

-- Commit the rollback transaction
COMMIT;

-- ============================================================================
-- ROLLBACK VERIFICATION QUERIES
-- ============================================================================
-- Run these queries after rollback to verify success:

-- 1. Verify interval column no longer exists:
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'subscription_plans' 
-- AND table_schema = 'public';

-- 2. Verify existing subscription plans data is intact:
-- SELECT id, name, duration_days, price, created_at 
-- FROM public.subscription_plans 
-- ORDER BY price;

-- 3. Test that seed script fails (expected behavior after rollback):
-- \i supabase/seed_subscription_plans.sql
-- Expected: ERROR: column "interval" does not exist

-- 4. Verify subscription functionality still works:
-- SELECT * FROM public.subscription_plans WHERE duration_days > 0;

-- ============================================================================
-- RECOVERY PROCEDURE (if rollback needs to be undone)
-- ============================================================================
-- If you need to re-apply Migration 1 after this rollback:
--
-- 1. Re-run the original migration:
--    \i supabase/fix_subscription_plans_schema.sql
--
-- 2. Verify seed script works again:
--    \i supabase/seed_subscription_plans.sql
--
-- 3. Check that both columns exist:
--    SELECT column_name FROM information_schema.columns 
--    WHERE table_name = 'subscription_plans' AND column_name IN ('duration_days', 'interval');

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 
-- ROLLBACK ORDER DEPENDENCY:
--   This rollback can be executed independently - Migration 1 has no dependencies
--   on Migrations 2 (wallet functions) or 3 (subscription_payments table)
--
-- DATA LOSS WARNING:
--   The 'interval' column data will be permanently lost after this rollback.
--   If this data needs to be preserved, create a backup table before rollback:
--   CREATE TABLE interval_backup AS SELECT id, interval FROM subscription_plans;
--
-- APPLICATION COMPATIBILITY:
--   Applications using duration_days column (recommended) are unaffected
--   Applications using interval column will break after this rollback
--
-- PRODUCTION DEPLOYMENT:
--   Execute during maintenance window if applications depend on interval column
--   Can be executed during normal operations if no dependencies exist
--
-- ============================================================================