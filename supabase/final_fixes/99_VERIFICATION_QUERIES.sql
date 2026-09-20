-- ============================================================================
-- 99_VERIFICATION_QUERIES.sql
-- Rexo — Read-Only Live Database Verification Queries
--
-- PURPOSE
--   Verify the live Supabase database state before and after applying the
--   final_fixes/ SQL package. Run in the Supabase Dashboard → SQL Editor.
--   ALL QUERIES ARE READ-ONLY (SELECT / pg_policies / information_schema).
--
-- CONFIRMED LIVE SCHEMA NOTES (Stage C, September 2026)
--   public.users
--     Identity column : uid  (text, NOT NULL) — NOT id/uuid
--     Privileged cols : role (text, DEFAULT 'CREATOR')
--                       "isVerified" (boolean, DEFAULT false)
--                       "isBanned"   (boolean)
--     NOT present     : account_status, admin_sub_role, is_verified
--
--   public.notifications
--     Ownership col   : "userId" (text, NOT NULL)   — NOT user_id
--     Content cols    : "title", "message", "type", "read", "link", "createdAt"
--     NOT present     : user_id, body, is_read, created_at
--
--   public.transactions
--     Ownership col   : "userId" (text, NOT NULL)   — camelCase, quoted in SQL
--
--   public.wallets / deposits / withdrawals — EXIST in live DB (confirmed)
--
-- USAGE
--   Run each section independently in the SQL editor.
--   Run SECTION 0 FIRST (before any SQL), and again LAST (after all SQL).
-- ============================================================================


-- ============================================================================
-- SECTION 0 — GLOBAL DANGEROUS POLICY SCAN
-- Run this FIRST before any deployment, and again AFTER all files are applied.
-- ============================================================================

SELECT
    tablename,
    policyname,
    cmd,
    qual        AS using_clause,
    with_check  AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND (
      lower(coalesce(qual,       '')) = 'true'
      OR lower(coalesce(with_check, '')) = 'true'
  )
ORDER BY tablename, policyname;

-- EXPECTED after full cleanup:
--   config — SELECT / true   (intentional: public config read — preserve this)
--
-- KNOWN REMAINING after cleanup (intentional):
--   recovery_* (7 tables) — intentionally untouched pending access model review
--
-- ANY OTHER TABLE = still-dangerous policy that needs attention.


-- ============================================================================
-- SECTION 1 — CAMPAIGNS TABLE COLUMNS
-- ============================================================================

SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'campaigns'
ORDER BY ordinal_position;

-- Confirmed live columns (Dart already fixed):
--   payout_per_creator  (NOT per_creator_payout)
--   slots               (NOT total_slots)
--   cover_image         (NOT cover_image_url)


-- ============================================================================
-- SECTION 2 — WALLET TABLES EXIST?
-- ============================================================================

SELECT table_name,
       (SELECT COUNT(*) FROM information_schema.columns c
        WHERE c.table_schema = 'public'
          AND c.table_name   = t.table_name) AS col_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('wallets', 'deposits', 'withdrawals')
ORDER BY table_name;

-- EXPECTED: 3 rows — all three tables exist (confirmed in live DB).


-- ============================================================================
-- SECTION 3 — WALLET TABLE COLUMNS
-- ============================================================================

SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('wallets', 'deposits', 'withdrawals')
ORDER BY table_name, ordinal_position;

-- Confirmed live schemas:
--   wallets:     id, user_id, available_balance, escrow_balance,
--                total_earnings, total_withdrawn, is_frozen, currency,
--                created_at, updated_at
--   deposits:    id, user_id, amount, payment_method, transaction_ref,
--                proof_url, status, admin_notes, created_at, processed_at
--   withdrawals: id, user_id, amount, method, payout_details,
--                status, transaction_ref, admin_notes, created_at, processed_at


-- ============================================================================
-- SECTION 4 — WALLET TABLE POLICIES
-- ============================================================================

SELECT tablename, policyname, cmd,
       left(coalesce(qual,       ''), 80) AS using_clause,
       left(coalesce(with_check, ''), 80) AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('wallets', 'deposits', 'withdrawals')
ORDER BY tablename, policyname;

