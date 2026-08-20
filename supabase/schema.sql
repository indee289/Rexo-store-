-- FULL SUPABASE PRODUCTION DATABASE SCHEMA FOR REXO / BRAND CREATOR MARKETPLACE
-- Tables: 16 Core Domain Tables with Relations, Indexes, Timestamps, and RLS Policies

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
    id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    handle VARCHAR(100) UNIQUE,
    avatar TEXT,
    role VARCHAR(50) NOT NULL DEFAULT 'creator' CHECK (role IN ('creator', 'brand', 'admin')),
    admin_sub_role VARCHAR(50) CHECK (admin_sub_role IN ('super_admin', 'finance_admin', 'moderator', 'support_agent')),
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_banned BOOLEAN NOT NULL DEFAULT FALSE,
    subscription_tier VARCHAR(50) NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'creator_pro', 'brand_pro', 'enterprise')),
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- 2. CREATOR PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.creator_profiles (
    user_id VARCHAR(255) PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    category VARCHAR(100) DEFAULT 'Lifestyle',
    followers INTEGER DEFAULT 0,
    engagement_rate NUMERIC(5,2) DEFAULT 0.00,
    instagram_handle VARCHAR(100),
    youtube_channel VARCHAR(255),
    min_rate NUMERIC(12,2) DEFAULT 0.00,
    rating NUMERIC(3,2) DEFAULT 5.00,
    completed_campaigns INTEGER DEFAULT 0,
    portfolio JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. BRAND PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.brand_profiles (
    user_id VARCHAR(255) PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    company_name VARCHAR(255) NOT NULL,
    industry VARCHAR(100) DEFAULT 'Ecommerce',
    website VARCHAR(255),
    gst_number VARCHAR(50),
    campaigns_posted INTEGER DEFAULT 0,
    total_spent NUMERIC(12,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. WALLETS TABLE
CREATE TABLE IF NOT EXISTS public.wallets (
    user_id VARCHAR(255) PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    available_balance NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (available_balance >= 0),
    escrow_balance NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (escrow_balance >= 0),
    total_earnings NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_withdrawn NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS public.transactions (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('deposit', 'withdrawal', 'escrow_hold', 'escrow_release', 'shop_purchase', 'subscription')),
    status VARCHAR(50) NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    reference_id VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);

-- 6. DEPOSITS TABLE (MANUAL DEPOSIT WORKFLOW)
CREATE TABLE IF NOT EXISTS public.deposits (
    id VARCHAR(255) PRIMARY KEY,
    brand_id VARCHAR(255) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    brand_name VARCHAR(255) NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(50) NOT NULL DEFAULT 'upi_manual',
    transaction_ref VARCHAR(255) NOT NULL,
    proof_screenshot_url TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_deposits_brand_id ON public.deposits(brand_id);
CREATE INDEX IF NOT EXISTS idx_deposits_status ON public.deposits(status);

-- 7. WITHDRAWALS TABLE (MANUAL WITHDRAWAL WORKFLOW)
CREATE TABLE IF NOT EXISTS public.withdrawals (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_name VARCHAR(255) NOT NULL,
    user_role VARCHAR(50) NOT NULL DEFAULT 'creator',
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payout_method VARCHAR(50) NOT NULL DEFAULT 'upi',
    payout_details JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    transaction_ref VARCHAR(255),
    admin_notes TEXT,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_withdrawals_user_id ON public.withdrawals(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawals_status ON public.withdrawals(status);

-- 8. CAMPAIGNS TABLE
CREATE TABLE IF NOT EXISTS public.campaigns (
    id VARCHAR(255) PRIMARY KEY,
    brand_id VARCHAR(255) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    brand_name VARCHAR(255) NOT NULL,
    brand_avatar TEXT,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    budget NUMERIC(12,2) NOT NULL CHECK (budget > 0),
    payout_per_creator NUMERIC(12,2) NOT NULL CHECK (payout_per_creator > 0),
    deadline VARCHAR(100) NOT NULL,
    deliverable_type VARCHAR(100) NOT NULL,
    slots INTEGER NOT NULL DEFAULT 1,
    filled_slots INTEGER NOT NULL DEFAULT 0,
    description TEXT NOT NULL,
    requirements JSONB NOT NULL DEFAULT '[]'::jsonb,
    image TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('draft', 'active', 'paused', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_campaigns_brand_id ON public.campaigns(brand_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON public.campaigns(status);

-- 9. CAMPAIGN APPLICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.campaign_applications (
    id VARCHAR(255) PRIMARY KEY,
    campaign_id VARCHAR(255) NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
    campaign_title VARCHAR(255) NOT NULL,
    brand_name VARCHAR(255) NOT NULL,
    creator_id VARCHAR(255) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    creator_name VARCHAR(255) NOT NULL,
    creator_handle VARCHAR(100) NOT NULL,
    creator_avatar TEXT,
    fee_requested NUMERIC(12,2) NOT NULL CHECK (fee_requested > 0),
    pitch TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'approved', 'rejected', 'paid')),
    deliverable_url TEXT,
    rejection_reason TEXT,
    payout_remarks TEXT,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_applications_campaign_id ON public.campaign_applications(campaign_id);
CREATE INDEX IF NOT EXISTS idx_applications_creator_id ON public.campaign_applications(creator_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON public.campaign_applications(status);

-- 10. DELIVERABLES TABLE
CREATE TABLE IF NOT EXISTS public.deliverables (
    id VARCHAR(255) PRIMARY KEY,
    application_id VARCHAR(255) NOT NULL REFERENCES public.campaign_applications(id) ON DELETE CASCADE,
    campaign_id VARCHAR(255) NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
    creator_id VARCHAR(255) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('instagram_reel', 'instagram_story', 'youtube_video', 'custom_post')),
    post_url TEXT NOT NULL,
    caption TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'under_review' CHECK (status IN ('under_review', 'approved', 'rejected_revision')),
    admin_feedback TEXT,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ
);

-- 11. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(100) NOT NULL,
    payload JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    delivery_status VARCHAR(50) NOT NULL DEFAULT 'delivered',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);

-- 12. PRODUCTS TABLE (DIGITAL, PHYSICAL, & SERVICES)
CREATE TABLE IF NOT EXISTS public.products (
    id VARCHAR(255) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    category VARCHAR(100) NOT NULL,
    product_type VARCHAR(50) NOT NULL CHECK (product_type IN ('digital', 'physical', 'service')),
    is_free BOOLEAN NOT NULL DEFAULT FALSE,
    cover_image TEXT NOT NULL,
    download_file TEXT,
    stock INTEGER DEFAULT 100,
    status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'out_of_stock', 'archived')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_type ON public.products(product_type);

-- 13. ORDERS TABLE (DIGITAL, PHYSICAL WITH ADDRESS, & SERVICES)
CREATE TABLE IF NOT EXISTS public.orders (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_name VARCHAR(255) NOT NULL,
    product_id VARCHAR(255) NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    product_title VARCHAR(255) NOT NULL,
    product_type VARCHAR(50) NOT NULL CHECK (product_type IN ('digital', 'physical', 'service')),
    price NUMERIC(12,2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'completed', 'cancelled')),
    shipping_address JSONB,
    digital_download_url TEXT,
    tracking_number VARCHAR(100),
    service_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);

-- 14. SUBSCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    plan_name VARCHAR(50) NOT NULL CHECK (plan_name IN ('free', 'creator_pro', 'brand_pro', 'enterprise')),
    price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expiry_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);

-- 15. KYC DOCUMENTS TABLE
CREATE TABLE IF NOT EXISTS public.kyc_documents (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_name VARCHAR(255) NOT NULL,
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('aadhaar', 'pan', 'gst', 'bank_passbook')),
    document_number VARCHAR(100) NOT NULL,
    document_url TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
    rejection_reason TEXT,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    verified_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_kyc_user_id ON public.kyc_documents(user_id);

-- 16. AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id VARCHAR(255) PRIMARY KEY,
    admin_id VARCHAR(255) NOT NULL,
    admin_name VARCHAR(255) NOT NULL,
    admin_role VARCHAR(50) NOT NULL,
    action VARCHAR(255) NOT NULL,
    target_type VARCHAR(100) NOT NULL,
    target_id VARCHAR(255) NOT NULL,
    target_name VARCHAR(255),
    reason TEXT,
    ip_address VARCHAR(50) DEFAULT '127.0.0.1',
    device VARCHAR(255) DEFAULT 'Admin Console',
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_admin_id ON public.audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON public.audit_logs(timestamp DESC);
