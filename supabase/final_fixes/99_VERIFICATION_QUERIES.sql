-- ============================================================================
-- 99_VERIFICATION_QUERIES.sql
-- Rexo — Read-Only Live Database Verification Queries
--
-- PURPOSE
--   Verify the live Supabase database state before and after applying the
--   final_fixes/ SQL package. Run in the Supabase Dashboard → SQL Editor.
--   ALL QUERIES ARE READ-ONLY (SELECT only).
--
-- USAGE
--   Run each section independently in the SQL editor.
--   Run SECTION 0 (global dangerous policies) FIRST and LAST.
--   Run SECTION 1 (campaign columns) before applying any SQL.
-- ============================================================================


-- ============================================================================
-- SECTION 0 — GLOBAL DANGEROUS POLICY SCAN (run first AND after cleanup)
-- ============================================================================
-- Identifies ALL policies with USING(true) or WITH CHECK(true).
-- After applying 08_RLS_GLOBAL_CLEANUP.sql, only intentionally public
-- tables (config SELECT, follows SELECT) should appear here.

SELECT
    tablename,
    policyname,
    cmd,
    qual        AS using_clause,
    with_check  AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND (
      lower(coalesce(qual, ''))       = 'true'
      OR lower(coalesce(with_check, '')) = 'true'
  )
ORDER BY tablename, policyname;

-- EXPECTED after cleanup:
--   config         — SELECT / true       (intentional: public config read)
--   follows        — SELECT / true        (intentional: public follower counts,
--                                          created by 05_ADDITIONAL_TABLES.sql)
-- NOTE: user_follows read is scoped to authenticated users
--   (auth.role() = 'authenticated'), NOT a bare true, so it will NOT appear here.
-- ALL other rows = remaining dangerous policies that still need fixing.


-- ============================================================================
-- SECTION 1 — CAMPAIGNS TABLE COLUMNS (CRITICAL — resolve column discrepancy)
-- ============================================================================

SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'campaigns'
ORDER BY ordinal_position;

-- EXPECTED live columns (from JOBS_VIA_CAMPAIGNS.sql verification):
--   payout_per_creator   — numeric (NOT per_creator_payout)
--   slots                — integer (NOT total_slots)
--   cover_image          — text    (NOT cover_image_url)
--   payout_model         — text    (used to tag job rows)
-- These mismatches have been fixed in the Flutter Dart code.


-- ============================================================================
-- SECTION 2 — WALLET TABLES EXIST?
-- ============================================================================
-- Confirms wallets, deposits, withdrawals are present after running 07_WALLET_TABLES.sql.

SELECT
    table_name,
    CASE WHEN table_name IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('wallets', 'deposits', 'withdrawals')
ORDER BY table_name;

-- EXPECTED: 3 rows (wallets, deposits, withdrawals all present)
-- If any are missing: run 07_WALLET_TABLES.sql


-- ============================================================================
-- SECTION 3 — WALLETS TABLE COLUMNS
-- ============================================================================

SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'wallets'
ORDER BY ordinal_position;

-- Expected columns: id, user_id, available_balance, escrow_balance,
--   total_earnings, total_withdrawn, is_frozen, currency, created_at, updated_at


-- ============================================================================
-- SECTION 4 — DEPOSITS TABLE COLUMNS AND CONSTRAINT
-- ============================================================================

SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'deposits'
ORDER BY ordinal_position;

-- Expected status CHECK: pending | approved | rejected
SELECT conname, pg_get_constraintdef(oid) AS constraint_def
FROM pg_constraint
WHERE conrelid = 'public.deposits'::regclass
  AND contype = 'c';


-- ============================================================================
-- SECTION 5 — WITHDRAWALS TABLE COLUMNS AND CONSTRAINT
-- ============================================================================

SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'withdrawals'
ORDER BY ordinal_position;

-- Expected status CHECK: pending | processing | completed | rejected
-- NOTE: Flutter admin writes 'completed' (NOT 'approved') — verified Batch 1.
SELECT conname, pg_get_constraintdef(oid) AS constraint_def
FROM pg_constraint
WHERE conrelid = 'public.withdrawals'::regclass
  AND contype = 'c';


-- ============================================================================
-- SECTION 6 — IS_ADMIN() FUNCTION
-- ============================================================================

SELECT
    proname                                    AS function_name,
    pg_get_function_identity_arguments(oid)    AS arguments,
    prosecdef                                  AS security_definer,
    proconfig                                  AS config_settings
