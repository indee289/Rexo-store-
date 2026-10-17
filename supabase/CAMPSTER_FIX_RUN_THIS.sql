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
-- Reload the PostgREST schema cache so the API picks up any changes.
-- ─────────────────────────────────────────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- DONE. Admin withdrawal queue, session revoke, wallet admin views, and audit
-- logs will now work. (The app code fixes ship separately in the APK.)
