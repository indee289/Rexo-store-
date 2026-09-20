# supabase/final_fixes/ — Rexo SQL Fix Package

> **These SQL files have NOT been deployed to the live Supabase database.**
> You must run them manually in the Supabase Dashboard → SQL Editor.

This folder is the **single authoritative SQL package** for the Rexo project.
It consolidates all migrations, fixes, and patches identified during the
Batch 1–3 engineering audit and the final Live DB Alignment session.

---

## LIVE DATABASE FINDINGS (confirmed)

| Finding | Impact |
|---|---|
| `wallets`, `deposits`, `withdrawals` tables **do NOT exist** in live DB | **CRITICAL** — entire wallet/deposit/withdrawal flow is broken |
| Campaigns live columns: `payout_per_creator`, `slots`, `cover_image` | Multiple Dart files were using wrong names — **fixed in Dart** |
| `transactions` table exists (0 rows), has `ALL=true` public policy | **CRITICAL security** — legacy unused table with open access |
| `escrows` table exists, has `ALL=true` public policy | **CRITICAL security** — unused table with open access |
| 24 live tables have "Allow all for public" ALL=true policies | **CRITICAL security** — created directly in Supabase Dashboard, not in repo |
| Notifications INSERT `WITH CHECK(TRUE)` still in live DB | **HIGH security** — fixed in `01_RLS_FIXES.sql` (must deploy) |
| Applications UPDATE missing `WITH CHECK` | **HIGH security** — fixed in `01_RLS_FIXES.sql` |
| Recovery tables (`recovery_*`) exist in live DB, not in repo SQL | Independent subsystem — secured to admin-only in `08_RLS_GLOBAL_CLEANUP.sql` |

---

## Files in Execution Order

