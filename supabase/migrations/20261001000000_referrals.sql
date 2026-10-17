-- ============================================================================
-- REFERRAL PROGRAM
--
-- Each user's referral code is their existing `username` (unique on the live
-- users table). A new user can redeem ONE referral code (the person who invited
-- them). Both the referrer and the referred user earn reward points.
--
-- Reward crediting and self/duplicate checks happen inside a SECURITY DEFINER
-- RPC (identity derived from auth.uid() only — never a client-supplied id), so
-- RLS is respected and the reward logic cannot be gamed from the client.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.referrals (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_uid  text NOT NULL,
    referred_uid  text NOT NULL,
    reward_points integer NOT NULL DEFAULT 100,
    status        text NOT NULL DEFAULT 'completed',
    created_at    timestamptz NOT NULL DEFAULT now(),
    -- A user can be referred at most once, and never by themselves.
    CONSTRAINT referrals_referred_unique UNIQUE (referred_uid),
    CONSTRAINT referrals_no_self CHECK (referrer_uid <> referred_uid)
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_uid);

ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

-- A user can read referral rows that involve them (as referrer or referred).
DROP POLICY IF EXISTS "Users read own referrals" ON public.referrals;
CREATE POLICY "Users read own referrals"
    ON public.referrals FOR SELECT
    USING (referrer_uid = auth.uid()::text OR referred_uid = auth.uid()::text);

-- Admins can review all referrals.
DROP POLICY IF EXISTS "Admins manage all referrals" ON public.referrals;
CREATE POLICY "Admins manage all referrals"
    ON public.referrals FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users u
                WHERE u.id = auth.uid() AND lower(u.role) = 'admin')
    );
-- NOTE: no INSERT policy for end users — inserts happen only via the
-- SECURITY DEFINER function below.

-- ---------------------------------------------------------------------------
-- redeem_referral(code): called ONCE by a newly-signed-up user.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.redeem_referral(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_referred_id   uuid := auth.uid();
    v_referred_uid  text;
    v_referrer_id   uuid;
    v_referrer_uid  text;
    v_reward        integer := 100;
    v_code          text;
BEGIN
    IF v_referred_id IS NULL THEN
        RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
    END IF;
    v_referred_uid := v_referred_id::text;

    v_code := lower(trim(coalesce(p_code, '')));
    IF v_code = '' THEN
        RAISE EXCEPTION 'empty_code' USING ERRCODE = '22023';
    END IF;

    -- Already redeemed a referral?
    IF EXISTS (SELECT 1 FROM public.referrals WHERE referred_uid = v_referred_uid) THEN
        RAISE EXCEPTION 'already_referred' USING ERRCODE = '23505';
    END IF;

    -- Resolve the referrer by their username (= their referral code).
    SELECT id, uid INTO v_referrer_id, v_referrer_uid
    FROM public.users
    WHERE lower(username) = v_code
    LIMIT 1;

    IF v_referrer_id IS NULL THEN
        RAISE EXCEPTION 'invalid_code' USING ERRCODE = 'P0002';
    END IF;
    IF v_referrer_uid = v_referred_uid THEN
        RAISE EXCEPTION 'self_referral' USING ERRCODE = '22023';
    END IF;

    -- Record the referral.
    INSERT INTO public.referrals (referrer_uid, referred_uid, reward_points, status)
    VALUES (v_referrer_uid, v_referred_uid, v_reward, 'completed');

    -- Credit reward points to BOTH users (safe upsert without relying on a
    -- unique constraint on reward_points.user_id).
    PERFORM public._credit_reward_points(v_referrer_id, v_reward);
    PERFORM public._credit_reward_points(v_referred_id, v_reward);

    RETURN jsonb_build_object('ok', true, 'reward_points', v_reward);
END;
$$;

-- Internal helper: increment a user's reward_points, creating the row if absent.
CREATE OR REPLACE FUNCTION public._credit_reward_points(p_user_id uuid, p_points integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF to_regclass('public.reward_points') IS NULL THEN
        RETURN;
    END IF;
    UPDATE public.reward_points
       SET points = coalesce(points, 0) + p_points,
           last_earned_at = now()
     WHERE user_id = p_user_id;
    IF NOT FOUND THEN
        INSERT INTO public.reward_points (user_id, points, last_earned_at)
        VALUES (p_user_id, p_points, now());
    END IF;
EXCEPTION WHEN others THEN
    -- Reward crediting is best-effort; never fail the whole referral on it.
    NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_referral(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.redeem_referral(text) FROM anon;
GRANT EXECUTE ON FUNCTION public.redeem_referral(text) TO authenticated;
-- The helper is only called internally by SECURITY DEFINER functions.
REVOKE ALL ON FUNCTION public._credit_reward_points(uuid, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public._credit_reward_points(uuid, integer) FROM anon;
REVOKE ALL ON FUNCTION public._credit_reward_points(uuid, integer) FROM authenticated;
