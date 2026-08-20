-- 010_update_schema.sql
-- Force update schema
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS age INT,
ADD COLUMN IF NOT EXISTS website TEXT;

-- Update creator profiles just in case
ALTER TABLE public.creator_profiles 
ADD COLUMN IF NOT EXISTS age INT,
ADD COLUMN IF NOT EXISTS website TEXT;
