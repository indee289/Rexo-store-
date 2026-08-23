-- ============================================================================
-- MIGRATION: subscription_payments
--
-- NEEDS-USER-ACTION: run this file in the Supabase SQL editor (or via
--   `supabase db push` / psql) against your project. It creates the table that
--   backs the new manual subscription-payment flow.
--
-- WHY: Tapping "Subscribe" used to instantly insert an ACTIVE row into
--   user_subscriptions with no payment. This mirrors the wallet DEPOSIT
--   pattern instead: the user submits a payment (amount + UPI/bank ref +
--   proof image) which lands here as status='pending'. An admin reviews the
--   proof and approves it, at which point a row is inserted into
--   user_subscriptions (status='active'). Rejection just marks it 'rejected'.
--
-- NOTE ON plan_id TYPE: subscription_plans.id and user_subscriptions.plan_id
--   are UUID (see schema.sql). We therefore use UUID here too so the value can
--   be forwarded verbatim into user_subscriptions on approval. We intentionally
--   do NOT add a foreign key to subscription_plans so that a pending payment
--   row is never blocked if a plan is edited/removed; the approval step (which
--   inserts into user_subscriptions) still enforces the real FK.
--
-- Idempotent: safe to run multiple times.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.subscription_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL,
    plan_name TEXT,                       -- denormalized for easy admin display
    amount DECIMAL(12, 2) NOT NULL,
    duration_days INTEGER NOT NULL DEFAULT 30,
    payment_method TEXT,
    transaction_ref TEXT,
    proof_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_subscription_payments_user_id
    ON public.subscription_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_payments_status
    ON public.subscription_payments(status);
CREATE INDEX IF NOT EXISTS idx_subscription_payments_created_at
    ON public.subscription_payments(created_at);

ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- RLS POLICIES
--   Users: can create their own payment + read their own payments.
--   Admins: can read all + update (approve/reject) all.
--   Reuses public.is_admin() from supabase/fix_admin_rls.sql (SECURITY DEFINER
--   helper that reads users.role for the current auth.uid()).
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can create own subscription payments"
    ON public.subscription_payments;
CREATE POLICY "Users can create own subscription payments"
    ON public.subscription_payments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can read own subscription payments"
    ON public.subscription_payments;
CREATE POLICY "Users can read own subscription payments"
    ON public.subscription_payments FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can read all subscription payments"
    ON public.subscription_payments;
CREATE POLICY "Admins can read all subscription payments"
    ON public.subscription_payments FOR SELECT
    USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can update subscription payments"
    ON public.subscription_payments;
CREATE POLICY "Admins can update subscription payments"
    ON public.subscription_payments FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ============================================================================
-- VERIFICATION (run AFTER applying):
--   SELECT policyname, cmd FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'subscription_payments'
--   ORDER BY policyname;
-- ============================================================================
