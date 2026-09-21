# supabase/final_fixes/ — Rexo SQL Fix Package

> **These SQL files have NOT been fully deployed to the live Supabase database.**
> Apply them manually in Supabase Dashboard → SQL Editor in the order shown below.
> Run `99_VERIFICATION_QUERIES.sql` Section 0 before and after every file.

---

## CONFIRMED LIVE DATABASE STATE (September 2026 — Stage C audit)

| Finding | Impact | Status |
|---|---|---|
| `wallets`, `deposits`, `withdrawals` tables **EXIST** in live DB | Tables present — `07` skips CREATE safely | ✅ Confirmed |
| Live `deposits`/`withdrawals` INSERT policies have **no WITH CHECK** | Any user can forge `user_id` on insert | 🔴 Fixed in `07` |
| `users` identity column is `uid` (text), **NOT** `id` (uuid) | All RLS policies must use `uid = auth.uid()::text` | 🔴 Fixed in `01` |
| `users.account_status` **DOES NOT EXIST** | `04` and `01` previously crashed on it | 🔴 Fixed in `01`/`04` |
| `users.admin_sub_role` **DOES NOT EXIST** | `04` previously crashed on it | 🔴 Fixed in `04` |
| `users.is_verified` **DOES NOT EXIST** | Live column is `"isVerified"` (camelCase) | 🔴 Fixed in `01`/`04` |
| `notifications` ownership column is `"userId"` (camelCase text) | `01` previously used `user_id` → crash | 🔴 Fixed in `01` |
| `transactions` already had `"Users can view own transactions"` | `08` crashed trying to recreate it | 🔴 Fixed in `08` |
| `applications` had **3** dangerous ALL=true policy names | Previous `08` only dropped 1 of the 3 | 🔴 Fixed in `08` |
| `campaigns` had **2** dangerous ALL=true policy names | Previous `08` only dropped 1 of the 2 | 🔴 Fixed in `08` |
| 38 dangerous `ALL/true` policies still in live DB after partial run | 7 are recovery_* (left intentionally) | 🟡 Partial — see below |
| `is_admin()` already exists in live DB | `01` uses `CREATE OR REPLACE` — safe | ✅ Confirmed |
| `handle_new_user_wallet()` already exists | `07` uses `CREATE OR REPLACE` — safe | ✅ Confirmed |
| `prevent_user_self_escalation()` **DOES NOT EXIST** | Created by `01_RLS_FIXES.sql` | 🔴 Fixed in `01` |
| Campaigns live columns: `payout_per_creator`, `slots`, `cover_image` | Dart already fixed (previous batch) | ✅ Done |

---

## ✅ DART-SIDE SCHEMA ALIGNMENT — COMPLETE (Stage D + Stage G)

All Dart-to-live-DB column mismatches have been resolved:

| Live column | Old Dart key | New Dart key | Fixed in |
|---|---|---|---|
| `users.username` | `'handle'` | `'username'` | Stage G |
| `users.profileImage` | `'avatar_url'` | `'profileImage'` | Stage G |
| `users."isVerified"` | `'is_verified'` | `'isVerified'` | Stage D |
| `users."isBanned"` | `'account_status'` | `'isBanned'` | Stage D |
| `users.uid` (identity) | `.eq('id', ...)` | `.eq('uid', ...)` | Stage D |
| `notifications."userId"` | `'user_id'` | `'userId'` | Stage D |
| `notifications.message` | `'body'` | `'message'` | Stage D |
| `notifications.read` | `'is_read'` | `'read'` | Stage D |
| `notifications."createdAt"` | `'created_at'` | `'createdAt'` | Stage D |
| `withdrawals` status | `'approved'` | `'completed'` | Stage D |
| `wallets.is_frozen` | `'status': 'frozen'` | `'is_frozen': true` | Stage D |

---

## Files in Execution Order

