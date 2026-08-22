-- ============================================================
-- DROP ALL TABLES + TRIGGERS + FUNCTIONS + STORAGE POLICIES
-- Run this FIRST, then run schema.sql fresh
-- ============================================================

-- Drop all storage policies
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
    END LOOP;
END $$;

-- Drop all public table policies
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
    END LOOP;
END $$;

-- Drop triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_user_created_create_wallet ON public.users;
DROP TRIGGER IF EXISTS on_withdrawal_check_balance ON public.withdrawals;
DROP TRIGGER IF EXISTS on_order_item_check_stock ON public.order_items;

-- Drop functions
DROP FUNCTION IF EXISTS public.handle_new_auth_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_wallet() CASCADE;
DROP FUNCTION IF EXISTS public.check_withdrawal_balance() CASCADE;
DROP FUNCTION IF EXISTS public.check_and_decrement_stock() CASCADE;

-- Drop all tables
DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.security_audit_logs CASCADE;
DROP TABLE IF EXISTS public.security_logs CASCADE;
DROP TABLE IF EXISTS public.ai_moderation_logs CASCADE;
DROP TABLE IF EXISTS public.moderation_queue CASCADE;
DROP TABLE IF EXISTS public.device_fingerprints CASCADE;
DROP TABLE IF EXISTS public.user_warnings CASCADE;
DROP TABLE IF EXISTS public.user_suspensions CASCADE;
DROP TABLE IF EXISTS public.user_sessions CASCADE;
DROP TABLE IF EXISTS public.user_devices CASCADE;
DROP TABLE IF EXISTS public.user_settings CASCADE;
DROP TABLE IF EXISTS public.user_subscriptions CASCADE;
DROP TABLE IF EXISTS public.subscription_plans CASCADE;
DROP TABLE IF EXISTS public.subscriptions CASCADE;
DROP TABLE IF EXISTS public.reward_points CASCADE;
DROP TABLE IF EXISTS public.coupons CASCADE;
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.product_categories CASCADE;
DROP TABLE IF EXISTS public.seller_profiles CASCADE;
DROP TABLE IF EXISTS public.services CASCADE;
DROP TABLE IF EXISTS public.kyc_documents CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.submissions CASCADE;
DROP TABLE IF EXISTS public.applications CASCADE;
DROP TABLE IF EXISTS public.disputes CASCADE;
DROP TABLE IF EXISTS public.deposits CASCADE;
DROP TABLE IF EXISTS public.withdrawals CASCADE;
DROP TABLE IF EXISTS public.campaigns CASCADE;
DROP TABLE IF EXISTS public.linked_accounts CASCADE;
DROP TABLE IF EXISTS public.addresses CASCADE;
DROP TABLE IF EXISTS public.wallets CASCADE;
DROP TABLE IF EXISTS public.brand_profiles CASCADE;
DROP TABLE IF EXISTS public.creator_profiles CASCADE;
DROP TABLE IF EXISTS public.platform_settings CASCADE;
DROP TABLE IF EXISTS public.system_settings CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Drop storage buckets
DELETE FROM storage.objects WHERE bucket_id IN ('avatars', 'kyc-documents', 'campaign-assets', 'product-images', 'deposit-proofs');
DELETE FROM storage.buckets WHERE id IN ('avatars', 'kyc-documents', 'campaign-assets', 'product-images', 'deposit-proofs');

-- ============================================================
-- DONE! All tables, policies, triggers, functions dropped.
-- Now run schema.sql for fresh setup.
-- ============================================================