-- After 07_WALLET_TABLES.sql:
--   deposits:    "Users can create deposits"      INSERT  WITH CHECK auth.uid()=user_id
--                "Users can read own deposits"    SELECT  auth.uid()=user_id
--                "Admins can read all deposits"   SELECT  is_admin()
--                "Admins can update deposits"     UPDATE  is_admin()
--   withdrawals: same pattern as deposits
--   wallets:     "Users can read own wallet"      SELECT  auth.uid()=user_id
--                "Admins can read all wallets"    SELECT  is_admin()
--                "Admins can update wallets"      UPDATE  is_admin()
-- Key check: "Users can create deposits/withdrawals" must have WITH CHECK.


-- ============================================================================
-- SECTION 5 — DEPOSITS / WITHDRAWALS STATUS CONSTRAINTS
-- ============================================================================

SELECT conname, pg_get_constraintdef(oid) AS constraint_def
FROM pg_constraint
WHERE conrelid IN (
    'public.deposits'::regclass,
    'public.withdrawals'::regclass
)
AND contype = 'c'
ORDER BY conrelid::text, conname;

-- Expected deposits status: pending | approved | rejected
-- Expected withdrawals status: pending | processing | completed | rejected
-- NOTE: Flutter admin writes 'completed' (NOT 'approved') for withdrawals.


-- ============================================================================
-- SECTION 6 — is_admin() FUNCTION
-- ============================================================================

SELECT
    proname          AS function_name,
    prosecdef        AS security_definer,
    proconfig        AS config_settings,
    pg_get_functiondef(oid) AS full_definition
FROM pg_proc
WHERE proname = 'is_admin'
  AND pronamespace = 'public'::regnamespace;

-- Expected: 1 row, security_definer=true, config={search_path=public}
-- Stage C fix: definition must use  uid = auth.uid()::text  (NOT id/uuid)
-- Confirm the definition body does NOT contain:  id::text = auth.uid()::text


-- ============================================================================
-- SECTION 7 — WALLET RPC FUNCTIONS
-- ============================================================================

SELECT
    proname          AS function_name,
    pg_get_function_identity_arguments(oid) AS arguments,
    prosecdef        AS security_definer
FROM pg_proc
WHERE proname IN (
    'credit_wallet', 'debit_wallet',
    'increment_wallet_balance', 'decrement_wallet_balance'
)
AND pronamespace = 'public'::regnamespace;

-- Expected: 4 rows (all security_definer = true)


-- ============================================================================
-- SECTION 8 — NOTIFICATIONS POLICIES + SCHEMA
-- ============================================================================

-- Schema
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'notifications'
ORDER BY ordinal_position;

-- Confirmed live columns: "userId"(text), "title", "message", "type",
--   "read"(bool), "link", "createdAt"(timestamptz)
-- NOT PRESENT: user_id, body, is_read, created_at
-- ⚠️ DART BUG: Dart sends user_id/body/is_read/created_at — all wrong.
--    Notifications will fail at runtime until Dart code is updated.

-- Policies
SELECT policyname, cmd,
       left(coalesce(qual,       ''), 100) AS using_clause,
       left(coalesce(with_check, ''), 100) AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'notifications'
ORDER BY policyname;

-- Expected after 01_RLS_FIXES.sql + 08_RLS_GLOBAL_CLEANUP.sql:
--   "Admins/system can insert notifications"  INSERT  (no WITH CHECK — preserved)
--   "Allow all for public notifications"      — MUST NOT APPEAR (dropped in §4 of 08)
--   "System can create notifications"         INSERT  WITH CHECK userId match OR is_admin()
--   "Users can update own notifications"      UPDATE  userId match OR is_admin()
--   "Users can view own notifications"        SELECT  userId match OR is_admin()
--   "Users or Admin can delete notifications" DELETE  userId match OR is_admin()


-- ============================================================================
-- SECTION 9 — APPLICATIONS UPDATE POLICY
-- ============================================================================

SELECT policyname, cmd,
       left(coalesce(qual,       ''), 100) AS using_clause,
       left(coalesce(with_check, ''), 100) AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'applications'
ORDER BY policyname;

