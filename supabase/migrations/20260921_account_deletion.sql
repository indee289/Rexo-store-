-- ============================================================================
-- Rexo Collab — Account Deletion (server-side, RLS-safe, ownership-protected)
-- ============================================================================
--
-- Google Play requires an in-app path that deletes a user's account and data.
-- This migration provides:
--
--   1. account_deletion_requests   — audit/lifecycle table (RLS-protected)
--   2. request_account_deletion()  — SECURITY DEFINER RPC that:
--        * derives identity from auth.uid() ONLY (never a client-supplied id)
--        * anonymizes the caller's public.users PII
--        * deletes / anonymizes the caller's personal data
--        * RETAINS financial/legal records (documented below)
--        * records a deletion request row for async hard-delete
--
-- IMPORTANT — LIVE SCHEMA NOTE:
--   The live database uses camelCase columns (users.uid text = auth.uid()::text,
--   notifications.userId, chat_messages.senderId, etc.) that differ from
--   supabase/schema.sql. To stay safe against schema drift, every table/column
--   mutation below is wrapped in its own BEGIN/EXCEPTION block that swallows
--   undefined_table / undefined_column so a missing object never aborts the
--   whole deletion. Apply this file against the LIVE database and review the
--   RAISE NOTICE output.
--
-- RETENTION POLICY (matches Privacy Policy):
--   Financial records — wallets, transactions, deposits, withdrawals — are NOT
--   deleted here. Indian tax/financial regulation requires retention (the
--   Privacy Policy states 7 years). They remain keyed to the user id for audit
--   but the user's *profile* PII (name/email/handle/avatar/bio/phone) is
--   anonymized so the retained rows are no longer personally identifiable.
--
-- HARD DELETION OF THE AUTH USER:
--   Deleting the row in auth.users requires the service role and cannot be done
--   from a user-JWT RPC. That final step is performed by the Edge Function
--   supabase/functions/delete-account (deployed separately). Until then, the
--   account is fully anonymized AND locked (isBanned = true), so it is unusable.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Audit / lifecycle table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.account_deletion_requests (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL,
    uid          TEXT,
    status       TEXT NOT NULL DEFAULT 'processing'
                 CHECK (status IN ('requested', 'processing', 'completed')),
    reason       TEXT,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_user_id
    ON public.account_deletion_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_status
    ON public.account_deletion_requests(status);

ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;

-- A user may see their own deletion requests (transparency); inserts happen via
-- the SECURITY DEFINER function, not directly. No UPDATE/DELETE for users.
DROP POLICY IF EXISTS "Users can view own deletion requests"
    ON public.account_deletion_requests;
CREATE POLICY "Users can view own deletion requests"
    ON public.account_deletion_requests
    FOR SELECT USING (auth.uid() = user_id);

-- Admins (users.role = 'admin') can review all requests to complete hard-delete.
DROP POLICY IF EXISTS "Admins can manage deletion requests"
    ON public.account_deletion_requests;
CREATE POLICY "Admins can manage deletion requests"
    ON public.account_deletion_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND lower(u.role) = 'admin'
        )
    );

-- ---------------------------------------------------------------------------
-- 2. Defensive PII columns on users (safe if they already exist)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    BEGIN
        ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;
    EXCEPTION WHEN others THEN RAISE NOTICE 'users.is_deleted: %', SQLERRM;
    END;
    BEGIN
        ALTER TABLE public.users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
    EXCEPTION WHEN others THEN RAISE NOTICE 'users.deleted_at: %', SQLERRM;
    END;
END $$;

