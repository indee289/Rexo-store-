-- ============================================================================
-- MIGRATION 3: Subscription Payments Table Integration
-- 
-- PART OF: Phase 1 Critical Database Fixes
-- EXECUTION ORDER: THIRD (after subscription_plans and wallet_function_aliases)
-- 
-- PURPOSE: Integrate the subscription_payments table from the separate migration
--          file into the main schema to resolve "relation does not exist" errors
--          when users attempt to submit subscription payments.
--
-- BUG CONDITION FIXED:
--   isBugCondition(input) where input.operation = 'SUBSCRIPTION_PAYMENT' 
--   AND NOT tableExists('subscription_payments')
--
-- EXPECTED BEHAVIOR: 
--   expectedBehavior(result) - successful subscription payment operations
--   including INSERT, SELECT, UPDATE operations on subscription_payments table
--
-- PRESERVATION: No impact on existing tables or operations - this only adds
--               new functionality without modifying existing schema elements
--
-- REQUIREMENTS: 2.3 (Missing subscription_payments table integration)
-- 
-- DEPENDENCIES: None - can run independently of other migrations
-- IDEMPOTENT: Safe to run multiple times (uses IF NOT EXISTS)
-- ============================================================================

-- ============================================================================
-- TABLE CREATION: subscription_payments
-- 
-- BACKGROUND: This table supports the manual subscription payment workflow
-- where users submit payment proof (amount + UPI/bank ref + proof image) which
-- lands as status='pending'. Admins review and approve/reject, then insert
-- approved payments into user_subscriptions table.
--
-- DESIGN NOTES:
-- - plan_id is UUID to match subscription_plans.id and user_subscriptions.plan_id
-- - No foreign key to subscription_plans to prevent blocking if plan is edited
-- - Approval step enforces real FK when inserting into user_subscriptions
-- - Uses same security model as other admin-managed tables (deposits/withdrawals)
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

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_subscription_payments_user_id
    ON public.subscription_payments(user_id);

CREATE INDEX IF NOT EXISTS idx_subscription_payments_status
    ON public.subscription_payments(status);

CREATE INDEX IF NOT EXISTS idx_subscription_payments_created_at
    ON public.subscription_payments(created_at);

-- ============================================================================
-- ROW LEVEL SECURITY SETUP
-- ============================================================================

ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES
-- 
-- SECURITY MODEL:
--   Users: can create their own payments + read their own payments
--   Admins: can read all + update (approve/reject) all
--   
-- DEPENDENCIES: Reuses public.is_admin() function from fix_admin_rls.sql
--               (SECURITY DEFINER helper that reads users.role for auth.uid())
-- ============================================================================

-- User Policies: Allow users to manage their own subscription payments
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

-- Admin Policies: Allow admins to review and manage all subscription payments
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
-- MIGRATION VALIDATION
-- 
-- After applying this migration, verify the following:
-- 1. Table exists: \d public.subscription_payments
-- 2. Indexes created: \di public.idx_subscription_payments*
-- 3. RLS enabled: SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'subscription_payments';
-- 4. Policies exist: SELECT policyname, cmd FROM pg_policies WHERE tablename = 'subscription_payments';
-- 5. Test INSERT: Should succeed for authenticated users
-- 6. Test admin SELECT: Should return all records for admin users
-- ============================================================================

-- ============================================================================
-- ROLLBACK INSTRUCTIONS
-- 
-- If this migration needs to be rolled back, execute these commands:
-- 
-- -- Drop all policies first
-- DROP POLICY IF EXISTS "Users can create own subscription payments" ON public.subscription_payments;
-- DROP POLICY IF EXISTS "Users can read own subscription payments" ON public.subscription_payments;
-- DROP POLICY IF EXISTS "Admins can read all subscription payments" ON public.subscription_payments;
-- DROP POLICY IF EXISTS "Admins can update subscription payments" ON public.subscription_payments;
-- 
-- -- Drop indexes
-- DROP INDEX IF EXISTS idx_subscription_payments_user_id;
-- DROP INDEX IF EXISTS idx_subscription_payments_status;
-- DROP INDEX IF EXISTS idx_subscription_payments_created_at;
-- 
-- -- Drop table
-- DROP TABLE IF EXISTS public.subscription_payments;
-- 
-- IMPACT OF ROLLBACK:
-- - Subscription payment functionality will be disabled
-- - Users will not be able to submit subscription payments
-- - Admin cannot review/approve subscription payments
-- - Any existing subscription payment data will be lost
-- ============================================================================

-- ============================================================================
-- DEPLOYMENT NOTES
-- 
-- EXECUTION ORDER: This is Migration 3 of 3 in the critical fixes sequence
-- - Migration 1: fix_subscription_plans_schema.sql (FIRST)
-- - Migration 2: add_wallet_function_aliases.sql (SECOND) 
-- - Migration 3: integrate_subscription_payments.sql (THIRD - this file)
--
-- INDEPENDENCE: This migration can run independently - no dependencies on 1 or 2
-- 
-- PRODUCTION CONSIDERATIONS:
-- - Can be applied during normal operations (no downtime required)
-- - Uses IF NOT EXISTS for idempotent deployment
-- - No impact on existing functionality
-- - Only adds new subscription payment capability
--
-- POST-DEPLOYMENT TESTING:
-- - Test user subscription payment submission
-- - Test admin subscription payment approval workflow
-- - Verify RLS policies prevent unauthorized access
-- - Check integration with user_subscriptions table workflow
-- ============================================================================

-- ============================================================================
-- INTEGRATION WITH EXISTING WORKFLOW
--
-- This table integrates with the existing subscription system:
-- 
-- 1. USER SUBMITS PAYMENT:
--    - Flutter app inserts record with status='pending'
--    - User provides: amount, payment_method, transaction_ref, proof_url
--    
-- 2. ADMIN REVIEWS:
--    - Admin dashboard shows pending payments
--    - Admin can add admin_notes and update status
--    
-- 3. APPROVAL WORKFLOW:
--    - status='approved' → insert record into user_subscriptions table
--    - status='rejected' → payment remains in subscription_payments with admin_notes
--    
-- 4. USER SUBSCRIPTION ACTIVATION:
--    - Approved payments create active subscriptions in user_subscriptions
--    - Original payment record preserved for audit trail
-- ============================================================================

COMMENT ON TABLE public.subscription_payments IS 
'Manual subscription payment submissions requiring admin approval. Users submit payment proof, admins review and approve/reject. Approved payments create entries in user_subscriptions table.';

COMMENT ON COLUMN public.subscription_payments.plan_id IS 
'UUID reference to subscription_plans.id. Intentionally no FK constraint to prevent blocking if plan is modified during pending review.';

COMMENT ON COLUMN public.subscription_payments.plan_name IS 
'Denormalized plan name for easy admin display without joins. Populated at submission time.';

COMMENT ON COLUMN public.subscription_payments.amount IS 
'Payment amount in INR. Should match the subscription plan amount but allows for promotional pricing.';

COMMENT ON COLUMN public.subscription_payments.status IS 
'Payment review status: pending (default), approved (creates subscription), rejected (with admin_notes).';

COMMENT ON COLUMN public.subscription_payments.admin_notes IS 
'Admin comments for approval/rejection decisions. Required for rejected payments.';

COMMENT ON COLUMN public.subscription_payments.processed_at IS 
'Timestamp when admin approved or rejected the payment. NULL while status=pending.';