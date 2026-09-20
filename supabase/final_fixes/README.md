# supabase/final_fixes/ — Rexo SQL Fix Package

This folder is the **single authoritative SQL package** for the Rexo project.

It consolidates all migrations, fixes, and patches identified during the Batch 1–3 engineering audit. It replaces the scattered individual fix files in `supabase/` for deployment purposes.

> **IMPORTANT — Read before running anything.**
>
> These files have NOT been deployed to the live Supabase database.
> Run `99_VERIFICATION_QUERIES.sql` first to understand what is already deployed.

---

## Files in Execution Order

| # | File | Purpose | Run Required? | Notes |
|---|------|---------|---------------|-------|
| 1 | `01_RLS_FIXES.sql` | is_admin() function + 6 security policy fixes | ✅ **MUST RUN** | Run this first; all others depend on is_admin() |
| 2 | `02_WALLET_AND_RPC_FIXES.sql` | Atomic wallet RPC functions (credit_wallet, debit_wallet) | ✅ **MUST RUN** | Flutter admin calls these RPCs for all balance operations |
| 3 | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` | Campaign/job column extensions, slot trigger, product_type | ✅ **MUST RUN** | See CRITICAL NOTE below about column discrepancy |
| 4 | `04_AUTH_USER_SETUP.sql` | Auth→users trigger, wallet auto-creation, admin role setup | ✅ **MUST RUN** | Required for new user registrations to work |
| 5 | `05_ADDITIONAL_TABLES.sql` | follows, banners, subscription_payments tables + RLS | ✅ **MUST RUN** | Subscription payment flow requires subscription_payments |
| 6 | `06_MESSAGES_SOFT_STATE.sql` | Edit/unsend/delete-for-me on messages | ⚠️ OPTIONAL | Only needed if chat edit/unsend features are active |
| 7 | `99_VERIFICATION_QUERIES.sql` | Read-only verification queries | 🔍 RUN FIRST | Run before AND after the above files to verify |

---

## Execution Instructions

### Step 1 — Verify current DB state first
Open the Supabase Dashboard → SQL Editor and run `99_VERIFICATION_QUERIES.sql` Section 1 **only** to determine which campaign column names exist.

### Step 2 — Run in order
Paste each file (01 → 06) into the SQL Editor and run. Each file is idempotent — safe to run multiple times.

### Step 3 — Verify again after
Run `99_VERIFICATION_QUERIES.sql` in full to confirm the expected state.

---

## CRITICAL — Campaigns Column Name Discrepancy

⚠️ **This is the most important unresolved issue. Run `99_VERIFICATION_QUERIES.sql` Section 1 before anything else.**

Two conflicting sources exist in the repository:

| Source | Payout column | Slots column | Cover image column |
|--------|--------------|-------------|-------------------|
| `schema.sql` (older snapshot) | `per_creator_payout` | `total_slots` | `cover_image_url` |
| `JOBS_VIA_CAMPAIGNS.sql` (claims "ACTUAL live") | `payout_per_creator` | `slots` | `cover_image` |

Flutter code uses:
- `create_campaign_screen.dart` → writes `per_creator_payout`, `total_slots`, `cover_image_url`
- `jobs_provider.dart` → writes `payout_per_creator`, `slots`, `cover_image`

**One of these will fail at runtime on INSERT.** The fix depends entirely on which column names exist in the live DB:

- If live DB has **`payout_per_creator`** (JOBS_VIA_CAMPAIGNS names): `create_campaign_screen.dart` insert will fail. Fix: update that screen to match.
- If live DB has **`per_creator_payout`** (schema.sql names): `jobs_provider.dart` inserts will fail. Fix: update that provider to match.
- If live DB has **both**: both work, no action needed.

**Do NOT rename columns** in the live DB — that is a destructive migration. Fix the Flutter code instead once confirmed.

---

## Security Fixes Summary (from Batch 1–3 Audits)

| Fix | File | Severity | Description |
|-----|------|----------|-------------|
| Notifications INSERT `WITH CHECK (TRUE)` → user-scoped | `01_RLS_FIXES.sql` | CRITICAL | Any auth user could spam any inbox |
| Applications UPDATE missing `WITH CHECK` | `01_RLS_FIXES.sql` | HIGH | Creators could write admin-only columns |
| Admin user-update policy used JWT claim (always false) | `01_RLS_FIXES.sql` | HIGH | Admin user management silently blocked |
| Products/campaigns missing DELETE policy | `01_RLS_FIXES.sql` | HIGH | Admin delete buttons always failed |
| Withdrawal approval using `'approved'` status | Flutter only (Batch 1) | CRITICAL | Fixed in admin_provider.dart — status now `'completed'` |
| creditWallet/debitWallet race condition | Flutter only (Batch 1) | HIGH | Fixed to use atomic RPCs |
| is_admin() not case-insensitive / uuid-cast issue | `01_RLS_FIXES.sql` | HIGH | New version handles both issues |

---

## What is NOT in this folder

- `schema.sql` — the base schema; it must have been applied already
- Rollback scripts — see `supabase/rollback_*.sql` if needed
- Monitoring setup — see `supabase/monitoring/`
- Diagnostic queries — see `supabase/DIAGNOSTIC_check_everything.sql`

---

## Old SQL Files — Status

The following files in `supabase/` are **superseded** by this package but have NOT been deleted (they may contain historical context):

| Old file | Superseded by | Status |
|----------|--------------|--------|
| `fix_admin_rls.sql` | `01_RLS_FIXES.sql` | Superseded |
| `PERMANENT_FIX_run_this.sql` | `01_RLS_FIXES.sql` | Superseded |
| `fix_is_admin_case_insensitive.sql` | `01_RLS_FIXES.sql` | Superseded |
| `fix_recursion.sql` | `01_RLS_FIXES.sql` (users UPDATE policy) | Superseded |
| `wallet_balance_rpc.sql` | `02_WALLET_AND_RPC_FIXES.sql` | Superseded |
| `migrations/add_wallet_function_aliases.sql` | `02_WALLET_AND_RPC_FIXES.sql` | Superseded |
| `add_campaign_columns.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` | Superseded |
| `CAMPAIGN_JOB_EXTRA_FIELDS.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` | Superseded |
| `add_application_fields.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` | Superseded |
| `JOBS_VIA_CAMPAIGNS.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` | Superseded (partial) |
| `JOBS_USE_PAYOUT_MODEL.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` | Superseded |
| `add_campaign_delete_rls.sql` | `01_RLS_FIXES.sql` | Superseded |
| `fix_user_creation.sql` | `04_AUTH_USER_SETUP.sql` | Superseded |
| `banners_migration.sql` | `05_ADDITIONAL_TABLES.sql` | Superseded |
| `add_follows_table.sql` | `05_ADDITIONAL_TABLES.sql` | Superseded |
| `add_subscription_payments.sql` | `05_ADDITIONAL_TABLES.sql` | Superseded |
| `fix_subscription_plans_schema.sql` | `05_ADDITIONAL_TABLES.sql` | Superseded |
| `add_product_type.sql` | `03_CAMPAIGN_JOB_SCHEMA_FIXES.sql` | Superseded |
| `migrations/add_messages_soft_state.sql` | `06_MESSAGES_SOFT_STATE.sql` | Superseded |

The following files remain **authoritative** and are NOT superseded:
- `schema.sql` — base schema, must be run before this package
- `seed_subscription_plans.sql` — seeds default subscription tiers
- `POST_JOB_FIX.sql` — relaxes legacy campaign constraints for job inserts
- `FIX_PGRST205_permanent.sql` — PostgREST schema cache reload fix
- `migrations/integrate_subscription_payments.sql` — subscription upgrade migration

---

## Known Items Requiring Live DB Verification

Run `99_VERIFICATION_QUERIES.sql` to verify these:

1. **Campaign column names** — payout_per_creator vs per_creator_payout (CRITICAL)
2. **is_admin() deployed** — verify function exists with correct signature
3. **Notifications INSERT policy** — verify the old `WITH CHECK (TRUE)` is replaced
4. **Applications UPDATE WITH CHECK** — verify the new constraint is present
5. **Wallet RPCs** — verify credit_wallet and debit_wallet exist
6. **Withdrawals CHECK constraint** — verify 'completed' is allowed (not 'approved')
