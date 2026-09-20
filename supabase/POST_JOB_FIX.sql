-- ============================================================================
-- POST_JOB_FIX.sql
-- Permanent fix for: "Something went wrong. Please try again." on the
-- Post a Job screen (INSERT into public.campaigns for payout_model='job'
-- silently rejected by lingering legacy constraints).
-- ============================================================================
--
-- HOW TO USE THIS FILE
-- --------------------
-- 1. Open the Supabase Dashboard, then open the SQL Editor.
-- 2. Copy the WHOLE file and click Run once. It is idempotent and safe to run
--    as many times as you like — every statement guards itself so a re-run
--    never errors.
-- 3. Wait about 10 seconds so PostgREST can reload its schema cache.
-- 4. In the Flutter app, open Post a Job, fill the form and tap "Post Job".
--    The insert should now succeed.
--
-- WHY IS THIS NEEDED?
-- -------------------
-- Jobs are stored as rows in the legacy public.campaigns table, tagged
-- payout_model = 'job'. That table accumulated many quirks over time:
--   * several NOT-NULL columns with NO default (a bare INSERT that omits them
--     is rejected — e.g. legacy camelCase mirror columns like createdAt),
--   * one or more CHECK constraints on payout_model / payoutModel / platform
--     that can reject the value 'job' or NULL,
--   * a status CHECK that may not permit the 'active'/'closed' values the app
--     uses.
-- The Flutter createJob() insert is intentionally minimal (only the columns it
-- is confident about). This script relaxes everything else so that minimal
-- insert always succeeds, WITHOUT dropping the table or touching existing rows.
--
-- WHAT IT PROTECTS
-- ----------------
-- It never relaxes the columns the app always supplies and that must stay
-- required: id, title, description, brand_id, status.
-- ============================================================================


-- ============================================================================
-- SECTION A - DROP NOT NULL on every non-essential NOT-NULL-without-default
--             column of public.campaigns.
-- ----------------------------------------------------------------------------
-- Loops information_schema.columns and, for every column on public.campaigns
-- that is NOT NULL and has NO default (so a minimal INSERT that omits it would
-- fail), drops the NOT NULL — EXCEPT the protected set the app always sends.
-- Wrapped in a DO block with EXECUTE format(%I) so column names are quoted
-- safely (the table has quoted camelCase columns). Fully idempotent: once a
-- column is nullable it no longer matches the WHERE clause on the next run.
-- ============================================================================
DO $$
DECLARE
    col text;
BEGIN
    FOR col IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'campaigns'
          AND is_nullable = 'NO'
          AND column_default IS NULL
          AND column_name NOT IN ('id', 'title', 'description', 'brand_id', 'status')
    LOOP
        BEGIN
            EXECUTE format(
                'ALTER TABLE public.campaigns ALTER COLUMN %I DROP NOT NULL',
                col
            );
            RAISE NOTICE 'Dropped NOT NULL on campaigns.%', col;
        EXCEPTION WHEN others THEN
            -- Never let a single column abort the whole run.
            RAISE NOTICE 'Skipped campaigns.% (% )', col, SQLERRM;
        END;
    END LOOP;
END $$;


-- ============================================================================
-- SECTION B - DROP any CHECK constraint that references payout_model /
--             payoutModel / platform.
-- ----------------------------------------------------------------------------
-- Any of these CHECK constraints can reject payout_model = 'job' (or a NULL
-- platform). We loop pg_constraint (contype = 'c') joined to pg_class for the
-- campaigns table, inspect each definition via pg_get_constraintdef, and DROP
-- the constraint when it mentions one of those column names. DROP CONSTRAINT
-- IF EXISTS + exception handling keeps re-runs error-free.
-- ============================================================================
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT c.conname AS name, pg_get_constraintdef(c.oid) AS def
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE t.relname = 'campaigns'
          AND n.nspname = 'public'
          AND c.contype = 'c'
    LOOP
        IF r.def ~* 'payout_model'
           OR r.def ~* 'payoutModel'
           OR r.def ~* 'platform' THEN
            BEGIN
                EXECUTE format(
                    'ALTER TABLE public.campaigns DROP CONSTRAINT IF EXISTS %I',
                    r.name
                );
                RAISE NOTICE 'Dropped CHECK constraint % (%).', r.name, r.def;
            EXCEPTION WHEN others THEN
                RAISE NOTICE 'Skipped constraint % (% )', r.name, SQLERRM;
            END;
        END IF;
    END LOOP;
