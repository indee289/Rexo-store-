-- Migration: Add new campaign columns for redesigned campaign creation form
-- Issue #3: Campaign Creation Form Redesign

-- Add company_name column
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS company_name TEXT;

-- Add gender column with CHECK constraint
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IN ('All', 'Male', 'Female'));

-- Add page_profile_category column
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS page_profile_category TEXT;

-- Update the platform CHECK constraint to also allow 'facebook'
-- First drop the existing constraint, then add the updated one
ALTER TABLE campaigns DROP CONSTRAINT IF EXISTS campaigns_platform_check;
ALTER TABLE campaigns ADD CONSTRAINT campaigns_platform_check
  CHECK (platform IN ('instagram', 'youtube', 'tiktok', 'twitter', 'facebook', 'multiple'));
