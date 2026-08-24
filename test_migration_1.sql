-- Test script for Migration 1: Subscription Plans Schema Alignment
-- This script simulates the migration on a test database

-- Step 1: Create test subscription_plans table with original schema
DROP TABLE IF EXISTS test_subscription_plans;

CREATE TABLE test_subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    price DECIMAL NOT NULL,
    features JSONB,
    duration_days INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Insert some test data with original schema (duration_days only)
INSERT INTO test_subscription_plans (id, name, price, duration_days, features)
VALUES
  ('a1b2c3d4-0001-4000-8000-000000000001', 'Free', 0, 30, '["Basic features"]'),
  ('a1b2c3d4-0002-4000-8000-000000000002', 'Pro', 299, 30, '["Pro features"]');

-- Step 3: Verify original data
SELECT 'BEFORE MIGRATION:' as status;
SELECT id, name, price, duration_days, 
       CASE WHEN EXISTS (SELECT column_name FROM information_schema.columns 
                         WHERE table_name = 'test_subscription_plans' 
                         AND column_name = 'interval') 
            THEN 'EXISTS' ELSE 'MISSING' END as interval_column
FROM test_subscription_plans;

-- Step 4: Apply the migration (add interval column)
ALTER TABLE test_subscription_plans 
ADD COLUMN IF NOT EXISTS interval TEXT DEFAULT 'month';

-- Step 5: Populate interval column for existing records
UPDATE test_subscription_plans 
SET interval = 'month' 
WHERE interval IS NULL OR interval = '';

-- Step 6: Add constraint
ALTER TABLE test_subscription_plans 
ADD CONSTRAINT test_subscription_plans_interval_check 
CHECK (interval IN ('month', 'year', 'week', 'day'));

-- Step 7: Verify migration results
SELECT 'AFTER MIGRATION:' as status;
SELECT id, name, price, duration_days, interval, 
       'BOTH_COLUMNS_EXIST' as migration_status
FROM test_subscription_plans;

-- Step 8: Test that the updated seed script would work
SELECT 'TESTING SEED SCRIPT COMPATIBILITY:' as status;

-- This INSERT should now work (simulates the updated seed script)
INSERT INTO test_subscription_plans (id, name, price, interval, duration_days, features)
VALUES
  ('a1b2c3d4-0003-4000-8000-000000000003', 'Test Plan', 199, 'month', 30, '["Test features"]')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  interval = EXCLUDED.interval,
  duration_days = EXCLUDED.duration_days,
  features = EXCLUDED.features;

-- Step 9: Final verification
SELECT 'FINAL VERIFICATION:' as status;
SELECT id, name, price, duration_days, interval, features
FROM test_subscription_plans
ORDER BY price;

-- Step 10: Test rollback (optional)
-- ALTER TABLE test_subscription_plans DROP CONSTRAINT IF EXISTS test_subscription_plans_interval_check;
-- ALTER TABLE test_subscription_plans DROP COLUMN IF EXISTS interval;

-- Cleanup
DROP TABLE test_subscription_plans;