| # | File | Purpose | Priority | Run Required? |
|---|------|---------|----------|---------------|
| 0 | `99_VERIFICATION_QUERIES.sql` | Run Section 0 FIRST to see current state | — | 🔍 READ-ONLY |
| 1 | `01_RLS_FIXES.sql` | is_admin() + 6 security policy fixes | 🔴 CRITICAL | ✅ RUN FIRST |
| 2 | `07_WALLET_TABLES.sql` | Create wallets, deposits, withdrawals | 🔴 CRITICAL | ✅ RUN SECOND |
| 3 | `02_WALLET_AND_RPC_FIXES.sql` | credit_wallet / debit_wallet RPCs | 🔴 CRITICAL | ✅ RUN THIRD |
| 4 | `08_RLS_GLOBAL_CLEANUP.sql` | Remove ALL=true policies on 24 tables | 🔴 CRITICAL | ✅ RUN FOURTH |
| 5 | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` | Campaign/job column extensions | 🟡 HIGH | ✅ RUN FIFTH |
| 6 | `04_AUTH_USER_SETUP.sql` | Auth→users trigger + wallet backfill | 🟡 HIGH | ✅ RUN SIXTH |
| 7 | `05_ADDITIONAL_TABLES.sql` | follows, banners, subscription_payments | 🟡 HIGH | ✅ RUN SEVENTH |
| 8 | `06_MESSAGES_SOFT_STATE.sql` | Edit/unsend/delete-for-me in messages | 🟢 OPTIONAL | ⚠️ Run if needed |
| 9 | `99_VERIFICATION_QUERIES.sql` | Run in full AFTER to verify deployment | — | 🔍 READ-ONLY |

> ⚠️ **Order matters.** `01_RLS_FIXES.sql` MUST run before `07_WALLET_TABLES.sql`
> and `08_RLS_GLOBAL_CLEANUP.sql`, because both call `public.is_admin()`, which is
> created in `01_RLS_FIXES.sql`. Running `07` or `08` first will fail with
> `function public.is_admin() does not exist`.

---

## CRITICAL: Wallet Tables Missing

The live DB has **no `wallets`, `deposits`, or `withdrawals` tables**.

The Flutter app is completely broken for:
- Wallet balance display
- Deposit submissions
- Withdrawal submissions
- Admin deposit/withdrawal approval queue
- Transaction history

**Run `01_RLS_FIXES.sql` first** (it defines `public.is_admin()`), **then
`07_WALLET_TABLES.sql`** — `07` references `public.is_admin()` in its policies,
so it must run after `01`.

After running those, also run `04_AUTH_USER_SETUP.sql` which backfills wallet rows
for users who already exist.

---

## CRITICAL: Campaign Column Names (Dart Fixed)

Live DB authoritative columns:

| ❌ Old (wrong in Dart) | ✅ Correct (live DB + Dart fixed) |
|---|---|
| `per_creator_payout` | `payout_per_creator` |
| `total_slots` | `slots` |
| `cover_image_url` | `cover_image` |

**Dart files have been fixed.** No SQL column additions needed — these columns already exist in the live DB.

`jobs_provider.dart` uses `'cover_image_url'` as an **internal UI alias** only
(line 45: `'cover_image_url': row['cover_image']`). This is correct — it maps the live
DB column name to the key that UI widgets read. The alias does NOT write to the DB.

---

## CRITICAL: ALL=true Public Policies

24 live tables have a "Allow all for public" `FOR ALL / USING(true) / WITH CHECK(true)` policy.
These were created directly in the Supabase Dashboard — they are NOT in any repo SQL file.

**`08_RLS_GLOBAL_CLEANUP.sql` removes all of them.**

Tables the Flutter app uses: applications, campaigns, notifications, reviews, users.
Correct policies already exist for these in `schema.sql` and `01_RLS_FIXES.sql`.

Tables the Flutter app does NOT use: transactions, escrows, config, chat_rooms,
chat_messages, posts, post_comments, post_likes, recovery_* (7 tables),
campaign_access_requests, verification_requests, admin_audit_logs, user_follows.

---

## Notes on Specific Tables

### transactions (live, 0 rows, legacy/unused)
- NOT used by the Flutter app (app uses deposits + withdrawals instead)
- After cleanup: users can read own rows, admins manage all
- DO NOT delete this table (may be used by external system)

### escrows (live, used for campaign escrow tracking)
- NOT used by the Flutter app directly (app uses `wallets.escrow_balance` column)
- After cleanup: existing 4 correct policies remain; only ALL=true is removed

### config (live, public read is intentional)
- Public SELECT is preserved (config data is designed to be publicly readable)
- ALL=true write access is removed; admin-only write applied

### recovery_* tables (live, 7 tables, independent subsystem)
- NOT in this repository's schema.sql
- NOT referenced in Flutter code or admin_app
- Likely a third-party customer-support / dispute-recovery system
- Restricted to admin-only access (safe fallback)
- If the recovery system needs specific auth, adjust policies after consulting whoever owns it

### user_follows (live, NOT used by Flutter)
- Live columns (verified): `id`, `follower_uid` (text), `following_uid` (text), `created_at`
- The Flutter app does NOT use this table — it uses a separate `follows` table
  (`follower_id` / `following_id`) created by `05_ADDITIONAL_TABLES.sql`
- After cleanup: authenticated users can read; a user can only insert/delete rows
  where `auth.uid()::text = follower_uid`

### verification_requests (live)
- Live columns (verified): `id`, `creatorId` (text), `creatorName`, `creatorEmail`,
  `proofLink`, `status`, `createdAt` (all camelCase, quoted in SQL)
- Ownership column is `"creatorId"` (text UID)
- After cleanup: a creator can read + insert their own request
  (`auth.uid()::text = "creatorId"::text`); admins manage all

### campaign_access_requests (live)
- Live columns (verified): `id`, `brandId` (text), `brandName`, `status`, `createdAt`
- **There is NO per-user/creator ownership column** — rows are keyed by brand only,
  with no column mapping a row to the authenticated end-user who requested access
- Because ownership cannot be expressed safely in RLS, this table is secured as
  **admin-only** management after removing the `ALL=true` override
- ⚠️ **Limitation:** end-users cannot read/insert their own access requests via RLS
  until an ownership column (e.g. a text `creatorId`/`userId`) is added to the table.
  If/when that column is added, add a user-scoped policy mirroring
  `verification_requests`.

---

## SQL Safety Notes

- All `CREATE POLICY` statements are preceded by `DROP POLICY IF EXISTS`
- All functions use `CREATE OR REPLACE`
- All tables use `CREATE TABLE IF NOT EXISTS`
- All `08_RLS_GLOBAL_CLEANUP.sql` operations wrap table existence checks in `DO $$ BEGIN IF EXISTS(...)`
- No `DROP TABLE` or `DROP COLUMN` statements
- No destructive migrations

---

## Old SQL Files — Superseded by This Package

| Old file | Superseded by |
|---|---|
| `fix_admin_rls.sql` | `01_RLS_FIXES.sql` |
| `PERMANENT_FIX_run_this.sql` | `01_RLS_FIXES.sql` |
| `fix_recursion.sql` | `01_RLS_FIXES.sql` |
| `wallet_balance_rpc.sql` | `02_WALLET_AND_RPC_FIXES.sql` |
| `migrations/add_wallet_function_aliases.sql` | `02_WALLET_AND_RPC_FIXES.sql` |
| `add_campaign_columns.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` |
| `CAMPAIGN_JOB_EXTRA_FIELDS.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` |
| `add_application_fields.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` |
| `JOBS_VIA_CAMPAIGNS.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` |
| `JOBS_USE_PAYOUT_MODEL.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` |
| `add_campaign_delete_rls.sql` | `01_RLS_FIXES.sql` |
| `fix_user_creation.sql` | `04_AUTH_USER_SETUP.sql` |
| `banners_migration.sql` | `05_ADDITIONAL_TABLES.sql` |
| `add_follows_table.sql` | `05_ADDITIONAL_TABLES.sql` |
| `add_subscription_payments.sql` | `05_ADDITIONAL_TABLES.sql` |
| `fix_subscription_plans_schema.sql` | `05_ADDITIONAL_TABLES.sql` |
| `add_product_type.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` |
| `migrations/add_messages_soft_state.sql` | `06_MESSAGES_SOFT_STATE.sql` |