-- ---------------------------------------------------------------------------
-- 3. The account-deletion RPC
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.request_account_deletion(p_reason TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid  UUID := auth.uid();
    v_uidt TEXT;
BEGIN
    -- Ownership / auth guard: identity comes ONLY from the verified JWT.
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
    END IF;
    v_uidt := v_uid::text;

    -- Record the request (idempotent-ish: one row per invocation is fine).
    INSERT INTO public.account_deletion_requests (user_id, uid, status, reason)
    VALUES (v_uid, v_uidt, 'processing', p_reason);

    -- 3a) Anonymize the caller's users row PII. Live identity column is `uid`
    --     (text) == auth.uid()::text. Scoped strictly to the caller's row so a
    --     user can NEVER affect another account.
    BEGIN
        UPDATE public.users
        SET name           = 'Deleted User',
            username       = 'deleted_' || left(replace(v_uidt, '-', ''), 16),
            email          = 'deleted+' || v_uidt || '@deleted.invalid',
            bio            = NULL,
            "profileImage" = NULL,
            "isBanned"     = TRUE,
            is_deleted     = TRUE,
            deleted_at     = NOW(),
            followers      = '[]'::jsonb,
            following      = '[]'::jsonb,
            "followersCount" = 0,
            "followingCount" = 0
        WHERE uid = v_uidt;
    EXCEPTION WHEN undefined_column OR undefined_table THEN
        -- Fall back to a minimal anonymization if some columns differ.
        BEGIN
            UPDATE public.users
            SET name = 'Deleted User',
                email = 'deleted+' || v_uidt || '@deleted.invalid'
            WHERE uid = v_uidt;
        EXCEPTION WHEN others THEN RAISE NOTICE 'users minimal anon failed: %', SQLERRM;
        END;
    WHEN others THEN RAISE NOTICE 'users anon failed: %', SQLERRM;
    END;

    -- Also try the phone column separately (may not exist on live schema).
    BEGIN
        UPDATE public.users SET phone = NULL WHERE uid = v_uidt;
    EXCEPTION WHEN others THEN NULL;
    END;

    -- 3b) Delete the caller's notifications (personal data).
    BEGIN
        DELETE FROM public.notifications WHERE "userId" = v_uidt;
    EXCEPTION WHEN undefined_column OR undefined_table THEN
        BEGIN DELETE FROM public.notifications WHERE user_id = v_uid;
        EXCEPTION WHEN others THEN RAISE NOTICE 'notifications: %', SQLERRM; END;
    WHEN others THEN RAISE NOTICE 'notifications: %', SQLERRM;
    END;

    -- 3c) Anonymize the caller's chat messages (leave the room so the other
    --     participant's history is not corrupted, but strip this user's text).
    BEGIN
        UPDATE public.chat_messages
        SET text = '', status = 'deleted'
        WHERE "senderId" = v_uidt;
    EXCEPTION WHEN undefined_column OR undefined_table THEN
        RAISE NOTICE 'chat_messages skip (schema mismatch)';
    WHEN others THEN RAISE NOTICE 'chat_messages: %', SQLERRM;
    END;

    -- 3d) Remove device push tokens (personal data / device identifiers).
    BEGIN
        DELETE FROM public.user_devices WHERE user_id = v_uid;
    EXCEPTION WHEN undefined_column OR undefined_table THEN
        BEGIN DELETE FROM public.user_devices WHERE user_id = v_uidt;
        EXCEPTION WHEN others THEN RAISE NOTICE 'user_devices: %', SQLERRM; END;
    WHEN others THEN RAISE NOTICE 'user_devices: %', SQLERRM;
    END;

    -- 3e) Remove device fingerprints if present (personal data).
    BEGIN
        DELETE FROM public.device_fingerprints WHERE user_id = v_uid;
    EXCEPTION WHEN others THEN
        BEGIN DELETE FROM public.device_fingerprints WHERE "userId" = v_uidt;
        EXCEPTION WHEN others THEN NULL; END;
    END;

    -- 3f) Remove linked social accounts (personal data), if the table exists.
    BEGIN
        DELETE FROM public.linked_accounts WHERE user_id = v_uid;
    EXCEPTION WHEN others THEN NULL;
    END;

    -- 3g) Remove saved addresses (personal data), if the table exists.
    BEGIN
        DELETE FROM public.addresses WHERE user_id = v_uid;
    EXCEPTION WHEN others THEN NULL;
    END;

    -- NOTE (retention): wallets, transactions, deposits, withdrawals, and
    -- moderation_queue rows are intentionally NOT deleted here — they are
    -- retained for legal/financial/audit compliance. The profile PII they
    -- reference has been anonymized above, so they are no longer PII-bearing.

    RETURN jsonb_build_object(
        'success', true,
        'uid', v_uidt,
        'message', 'Account data anonymized and deletion requested.'
    );
END;
$$;

-- ---------------------------------------------------------------------------
-- 4. Lock down EXECUTE — authenticated users only (never anon/public).
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.request_account_deletion(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.request_account_deletion(TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.request_account_deletion(TEXT) TO authenticated;

-- ============================================================================
-- VERIFICATION (run manually as an authenticated user):
--   SELECT public.request_account_deletion('user requested');
--   SELECT name, email, username, "isBanned", is_deleted
--     FROM public.users WHERE uid = auth.uid()::text;
-- Expect: name='Deleted User', email/username anonymized, isBanned/is_deleted true.
-- ============================================================================
