-- ============================================================
-- Migration 1: Subscription Plans Schema Alignment
-- Fixes bug where seed script references non-existent 'interval' column
-- ============================================================

-- MIGRATION PURPOSE:
-- The subscription_plans table has 'duration_days INTEGER' but the seed script
-- expects 'interval TEXT'. This migration adds the interval column for 
-- compatibility while preserving the existing duration_days as the primary field.

-- BUG CONDITION BEING FIXED:
-- isBugCondition(input) where input.operation = 'INSERT_SUBSCRIPTION_PLANS' 
--                     AND input.references_column = 'interval'

-- EXPECTED BEHAVIOR AFTER FIX:
-- Seed script execution succeeds without column errors, both interval and 
-- duration_days populated correctly

-- ============================================================
-- STEP 1: Add interval column for seed script compatibility
-- ============================================================

-- Add interval TEXT column to existing subscription_plans table
ALTER TABLE public.subscription_plans ADD COLUMN IF NOT EXISTS interval TEXT DEFAULT 'month';

-- ============================================================
-- STEP 2: Populate interval column for existing records
-- ============================================================

-- Set interval = 'month' for all existing records to match seed data expectations
UPDATE public.subscription_plans SET interval = 'month' 
WHERE interval IS NULL OR interval = '';

-- ============================================================
-- STEP 3: Add constraint to ensure data consistency
-- ============================================================

-- Add constraint to ensure interval values are valid
ALTER TABLE public.subscription_plans ADD CONSTRAINT subscription_plans_interval_check 
CHECK (interval IN ('month', 'year', 'week', 'day'));

-- ============================================================
-- STEP 4: Update seed script compatibility
-- ============================================================

-- Note: The seed script (seed_subscription_plans.sql) will now work because:
-- 1. The interval column exists
-- 2. Existing duration_days column is preserved
-- 3. Both columns can coexist for backward compatibility

-- The application should continue using duration_days as the primary field
-- The interval column is for seed script compatibility only
-- PRESERVATION: All existing duration_days data and subscription plan functionality preserved

-- ============================================================
-- ROLLBACK INSTRUCTIONS (execute in reverse order if needed)
-- ============================================================

/*
-- To rollback this migration:

-- Step 1: Remove constraint
ALTER TABLE public.subscription_plans 
DROP CONSTRAINT IF EXISTS subscription_plans_interval_check;

-- Step 2: Remove interval column
ALTER TABLE public.subscription_plans 
DROP COLUMN IF EXISTS interval;

-- Step 3: Restore original seed script behavior
-- (the seed script will fail again until the interval column is re-added)
*/

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- Verify the migration completed successfully:
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'subscription_plans' 
-- AND column_name IN ('duration_days', 'interval');

-- Verify existing data is preserved:
-- SELECT id, name, duration_days, interval, price 
-- FROM public.subscription_plans 
-- ORDER BY price;

-- ============================================================
-- MIGRATION METADATA
-- ============================================================

-- Migration: fix_subscription_plans_schema.sql
-- Order: FIRST (affects data structure)
-- Dependencies: None (base schema must exist)
-- Affects: subscription_plans table structure
-- Preserves: All existing duration_days data and application functionality
-- Enables: seed_subscription_plans.sql execution without errors