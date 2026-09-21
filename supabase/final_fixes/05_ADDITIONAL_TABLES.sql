-- ============================================================================
-- 05_ADDITIONAL_TABLES.sql
-- Rexo — Additional Tables and Their RLS
--
-- PURPOSE
--   Creates tables that are NOT part of the base schema.sql but are required
--   by Flutter features: follows, banners, subscription_payments.
--   Also adds the subscription_plans 'interval' column for seed compatibility.
--
-- IDEMPOTENCY
--   CREATE TABLE IF NOT EXISTS, ADD COLUMN IF NOT EXISTS, DROP POLICY IF EXISTS.
--   Safe to run multiple times.
--
-- DEPENDENCIES
--   01_RLS_FIXES.sql (defines is_admin()).
--   schema.sql (users, campaigns, subscription_plans must exist).
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- A. follows — creator follow/unfollow
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.follows (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_follower_id  ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows(following_id);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read all follows"  ON public.follows;
DROP POLICY IF EXISTS "Users can follow others"     ON public.follows;
DROP POLICY IF EXISTS "Users can unfollow"          ON public.follows;

CREATE POLICY "Users can read all follows" ON public.follows
    FOR SELECT USING (true);

CREATE POLICY "Users can follow others" ON public.follows
    FOR INSERT WITH CHECK (follower_id = auth.uid());

CREATE POLICY "Users can unfollow" ON public.follows
    FOR DELETE USING (follower_id = auth.uid());


-- ─────────────────────────────────────────────────────────────────────────────
-- B. banners — home carousel (stored in platform_settings JSON as workaround
--    for PostgREST PGRST205; this table is kept for reference but Flutter
--    currently reads from platform_settings instead)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.banners (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title            text,
    image_url        text NOT NULL,
    link_type        text CHECK (link_type IN ('none', 'campaign', 'page')),
    link_campaign_id uuid REFERENCES public.campaigns(id) ON DELETE SET NULL,
    link_page        text,
    is_visible       boolean NOT NULL DEFAULT true,
    sort_order       integer NOT NULL DEFAULT 0,
    created_by       uuid REFERENCES public.users(id),
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS banners_visible_idx ON public.banners(is_visible);
CREATE INDEX IF NOT EXISTS banners_sort_idx    ON public.banners(sort_order);

ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Everyone can view visible banners" ON public.banners;
DROP POLICY IF EXISTS "Admins manage all banners"         ON public.banners;

CREATE POLICY "Everyone can view visible banners" ON public.banners
    FOR SELECT USING (is_visible = true OR public.is_admin());

CREATE POLICY "Admins manage all banners" ON public.banners
    FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE OR REPLACE FUNCTION public.update_banners_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS set_banners_updated_at ON public.banners;
CREATE TRIGGER set_banners_updated_at
    BEFORE UPDATE ON public.banners
    FOR EACH ROW EXECUTE FUNCTION public.update_banners_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- C. subscription_payments — manual payment proof flow
--    (user submits payment proof; admin approves → activates subscription)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.subscription_payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    plan_id         UUID NOT NULL,              -- no FK: plan may be edited/removed
    plan_name       TEXT,                       -- denormalized for admin display
    amount          DECIMAL(12, 2) NOT NULL,
    duration_days   INTEGER NOT NULL DEFAULT 30,
    payment_method  TEXT,
    transaction_ref TEXT,
    proof_url       TEXT,
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at    TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_subscription_payments_user_id
    ON public.subscription_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_payments_status
    ON public.subscription_payments(status);
CREATE INDEX IF NOT EXISTS idx_subscription_payments_created_at
    ON public.subscription_payments(created_at);

ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can create own subscription payments"  ON public.subscription_payments;
DROP POLICY IF EXISTS "Users can read own subscription payments"    ON public.subscription_payments;
DROP POLICY IF EXISTS "Admins can read all subscription payments"   ON public.subscription_payments;
DROP POLICY IF EXISTS "Admins can update subscription payments"     ON public.subscription_payments;

CREATE POLICY "Users can create own subscription payments"
    ON public.subscription_payments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read own subscription payments"
    ON public.subscription_payments FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can read all subscription payments"
    ON public.subscription_payments FOR SELECT
    USING (public.is_admin());

CREATE POLICY "Admins can update subscription payments"
    ON public.subscription_payments FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());


-- ─────────────────────────────────────────────────────────────────────────────
-- D. subscription_plans — add 'interval' column for seed compatibility
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.subscription_plans
    ADD COLUMN IF NOT EXISTS interval TEXT DEFAULT 'month';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'subscription_plans_interval_check'
    ) THEN
        ALTER TABLE public.subscription_plans
            ADD CONSTRAINT subscription_plans_interval_check
            CHECK (interval IN ('month', 'year', 'week', 'day'));
    END IF;
END$$;

UPDATE public.subscription_plans
SET interval = 'month'
WHERE interval IS NULL;


-- ─────────────────────────────────────────────────────────────────────────────
-- E. Reload PostgREST
-- ─────────────────────────────────────────────────────────────────────────────

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
