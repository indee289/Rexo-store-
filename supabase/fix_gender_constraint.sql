-- Migration: Fix gender CHECK constraint to use lowercase values
-- This resolves PostgrestException code 23514: campaigns_gender_check violation
-- The form now sends lowercase ('all', 'male', 'female') values.

-- Drop the existing constraint (it may have been created with title-case or lowercase)
ALTER TABLE campaigns DROP CONSTRAINT IF EXISTS campaigns_gender_check;

-- Recreate with lowercase values matching what the form now sends
ALTER TABLE campaigns ADD CONSTRAINT campaigns_gender_check
  CHECK (gender IN ('all', 'male', 'female'));

-- Update any existing rows that have title-case values
UPDATE campaigns SET gender = LOWER(gender) WHERE gender IS NOT NULL;
