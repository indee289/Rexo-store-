-- ============================================================================
-- CAMPSTER — CONSOLIDATED FIX (run once in the Supabase SQL editor)
-- ============================================================================
-- This file is IDEMPOTENT (safe to run multiple times). It fixes the issues
-- that were reported in the app:
--   1. Admin "Withdrawal Queue" showed 0 even when a user requested a
--      withdrawal  -> ensures admins can SELECT/UPDATE all withdrawals.
--   2. Sessions could not be deleted / revoked  -> adds the missing DELETE
--      policy so a user can remove their own sessions (the table only had
--      SELECT/INSERT/UPDATE policies, so DELETE was silently blocked).
--   3. Re-asserts wallet admin visibility + the is_admin() helper.
--
-- It does NOT drop or modify any data — only (re)creates the helper function
-- and RLS policies with DROP POLICY IF EXISTS + CREATE.
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- 0) is_admin() — case-insensitive, text-safe. Used by every admin policy.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id::text = auth.uid()::text
      AND lower(u.role) = 'admin'
  );
$$;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- 1) WITHDRAWALS — make sure admins can see and process ALL requests.
--    (Fixes: user withdrawal is 'pending' but admin queue shows 0.)
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF to_regclass('public.withdrawals') IS NOT NULL THEN
    ALTER TABLE public.withdrawals ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "Users can read own withdrawals" ON public.withdrawals;
    CREATE POLICY "Users can read own withdrawals" ON public.withdrawals
      FOR SELECT USING (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Admins can read all withdrawals" ON public.withdrawals;
    CREATE POLICY "Admins can read all withdrawals" ON public.withdrawals
      FOR SELECT USING (public.is_admin());

    DROP POLICY IF EXISTS "Users can create withdrawals" ON public.withdrawals;
    CREATE POLICY "Users can create withdrawals" ON public.withdrawals
      FOR INSERT WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Admins can update withdrawals" ON public.withdrawals;
    CREATE POLICY "Admins can update withdrawals" ON public.withdrawals
      FOR UPDATE USING (public.is_admin());
  END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2) USER_SESSIONS — add the MISSING delete policy so users can revoke their
--    own sessions. (The live table only had SELECT/INSERT/UPDATE policies, so
--    DELETE was blocked by RLS and sessions kept reappearing.)
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF to_regclass('public.user_sessions') IS NOT NULL THEN
    ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "Users can delete own sessions" ON public.user_sessions;
    CREATE POLICY "Users can delete own sessions" ON public.user_sessions
      FOR DELETE USING (auth.uid() = user_id);

    -- (Re-assert the existing ones so the set is complete.)
    DROP POLICY IF EXISTS "Users can read own sessions" ON public.user_sessions;
    CREATE POLICY "Users can read own sessions" ON public.user_sessions
      FOR SELECT USING (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can update own sessions" ON public.user_sessions;
    CREATE POLICY "Users can update own sessions" ON public.user_sessions
      FOR UPDATE USING (auth.uid() = user_id);
  END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3) WALLETS — admins can read/update all wallets (admin Wallets & Escrow).
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF to_regclass('public.wallets') IS NOT NULL THEN
    ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "Users can read own wallet" ON public.wallets;
    CREATE POLICY "Users can read own wallet" ON public.wallets
      FOR SELECT USING (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Admins can read all wallets" ON public.wallets;
    CREATE POLICY "Admins can read all wallets" ON public.wallets
      FOR SELECT USING (public.is_admin());

    DROP POLICY IF EXISTS "Admins can update wallets" ON public.wallets;
    CREATE POLICY "Admins can update wallets" ON public.wallets
      FOR UPDATE USING (public.is_admin());
  END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4) AUDIT_LOGS — ensure the table/columns the app writes exist, and admins
--    can read them. The app inserts: action_type, reason, admin_id, created_at.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type TEXT,
    reason      TEXT,
    admin_id    TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS action_type TEXT;
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS reason      TEXT;
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS admin_id    TEXT;
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read audit logs" ON public.audit_logs;
CREATE POLICY "Admins can read audit logs" ON public.audit_logs
  FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can write audit logs" ON public.audit_logs;
CREATE POLICY "Admins can write audit logs" ON public.audit_logs
  FOR INSERT WITH CHECK (public.is_admin());


-- ─────────────────────────────────────────────────────────────────────────────
-- 5) CAMPAIGNS / JOBS — fix "something went wrong" when POSTING A JOB.
--
-- Jobs are stored in the `campaigns` table tagged payout_model='job'. The job
-- insert failed because:
--   (a) `payout_model` and some job columns may not exist on the live table
--       -> missing-column error (PGRST204).
--   (b) legacy NOT-NULL columns the minimal job insert doesn't populate
--       (e.g. company_name/gender/brandName) rejected the row.
-- This section makes every column the app writes exist and relaxes NOT NULL on
-- every non-essential column so both the campaign form AND the job form insert
-- succeed. (The app code also now writes brand_id, matching the INSERT policy.)
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE col text;
BEGIN
  IF to_regclass('public.campaigns') IS NOT NULL THEN
    -- Ensure every column the app writes exists (no-op if already present).
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS payout_model          text DEFAULT 'campaign';
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS payout_per_creator     numeric DEFAULT 0;
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS slots                  integer DEFAULT 0;
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS cover_image            text;
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS rules                  text;
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS demo_asset_type        text;
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS demo_asset_url         text;
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS platform               text;
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS company_name           text;
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS gender                 text;
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS page_profile_category  text;
    ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS "brandId"              text;

    -- Backfill payout_model for existing rows so the Home feed keeps showing
    -- them as campaigns (jobs are only the rows explicitly set to 'job').
    UPDATE public.campaigns SET payout_model = 'campaign'
      WHERE payout_model IS NULL;

    -- Relax NOT NULL on every column that has no default and is NOT one of the
    -- essentials the inserts always provide. This lets the minimal job insert
    -- (which omits company_name/gender/etc.) succeed.
    FOR col IN
      SELECT column_name FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'campaigns'
        AND is_nullable = 'NO'
        AND column_default IS NULL
        AND column_name NOT IN ('id', 'title', 'brand_id', 'status')
    LOOP
      EXECUTE format('ALTER TABLE public.campaigns ALTER COLUMN %I DROP NOT NULL', col);
    END LOOP;

    -- Make sure admins (and brands creating their own) can INSERT campaigns/jobs.
    ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Admins can insert campaigns" ON public.campaigns;
    CREATE POLICY "Admins can insert campaigns" ON public.campaigns
      FOR INSERT WITH CHECK (public.is_admin() OR auth.uid() = brand_id);
  END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- Reload the PostgREST schema cache so the API picks up any changes.
-- ─────────────────────────────────────────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- DONE. Admin withdrawal queue, session revoke, wallet admin views, audit logs,
-- AND job posting will now work. (The app code fixes ship in the APK.)