END $$;


-- ============================================================================
-- SECTION C - Ensure the status CHECK allows at least 'active' and 'closed'.
-- ----------------------------------------------------------------------------
-- Drops any CHECK constraint that references the status column but NOT any of
-- the protected/other columns handled above (so we only touch a status-only
-- check), then recreates a permissive check that allows the values the app
-- writes. If you would rather leave status completely unconstrained, delete
-- the ADD CONSTRAINT statement below — dropping alone is enough.
-- ============================================================================
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT c.conname AS name, pg_get_constraintdef(c.oid) AS def
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE t.relname = 'campaigns'
          AND n.nspname = 'public'
          AND c.contype = 'c'
    LOOP
        -- A "status-only" check references status but none of the other
        -- columns that Section B already handled.
        IF r.def ~* 'status'
           AND r.def !~* 'payout_model'
           AND r.def !~* 'payoutModel'
           AND r.def !~* 'platform' THEN
            BEGIN
                EXECUTE format(
                    'ALTER TABLE public.campaigns DROP CONSTRAINT IF EXISTS %I',
                    r.name
                );
                RAISE NOTICE 'Dropped status CHECK constraint % (%).', r.name, r.def;
            EXCEPTION WHEN others THEN
                RAISE NOTICE 'Skipped status constraint % (% )', r.name, SQLERRM;
            END;
        END IF;
    END LOOP;

    -- Recreate a permissive status check (idempotent via DROP IF EXISTS above
    -- for our own name, and a guarded ADD here). Allows the app's values plus
    -- a couple of common legacy ones. NULL is allowed too (status stays
    -- required only via the app-supplied value, not this check).
    BEGIN
        ALTER TABLE public.campaigns
            DROP CONSTRAINT IF EXISTS campaigns_status_allowed_chk;
        ALTER TABLE public.campaigns
            ADD CONSTRAINT campaigns_status_allowed_chk
            CHECK (status IS NULL OR status IN ('active', 'closed', 'draft', 'paused', 'completed'));
        RAISE NOTICE 'Ensured campaigns_status_allowed_chk allows active/closed.';
    EXCEPTION WHEN others THEN
        RAISE NOTICE 'Could not (re)create status check: %', SQLERRM;
    END;
END $$;


-- ============================================================================
-- SECTION D - RELOAD POSTGREST
-- ----------------------------------------------------------------------------
-- Tell PostgREST to reload its schema cache and configuration so the relaxed
-- constraints take effect immediately.
-- ============================================================================
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';


-- ============================================================================
-- SECTION E - VERIFICATION  (optional; run manually after the fix)
-- ----------------------------------------------------------------------------
-- E1. Confirm no NOT-NULL-without-default columns remain outside the protected
--     set (should return zero rows):
--     SELECT column_name FROM information_schema.columns
--     WHERE table_schema='public' AND table_name='campaigns'
--       AND is_nullable='NO' AND column_default IS NULL
--       AND column_name NOT IN ('id','title','description','brand_id','status');
--
-- E2. Confirm no CHECK constraint references payout_model/payoutModel/platform:
--     SELECT conname, pg_get_constraintdef(c.oid)
--     FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
--     WHERE t.relname='campaigns' AND c.contype='c';
--
-- E3. Try a minimal job insert from the app's Post a Job screen — it should
--     now succeed and appear on the Jobs tab.
-- ============================================================================
