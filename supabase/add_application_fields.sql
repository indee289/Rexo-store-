-- ============================================================================
-- Expand the applications table with the creator-profile fields collected on
-- the "Apply to Campaign" form, so the brand (campaign poster) can review a
-- full applicant profile from their dashboard.
--
-- No RLS change is required: the existing policies already allow
--   * creators to INSERT their own applications,
--   * brands to SELECT applications for their own campaigns,
--   * admins to SELECT all applications.
-- These new columns are covered by those row-level policies automatically.
--
-- Idempotent: safe to run multiple times (ADD COLUMN IF NOT EXISTS).
-- ============================================================================

ALTER TABLE public.applications
  ADD COLUMN IF NOT EXISTS applicant_name  TEXT,
  ADD COLUMN IF NOT EXISTS location        TEXT,
  ADD COLUMN IF NOT EXISTS category        TEXT,
  ADD COLUMN IF NOT EXISTS city            TEXT,
  ADD COLUMN IF NOT EXISTS state           TEXT,
  ADD COLUMN IF NOT EXISTS contact_number  TEXT,
  ADD COLUMN IF NOT EXISTS instagram_url   TEXT,
  ADD COLUMN IF NOT EXISTS followers_count INTEGER;

-- ============================================================================
-- VERIFICATION:
--   SELECT column_name, data_type FROM information_schema.columns
--   WHERE table_schema = 'public' AND table_name = 'applications'
--   ORDER BY ordinal_position;
-- ============================================================================