FROM pg_proc
WHERE proname = 'is_admin'
  AND pronamespace = 'public'::regnamespace;

-- Expected: 1 row, security_definer = true, config = {search_path=public}


-- ============================================================================
-- SECTION 7 — WALLET RPC FUNCTIONS
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

-- Expected: 4 rows (all security_definer = true)


-- ============================================================================
-- SECTION 8 — NOTIFICATIONS INSERT POLICY (Batch 1 security fix)
-- ============================================================================

SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'notifications'
ORDER BY policyname;

-- "System can create notifications" should have:
--   with_check = auth.uid() = user_id OR is_admin()
--   NOT the old: with_check = TRUE


-- ============================================================================
-- SECTION 9 — APPLICATIONS UPDATE WITH CHECK (Batch 1 security fix)
-- ============================================================================

SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'applications'
  AND cmd        = 'UPDATE'
ORDER BY policyname;

-- "Creators can update own applications" should have:
--   with_check restricting status IN ('pending','withdrawn')


-- ============================================================================
-- SECTION 10 — TRANSACTIONS TABLE STATUS
-- ============================================================================

-- Check if transactions table exists (it's live but legacy/unused by Flutter)
SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'transactions'
) AS transactions_exists;

-- If it exists, check its RLS policies
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'transactions'
ORDER BY policyname;

-- After 08_RLS_GLOBAL_CLEANUP.sql:
--   "Allow all for public transactions" should NOT appear
--   "Users can view own transactions" and "Admins can manage transactions" should appear


-- ============================================================================
-- SECTION 11 — ESCROWS TABLE STATUS
-- ============================================================================

SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'escrows'
) AS escrows_exists;

SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'escrows'
ORDER BY policyname;

-- After 08_RLS_GLOBAL_CLEANUP.sql:
--   "Allow all for public escrows" should NOT appear


-- ============================================================================
-- SECTION 12 — CAMPAIGNS TABLE CONSTRAINTS
-- ============================================================================

SELECT conname, pg_get_constraintdef(oid) AS constraint_def
FROM pg_constraint
WHERE conrelid = 'public.campaigns'::regclass
  AND contype  = 'c'
ORDER BY conname;

-- Expected:
--   campaigns_platform_check — includes 'facebook'
--   campaigns_status_check   — includes 'closed'
--   campaigns_gender_check   — 'all' | 'male' | 'female'


-- ============================================================================
-- SECTION 13 — APPLICATIONS TABLE COLUMNS (job submission fields)
-- ============================================================================

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'applications'
ORDER BY ordinal_position;

-- Expected extra columns (from JOBS_VIA_CAMPAIGNS.sql + add_application_fields.sql):
--   submission_type, submission_url, submission_note, rejection_reason,
--   submitted_at, reviewed_at, reviewed_by,
--   applicant_name, location, category, city, state,
--   contact_number, instagram_url, followers_count


-- ============================================================================
-- SECTION 14 — WALLET AUTO-CREATION TRIGGER
-- ============================================================================

SELECT tgname, tgenabled, tgtype
FROM pg_trigger
WHERE tgrelid = 'public.users'::regclass
  AND NOT tgisinternal;

-- Expected on public.users:
--   on_user_created_create_wallet         (wallet auto-creation)
--   trg_prevent_user_self_escalation      (BEFORE UPDATE self-escalation guard)
-- Also: on_auth_user_created on auth.users


-- ============================================================================
-- SECTION 14b — SELF-ESCALATION GUARD (function + trigger)
-- ============================================================================

SELECT
    proname                   AS function_name,
    prosecdef                 AS security_definer,
    proconfig                 AS config_settings
FROM pg_proc
WHERE proname = 'prevent_user_self_escalation'
  AND pronamespace = 'public'::regnamespace;
-- Expected: 1 row, security_definer = true, config = {search_path=public}

SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgrelid = 'public.users'::regclass
  AND tgname = 'trg_prevent_user_self_escalation';
-- Expected: 1 row (BEFORE UPDATE trigger enabled).
--
-- MANUAL BEHAVIOR TEST (run as a NON-admin user via the app or a scoped session):
--   UPDATE public.users SET bio = 'new bio' WHERE id = auth.uid();      -- should succeed
--   UPDATE public.users SET role = 'admin'  WHERE id = auth.uid();      -- role stays unchanged
--   UPDATE public.users SET is_verified = true WHERE id = auth.uid();   -- stays false
-- After each escalation attempt, re-select the row: role/is_verified/account_status/
-- admin_sub_role must equal their prior values.