-- After 01_RLS_FIXES.sql + 08_RLS_GLOBAL_CLEANUP.sql:
--   "Allow all applications"             — MUST NOT APPEAR
--   "Allow all for applications"         — MUST NOT APPEAR
--   "Allow all for public applications"  — MUST NOT APPEAR
--   "Creators can update own applications" UPDATE WITH CHECK status IN ('pending','withdrawn')


-- ============================================================================
-- SECTION 10 — TRANSACTIONS POLICIES + SCHEMA
-- ============================================================================

-- Schema
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'transactions'
ORDER BY ordinal_position;

-- Confirmed live columns: id(uuid), "userId"(text), amount(numeric),
--   type(text), status(text DEFAULT 'Pending'), "createdAt"(timestamptz)

-- Policies
SELECT policyname, cmd,
       left(coalesce(qual,       ''), 100) AS using_clause,
       left(coalesce(with_check, ''), 100) AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'transactions'
ORDER BY policyname;

-- After 08_RLS_GLOBAL_CLEANUP.sql:
--   "Allow all for public transactions"  — MUST NOT APPEAR
--   "Admins can delete transactions"     DELETE  is_admin()        (preserved)
--   "Admins can update transactions"     UPDATE  is_admin()        (preserved)
--   "Admins/system can insert transactions" INSERT               (preserved)
--   "Users can view own transactions"    SELECT  "userId"=auth.uid()::text OR is_admin()


-- ============================================================================
-- SECTION 11 — USERS SCHEMA + POLICIES + TRIGGERS
-- ============================================================================

-- Schema
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'users'
ORDER BY ordinal_position;

-- Confirmed live identity column: uid (text) — NOT id/uuid for RLS purposes
-- Confirmed privileged cols: role, "isVerified", "isBanned"
-- NOT PRESENT: account_status, admin_sub_role, is_verified

-- Policies
SELECT policyname, cmd,
       left(coalesce(qual,       ''), 100) AS using_clause,
       left(coalesce(with_check, ''), 100) AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'users'
ORDER BY policyname;

-- After 01_RLS_FIXES.sql + 08_RLS_GLOBAL_CLEANUP.sql:
--   "Allow all for public users"      — MUST NOT APPEAR
--   "Anyone can view users"           SELECT  hidden=false OR uid=auth.uid()... (preserved)
--   "Users can insert own profile"    INSERT                                   (preserved)
--   "Users can update own profile"    UPDATE  uid=auth.uid()::text OR is_admin()(preserved)
--   "Users or Admin can delete..."    DELETE                                   (preserved)

-- Triggers
SELECT tgname, tgenabled, pg_get_triggerdef(oid) AS trigger_def
FROM pg_trigger
WHERE tgrelid = 'public.users'::regclass
  AND NOT tgisinternal
ORDER BY tgname;

-- Expected after 01_RLS_FIXES.sql:
--   on_user_created_create_wallet         (wallet auto-creation — already exists)
--   trg_prevent_user_self_escalation      (BEFORE UPDATE — created by 01_RLS_FIXES.sql)
--
-- Verify trigger definition uses:
--   NEW.role       := OLD.role
--   NEW."isVerified" := OLD."isVerified"
--   NEW."isBanned"   := OLD."isBanned"
-- And does NOT reference account_status, admin_sub_role, or is_verified.


-- ============================================================================
-- SECTION 12 — SELF-ESCALATION FUNCTION
-- ============================================================================

SELECT proname, prosecdef, proconfig,
       pg_get_functiondef(oid) AS full_definition
FROM pg_proc
WHERE proname = 'prevent_user_self_escalation'
  AND pronamespace = 'public'::regnamespace;

-- Expected: 1 row after 01_RLS_FIXES.sql runs.
-- security_definer = true, config = {search_path=public}
-- Body must NOT reference: account_status, admin_sub_role, is_verified


-- ============================================================================
-- SECTION 13 — CAMPAIGNS POLICIES (dangerous overrides removed?)
-- ============================================================================

SELECT policyname, cmd,
       left(coalesce(qual, ''), 80) AS using_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'campaigns'
ORDER BY policyname;

-- After 08_RLS_GLOBAL_CLEANUP.sql:
--   "Allow all for campaigns"        — MUST NOT APPEAR
--   "Allow all for public campaigns" — MUST NOT APPEAR


