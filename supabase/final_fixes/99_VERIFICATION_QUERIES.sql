-- ============================================================================
-- 99_VERIFICATION_QUERIES.sql
-- Rexo — Read-Only Live Database Verification Queries
--
-- PURPOSE
--   These queries verify the live Supabase database matches what Flutter expects.
--   Run each section in the Supabase SQL Editor (Dashboard → SQL Editor).
--
--   ALL QUERIES ARE READ-ONLY (SELECT / introspection only).
--   DO NOT modify data with these queries.
--
-- CRITICAL
--   Run Section 1 (campaigns column names) FIRST.
--   The answer determines whether jobs_provider.dart or create_campaign_screen.dart
--   will fail at runtime. See the CAMPAIGNS COLUMN DISCREPANCY note in README.md.
-- ============================================================================


-- ============================================================================
-- SECTION 1 — CAMPAIGNS TABLE COLUMNS (CRITICAL — run this first)
-- ============================================================================
-- This resolves the known discrepancy between schema.sql and JOBS_VIA_CAMPAIGNS.sql.
-- Expected columns for the Flutter app to work:
--   FOR JOBS: payout_per_creator, slots, cover_image, payout_model, is_job
--   FOR CAMPAIGNS: per_creator_payout, total_slots, cover_image_url (or the same as jobs)

SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'campaigns'
ORDER BY ordinal_position;

-- What to look for:
--   payout_per_creator   → jobs_provider.dart will work for payout
--   per_creator_payout   → create_campaign_screen.dart will work for payout
--   BOTH                 → both work (DB has both columns)
--   NEITHER              → critical schema mismatch; run JOBS_VIA_CAMPAIGNS.sql first
--
--   slots                → jobs_provider.dart will work for slots
--   total_slots          → create_campaign_screen.dart will work for slots
--
--   cover_image          → jobs_provider.dart will work for cover image
--   cover_image_url      → create_campaign_screen.dart will work for cover image
--
--   payout_model         → mandatory for job filtering (Flutter filters by payout_model='job')
--   is_job               → job marker for trigger, may be set to false for non-jobs


-- ============================================================================
-- SECTION 2 — IS_ADMIN() FUNCTION
-- ============================================================================

SELECT
    proname                                    AS function_name,
    pg_get_function_identity_arguments(oid)    AS arguments,
    prosecdef                                  AS security_definer,
    proconfig                                  AS config
FROM pg_proc
WHERE proname = 'is_admin'
  AND pronamespace = 'public'::regnamespace;

-- Expected: 1 row, security_definer = true


-- ============================================================================
-- SECTION 3 — WALLET RPC FUNCTIONS
-- ============================================================================

SELECT
    proname                                    AS function_name,
    pg_get_function_identity_arguments(oid)    AS arguments,
    prosecdef                                  AS security_definer
FROM pg_proc
WHERE proname IN (
    'credit_wallet', 'debit_wallet',
    'increment_wallet_balance', 'decrement_wallet_balance'
)
AND pronamespace = 'public'::regnamespace;

-- Expected: 4 rows (all four functions, all security_definer = true)


-- ============================================================================
-- SECTION 4 — NOTIFICATIONS INSERT RLS POLICY
-- ============================================================================

SELECT
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'notifications'
ORDER BY policyname;

-- Expected: "System can create notifications" policy should have:
--   with_check = (auth.uid() = user_id) OR is_admin()
--   NOT the old: with_check = TRUE


-- ============================================================================
-- SECTION 5 — APPLICATIONS UPDATE WITH CHECK
-- ============================================================================

SELECT
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'applications'
  AND cmd        = 'UPDATE'
ORDER BY policyname;

-- Expected: "Creators can update own applications" should have:
--   with_check = (auth.uid() = creator_id AND status IN ('pending','withdrawn'))
--   NOT the old version without WITH CHECK


-- ============================================================================
-- SECTION 6 — WITHDRAWALS STATUS CONSTRAINT
-- ============================================================================

SELECT
    conname,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conname LIKE '%withdrawal%status%'
   OR (conrelid = 'public.withdrawals'::regclass AND contype = 'c');

-- Expected: CHECK constraint allows: pending | processing | completed | rejected
-- NOTE: Flutter writes 'completed' (not 'approved') after Batch 1 fix.
--       If 'approved' appears in the constraint, the fix was NOT needed.
--       If 'approved' is NOT in the constraint, the fix was mandatory and correct.


-- ============================================================================
-- SECTION 7 — ALL RLS POLICIES ON CRITICAL TABLES
-- ============================================================================

SELECT
    tablename,
    policyname,
    cmd,
    CASE WHEN qual IS NOT NULL THEN 'USING: ' || left(qual, 80) ELSE '' END     AS using_clause,
    CASE WHEN with_check IS NOT NULL THEN 'CHECK: ' || left(with_check, 80) ELSE '' END AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
      'wallets', 'deposits', 'withdrawals', 'notifications',
      'applications', 'campaigns', 'users', 'subscription_payments'
  )
ORDER BY tablename, policyname;


-- ============================================================================
-- SECTION 8 — APPLICATIONS TABLE COLUMNS (verify job submission fields)
-- ============================================================================

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'applications'
ORDER BY ordinal_position;

-- Expected columns to exist (added by JOBS_VIA_CAMPAIGNS.sql):
--   submission_type, submission_url, submission_note, rejection_reason,
--   submitted_at, reviewed_at, reviewed_by
-- Expected columns to exist (added by add_application_fields.sql):
--   applicant_name, location, category, city, state, contact_number,
--   instagram_url, followers_count


-- ============================================================================
-- SECTION 9 — SUBSCRIPTION_PAYMENTS TABLE AND POLICIES
-- ============================================================================

-- Table columns
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'subscription_payments'
ORDER BY ordinal_position;

-- Policies
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'subscription_payments'
ORDER BY policyname;


-- ============================================================================
-- SECTION 10 — USER CREATION TRIGGER
-- ============================================================================

SELECT tgname, tgenabled, tgtype
FROM pg_trigger
WHERE tgrelid = 'auth.users'::regclass
  AND NOT tgisinternal;

-- Expected: on_auth_user_created trigger present and enabled ('O' = enabled always)


-- ============================================================================
-- SECTION 11 — SUBSCRIPTION_PLANS INTERVAL COLUMN
-- ============================================================================

SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'subscription_plans'
  AND column_name IN ('duration_days', 'interval', 'price');

-- Expected: both duration_days and interval exist


-- ============================================================================
-- SECTION 12 — MESSAGES SOFT-STATE COLUMNS
-- ============================================================================

SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'messages'
  AND column_name IN ('is_unsent', 'edited_at', 'deleted_for');

-- Expected: all three columns exist (added by migrations/add_messages_soft_state.sql)


-- ============================================================================
-- SECTION 13 — JOBS SLOT ENFORCEMENT TRIGGER
-- ============================================================================

SELECT tgname, tgenabled, tgtype
FROM pg_trigger
WHERE tgrelid = 'public.applications'::regclass
  AND NOT tgisinternal;

-- Expected: enforce_job_slots trigger present and enabled


-- ============================================================================
-- SECTION 14 — PLATFORM CHECK CONSTRAINT ON CAMPAIGNS
-- ============================================================================

SELECT conname, pg_get_constraintdef(oid) AS constraint_def
FROM pg_constraint
WHERE conrelid = 'public.campaigns'::regclass
  AND contype  = 'c'
ORDER BY conname;

-- Expected: campaigns_platform_check should include 'facebook'
-- Expected: campaigns_status_check should include 'closed'