-- ============================================================================
-- SECTION 15 — SUBSCRIPTION_PAYMENTS TABLE AND RLS
-- ============================================================================

SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'subscription_payments'
) AS sub_payments_exists;

SELECT policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'subscription_payments'
ORDER BY policyname;

-- Expected: 4 policies (user create+read own, admin read all+update)


-- ============================================================================
-- SECTION 16 — MESSAGES SOFT-STATE COLUMNS
-- ============================================================================

SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'messages'
  AND column_name IN ('is_unsent', 'edited_at', 'deleted_for')
ORDER BY column_name;

-- Expected: 3 rows (after running 06_MESSAGES_SOFT_STATE.sql)


-- ============================================================================
-- SECTION 17 — COMPLETE POLICY INVENTORY FOR CRITICAL TABLES
-- ============================================================================

SELECT
    tablename,
    policyname,
    cmd,
    left(coalesce(qual, ''), 80)       AS using_clause,
    left(coalesce(with_check, ''), 80) AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
      'wallets', 'deposits', 'withdrawals', 'notifications',
      'applications', 'campaigns', 'users', 'subscription_payments',
      'transactions', 'escrows'
  )
ORDER BY tablename, policyname;


-- ============================================================================
-- SECTION 18 — FOLLOWS / USER_FOLLOWS TABLES
-- ============================================================================

-- The live DB has TWO follow tables:
--   follows       — created by 05_ADDITIONAL_TABLES.sql, used by Flutter
--                    columns: follower_id (uuid), following_id (uuid)
--   user_follows  — pre-existing live table, NOT used by Flutter
--                    columns: id (uuid), follower_uid (text), following_uid (text), created_at

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('follows', 'user_follows');

-- Verify user_follows live schema matches expected (text uid columns)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'user_follows'
ORDER BY ordinal_position;
-- Expected: id uuid, follower_uid text, following_uid text, created_at timestamptz

SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('follows', 'user_follows')
ORDER BY tablename, policyname;
-- After cleanup (user_follows):
--   "Authenticated users can read follows" — SELECT / auth.role() = 'authenticated'
--   "Users can manage own follows"         — ALL / follower_uid or following_uid / follower_uid


-- ============================================================================
-- SECTION 18b — VERIFICATION_REQUESTS SCHEMA + POLICIES
-- ============================================================================

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'verification_requests'
ORDER BY ordinal_position;
-- Expected: id uuid, "creatorId" text, "creatorName" text, "creatorEmail" text,
--           "proofLink" text, status text, "createdAt" timestamptz

SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'verification_requests'
ORDER BY policyname;
-- After cleanup:
--   "Creators read own verification_requests"   — SELECT / creatorId match
--   "Creators create own verification_requests"  — INSERT / creatorId match
--   "Admins manage verification_requests"        — ALL / is_admin()


-- ============================================================================
-- SECTION 18c — CAMPAIGN_ACCESS_REQUESTS SCHEMA + POLICIES
-- ============================================================================

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'campaign_access_requests'
ORDER BY ordinal_position;
-- Expected: id uuid, "brandId" text, "brandName" text, status text, "createdAt" timestamptz
-- NOTE: No per-user/creator ownership column exists.

SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'campaign_access_requests'
ORDER BY policyname;
-- After cleanup:
--   "Admins manage campaign_access_requests" — ALL / is_admin()
-- NOTE: No user-scoped policy — there is no ownership column.


-- ============================================================================
-- SECTION 19 — JOBS SLOT ENFORCEMENT TRIGGER
-- ============================================================================

SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgrelid = 'public.applications'::regclass
  AND NOT tgisinternal;

-- Expected: enforce_job_slots trigger


-- ============================================================================
-- SECTION 20 — FINAL HEALTH CHECK: any remaining issues
-- ============================================================================

-- Count tables with ALL=true policies after cleanup:
SELECT
    COUNT(*) AS remaining_all_true_policies,
    array_agg(tablename || '.' || policyname ORDER BY tablename) AS policy_list
FROM pg_policies
WHERE schemaname = 'public'
  AND (
      lower(coalesce(qual, ''))       = 'true'
      OR lower(coalesce(with_check, '')) = 'true'
  )
  AND (cmd = 'ALL' OR with_check = 'true');

-- EXPECTED: 0 remaining ALL=true policies (only SELECT=true on config/follows are OK)