-- ============================================================================
-- SECTION 14 — REVIEWS POLICIES
-- ============================================================================

SELECT policyname, cmd,
       left(coalesce(qual, ''), 80) AS using_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'reviews'
ORDER BY policyname;

-- After 08_RLS_GLOBAL_CLEANUP.sql:
--   "Allow all for public reviews"  — MUST NOT APPEAR


-- ============================================================================
-- SECTION 15 — FOLLOW TABLES SCHEMA + POLICIES
-- ============================================================================

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('follows', 'user_follows');

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'user_follows'
ORDER BY ordinal_position;
-- Expected: id(uuid), follower_uid(text), following_uid(text), created_at(timestamptz)

SELECT policyname, cmd,
       left(coalesce(qual,       ''), 100) AS using_clause,
       left(coalesce(with_check, ''), 100) AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('follows', 'user_follows')
ORDER BY tablename, policyname;


-- ============================================================================
-- SECTION 16 — VERIFICATION_REQUESTS SCHEMA + POLICIES
-- ============================================================================

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'verification_requests'
ORDER BY ordinal_position;
-- Expected: id, "creatorId"(text), "creatorName", "creatorEmail",
--           "proofLink", status, "createdAt"

SELECT policyname, cmd,
       left(coalesce(qual,       ''), 100) AS using_clause,
       left(coalesce(with_check, ''), 100) AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'verification_requests'
ORDER BY policyname;
-- After 08_RLS_GLOBAL_CLEANUP.sql:
--   "Creators read own verification_requests"    SELECT  creatorId match
--   "Creators create own verification_requests"  INSERT  creatorId match
--   "Admins manage verification_requests"        ALL     is_admin()


-- ============================================================================
-- SECTION 17 — CAMPAIGN_ACCESS_REQUESTS SCHEMA + POLICIES
-- ============================================================================

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'campaign_access_requests'
ORDER BY ordinal_position;
-- Expected: id, "brandId"(text), "brandName", status, "createdAt"
-- NOTE: No per-user ownership column → admin-only RLS.

SELECT policyname, cmd,
       left(coalesce(qual, ''), 100) AS using_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'campaign_access_requests'
ORDER BY policyname;
-- After 08_RLS_GLOBAL_CLEANUP.sql:
--   "Admins manage campaign_access_requests"  ALL  is_admin()


-- ============================================================================
-- SECTION 18 — RECOVERY_* TABLES STATUS (informational — do not modify)
-- ============================================================================

SELECT tablename, policyname, cmd,
       left(coalesce(qual, ''), 60) AS using_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename LIKE 'recovery_%'
ORDER BY tablename, policyname;

-- These policies are intentionally NOT changed by this SQL package.
-- Their dangerous ALL=true policies remain until the recovery system's
-- access model is confirmed and a targeted fix is designed.


-- ============================================================================
-- SECTION 19 — COMPLETE POLICY INVENTORY (all tables)
-- ============================================================================

SELECT
    tablename,
    policyname,
    cmd,
    left(coalesce(qual,       ''), 70) AS using_clause,
    left(coalesce(with_check, ''), 70) AS check_clause
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;


-- ============================================================================
-- SECTION 20 — FINAL HEALTH CHECK
-- ============================================================================

SELECT
    COUNT(*) FILTER (
        WHERE lower(coalesce(qual,''))='true'
        OR lower(coalesce(with_check,''))='true'
    ) AS remaining_true_policies,
    COUNT(*) FILTER (
        WHERE lower(coalesce(qual,''))='true'
        AND cmd = 'SELECT'
        AND tablename = 'config'
    ) AS intentional_config_read,
    COUNT(*) FILTER (
        WHERE tablename LIKE 'recovery_%'
        AND (lower(coalesce(qual,''))='true'
             OR lower(coalesce(with_check,''))='true')
    ) AS recovery_tables_pending_review
FROM pg_policies
WHERE schemaname = 'public';

-- EXPECTED:
--   remaining_true_policies     = 1  (config SELECT/true only)
--   intentional_config_read     = 1
--   recovery_tables_pending_review = 7  (known gap — intentional)
--
-- If remaining_true_policies > 1 + (recovery count), something was missed.