| # | File | Purpose | Priority | Run? |
|---|------|---------|----------|------|
| 0 | `99_VERIFICATION_QUERIES.sql` §0 | Current-state snapshot | — | 🔍 READ-ONLY first |
| 1 | `01_RLS_FIXES.sql` | `is_admin()` (uid-based) + notifications + trigger + applications + products/campaigns DELETE | 🔴 CRITICAL | ✅ RUN FIRST |
| 2 | `07_WALLET_TABLES.sql` | Wallet tables (already exist — skipped safely) + fix INSERT WITH CHECK on deposits/withdrawals | 🔴 CRITICAL | ✅ RUN SECOND |
| 3 | `02_WALLET_AND_RPC_FIXES.sql` | `credit_wallet` / `debit_wallet` RPCs | 🔴 CRITICAL | ✅ RUN THIRD |
| 4 | `08_RLS_GLOBAL_CLEANUP.sql` | Remove 38 ALL=true dangerous policies | 🔴 CRITICAL | ✅ RUN FOURTH |
| 5 | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` | Campaign/job column extensions | 🟡 HIGH | ✅ RUN FIFTH |
| 6 | `04_AUTH_USER_SETUP.sql` | Auth→users trigger + admin account setup | 🟡 HIGH | ✅ RUN SIXTH |
| 7 | `05_ADDITIONAL_TABLES.sql` | `follows`, banners, subscription_payments | 🟡 HIGH | ✅ RUN SEVENTH |
| 8 | `06_MESSAGES_SOFT_STATE.sql` | Edit/unsend/delete-for-me in messages | 🟢 OPTIONAL | ⚠️ Run if needed |
| 9 | `99_VERIFICATION_QUERIES.sql` full | Post-deployment verification | — | 🔍 READ-ONLY last |

> ⚠️ **Order is mandatory.** `01_RLS_FIXES.sql` MUST run before every other file
> because it defines `public.is_admin()`. `07`, `02`, `03`, `04`, `05`, and `08`
> all call `public.is_admin()` and will fail with
> `function public.is_admin() does not exist` if run out of order.

---

## CONFIRMED LIVE users SCHEMA (privileged columns)

| Column | Type | Default | Exists? |
|---|---|---|---|
| `uid` | text | — | ✅ YES — RLS identity column |
| `role` | text | `'CREATOR'` | ✅ YES — privileged |
| `"isVerified"` | boolean | `false` | ✅ YES — privileged (camelCase, quoted) |
| `"isBanned"` | boolean | — | ✅ YES — privileged (camelCase, quoted) |
| `account_status` | — | — | ❌ DOES NOT EXIST |
| `admin_sub_role` | — | — | ❌ DOES NOT EXIST |
| `is_verified` | — | — | ❌ DOES NOT EXIST (camelCase `"isVerified"` is correct) |

---

## CONFIRMED LIVE notifications SCHEMA

| Column | Type | Notes |
|---|---|---|
| `"userId"` | text NOT NULL | RLS ownership column |
| `"title"` | text | |
| `"message"` | text | ← NOT `body` |
| `"type"` | text | DEFAULT 'info' |
| `"read"` | boolean | DEFAULT false ← NOT `is_read` |
| `"link"` | text | |
| `"createdAt"` | timestamptz | ← NOT `created_at` |

---

## CONFIRMED LIVE transactions SCHEMA

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `"userId"` | text NOT NULL | RLS ownership (camelCase, quoted) |
| `amount` | numeric | |
| `type` | text | |
| `status` | text | DEFAULT 'Pending' |
| `"createdAt"` | timestamptz | |

Existing admin policies (INSERT/UPDATE/DELETE) are preserved.
Only the dangerous `"Allow all for public transactions"` ALL=true is removed.

---

## KNOWN REMAINING SECURITY GAP

### recovery_* tables (7 tables) — intentionally untouched

`recovery_requests`, `recovery_messages`, `recovery_evidence`,
`recovery_customer_updates`, `recovery_admin_notes`, `recovery_audit_logs`,
`recovery_payments` all have dangerous ALL=true policies.

These belong to an **independent subsystem** whose auth model has not been
confirmed. Blindly replacing their policies could break a live recovery
workflow. They are excluded from `08_RLS_GLOBAL_CLEANUP.sql` until:

1. The system that uses these tables is identified.
2. Its authentication and access requirements are confirmed.
3. A targeted policy replacement is written for that system specifically.

---

## SQL Safety Properties of This Package

- All `CREATE POLICY` statements have a `DROP POLICY IF EXISTS` immediately before
- All functions use `CREATE OR REPLACE`
- All tables use `CREATE TABLE IF NOT EXISTS`
- All `08` table operations are inside `DO $$ BEGIN IF EXISTS(...) THEN ... END IF; END $$`
- No `DROP TABLE` or `DROP COLUMN` statements anywhere
- No destructive migrations
- No columns invented that don't exist in the confirmed live schema
- `account_status`, `admin_sub_role`, `is_verified` (snake_case) referenced nowhere

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
