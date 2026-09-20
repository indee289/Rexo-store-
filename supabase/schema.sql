-- ============================================================
-- Rexo Marketplace - Supabase Database Schema
-- Complete schema with RLS policies, indexes, and storage
-- ============================================================

-- ============================================================
-- DROP OLD TABLES
-- ============================================================
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS kyc_documents CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS deliverables CASCADE;
DROP TABLE IF EXISTS campaign_applications CASCADE;
DROP TABLE IF EXISTS campaigns CASCADE;
DROP TABLE IF EXISTS withdrawals CASCADE;
DROP TABLE IF EXISTS deposits CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS wallets CASCADE;
DROP TABLE IF EXISTS brand_profiles CASCADE;
DROP TABLE IF EXISTS creator_profiles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Also drop new tables if they exist (for idempotent runs)
DROP TABLE IF EXISTS platform_settings CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS submissions CASCADE;
DROP TABLE IF EXISTS applications CASCADE;

-- ============================================================
-- CREATE TABLES
-- ============================================================

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    name TEXT DEFAULT '',
    handle TEXT UNIQUE,
    role TEXT NOT NULL DEFAULT 'creator' CHECK (role IN ('creator', 'brand', 'admin')),
    admin_sub_role TEXT CHECK (admin_sub_role IN ('super_admin', 'finance_admin', 'support_admin')),
    account_status TEXT NOT NULL DEFAULT 'active' CHECK (account_status IN ('active', 'suspended', 'banned', 'pending_verification')),
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    avatar_url TEXT,
    bio TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Wallets table
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    available_balance DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    escrow_balance DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total_earnings DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total_withdrawn DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    is_frozen BOOLEAN NOT NULL DEFAULT FALSE,
    currency TEXT NOT NULL DEFAULT 'INR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Creator profiles table
CREATE TABLE creator_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    category TEXT,
    followers INTEGER DEFAULT 0,
    engagement_rate DECIMAL(5, 2) DEFAULT 0.00,
    completed_campaigns INTEGER DEFAULT 0,
    rating DECIMAL(3, 2) DEFAULT 0.00,
    instagram_handle TEXT,
    youtube_channel TEXT,
    tiktok_handle TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Brand profiles table
CREATE TABLE brand_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    company_name TEXT,
    website TEXT,
    industry TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Campaigns table
CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    budget DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    per_creator_payout DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    cover_image_url TEXT,
    platform TEXT CHECK (platform IN ('instagram', 'youtube', 'tiktok', 'twitter', 'multiple')),
    category TEXT,
    total_slots INTEGER NOT NULL DEFAULT 1,
    filled_slots INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed', 'cancelled')),
    escrow_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    deadline TIMESTAMPTZ,
    guidelines TEXT,
    min_followers INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Applications table
CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pitch TEXT,
    portfolio_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'withdrawn')),
    admin_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(campaign_id, creator_id)
);

-- Submissions table
CREATE TABLE submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    deliverable_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'revision_requested')),
    admin_notes TEXT,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Deposits table
CREATE TABLE deposits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL,
    payment_method TEXT,
    transaction_ref TEXT,
    proof_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

-- Withdrawals table
CREATE TABLE withdrawals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL,
    method TEXT,
    payout_details JSONB,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
    transaction_ref TEXT,
    admin_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

-- Products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    original_price DECIMAL(10, 2),
    stock INTEGER NOT NULL DEFAULT 0,
    category TEXT,
    image_url TEXT,
    images JSONB DEFAULT '[]'::jsonb,
    seller_id UUID REFERENCES users(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Orders table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_amount DECIMAL(12, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')),
    shipping_address JSONB,
    payment_method TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Order items table
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    price DECIMAL(10, 2) NOT NULL
);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT,
    type TEXT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit logs table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action_type TEXT NOT NULL,
    target_id UUID,
    target_type TEXT,
    reason TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- KYC Documents table
CREATE TABLE kyc_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    document_url TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    verified_at TIMESTAMPTZ
);

-- Platform settings table
CREATE TABLE platform_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL UNIQUE,
    value TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE brand_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================

-- Users policies
-- IMPORTANT: Policies on the users table must NEVER subquery the users table itself.
-- Doing so causes infinite recursion (PostgreSQL error 42P17).
-- Instead, use auth.uid() checks or auth.jwt() claims for role-based access.

-- Any authenticated user can read profiles (needed for cross-user joins)
CREATE POLICY "Authenticated users can read all profiles" ON users
    FOR SELECT USING (auth.role() = 'authenticated');

-- Users can update their own data
CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Admins can update any user - use JWT claim to avoid recursion
CREATE POLICY "Admins can update any user" ON users
    FOR UPDATE USING (
        (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
        OR auth.uid() = id
    );

-- Allow insert for authenticated users (own row only)
CREATE POLICY "Allow insert for authenticated users" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow delete for service role only (admin operations via server-side)
CREATE POLICY "Service role can delete users" ON users
    FOR DELETE USING (auth.role() = 'service_role');

-- Wallets policies
CREATE POLICY "Users can read own wallet" ON wallets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can read all wallets" ON wallets
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can update wallets" ON wallets
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- Creator profiles policies
CREATE POLICY "Anyone can read creator profiles" ON creator_profiles
    FOR SELECT USING (TRUE);

CREATE POLICY "Creators can update own profile" ON creator_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Creators can insert own profile" ON creator_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Brand profiles policies
CREATE POLICY "Anyone can read brand profiles" ON brand_profiles
    FOR SELECT USING (TRUE);

CREATE POLICY "Brands can update own profile" ON brand_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Brands can insert own profile" ON brand_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Campaigns policies
CREATE POLICY "Anyone can read active campaigns" ON campaigns
    FOR SELECT USING (status = 'active' OR brand_id = auth.uid() OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Brands can create campaigns" ON campaigns
    FOR INSERT WITH CHECK (auth.uid() = brand_id);

CREATE POLICY "Brands can update own campaigns" ON campaigns
    FOR UPDATE USING (auth.uid() = brand_id OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- Applications policies
CREATE POLICY "Creators can read own applications" ON applications
    FOR SELECT USING (auth.uid() = creator_id);

CREATE POLICY "Brands can read applications for their campaigns" ON applications
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM campaigns WHERE id = campaign_id AND brand_id = auth.uid())
    );

CREATE POLICY "Admins can read all applications" ON applications
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Creators can create applications" ON applications
    FOR INSERT WITH CHECK (auth.uid() = creator_id);

-- SECURITY FIX (audit 2026-09-20): add WITH CHECK so creators can only set
-- status to 'pending' (revert) or 'withdrawn'. Without this clause a creator
-- could UPDATE admin_notes, rejection_reason, reviewed_by or any other field
-- on their own application row, which is not the intent.
CREATE POLICY "Creators can update own applications" ON applications
    FOR UPDATE
    USING (auth.uid() = creator_id)
    WITH CHECK (
        auth.uid() = creator_id
        AND status IN ('pending', 'withdrawn')
    );

CREATE POLICY "Admins can update any application" ON applications
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- Submissions policies
CREATE POLICY "Creators can read own submissions" ON submissions
    FOR SELECT USING (auth.uid() = creator_id);

CREATE POLICY "Admins can read all submissions" ON submissions
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Creators can create submissions" ON submissions
    FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Admins can update submissions" ON submissions
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- Deposits policies
CREATE POLICY "Users can read own deposits" ON deposits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can read all deposits" ON deposits
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can create deposits" ON deposits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update deposits" ON deposits
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- Withdrawals policies
CREATE POLICY "Users can read own withdrawals" ON withdrawals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can read all withdrawals" ON withdrawals
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can create withdrawals" ON withdrawals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update withdrawals" ON withdrawals
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- Products policies
CREATE POLICY "Anyone can read active products" ON products
    FOR SELECT USING (is_active = TRUE OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Authorized users can create products" ON products
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
        OR EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'brand')
        OR EXISTS (
            SELECT 1 FROM rexo_program_applications
            WHERE creator_id = auth.uid() AND status = 'approved'
        )
    );

CREATE POLICY "Admins can update products" ON products
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- Orders policies
CREATE POLICY "Users can read own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can read all orders" ON orders
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can create orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update orders" ON orders
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can delete own orders" ON orders
    FOR DELETE USING (auth.uid() = user_id);

-- Order items policies
CREATE POLICY "Users can read own order items" ON order_items
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM orders WHERE id = order_id AND user_id = auth.uid())
    );

CREATE POLICY "Admins can read all order items" ON order_items
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can create order items" ON order_items
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM orders WHERE id = order_id AND user_id = auth.uid())
    );

-- Notifications policies
CREATE POLICY "Users can read own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- SECURITY FIX (audit 2026-09-20): restrict notification INSERT so a user can
-- only create a notification addressed to themselves; admins may create for any
-- user (needed for admin broadcast + job-approval notifications from server
-- logic). This closes the exploit where any authenticated user could call
-- Supabase directly and spam/phish any other user's notification inbox.
-- The is_admin() SECURITY DEFINER function is defined in
-- supabase/PERMANENT_FIX_run_this.sql (run that file once if not already applied).
CREATE POLICY "System can create notifications" ON notifications
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
        OR (SELECT EXISTS (
            SELECT 1 FROM public.users
            WHERE id::text = auth.uid()::text AND lower(role) = 'admin'
        ))
    );

CREATE POLICY "Users can delete own notifications" ON notifications
    FOR DELETE USING (auth.uid() = user_id);

-- Audit logs policies
CREATE POLICY "Admins can read audit logs" ON audit_logs
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can create audit logs" ON audit_logs
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- Messages policies
CREATE POLICY "Users can read own messages" ON messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send messages" ON messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update own messages" ON messages
    FOR UPDATE USING (auth.uid() = receiver_id);

-- KYC documents policies
CREATE POLICY "Users can read own KYC documents" ON kyc_documents
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can read all KYC documents" ON kyc_documents
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can upload KYC documents" ON kyc_documents
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update KYC documents" ON kyc_documents
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- Platform settings policies
CREATE POLICY "Anyone can read platform settings" ON platform_settings
    FOR SELECT USING (TRUE);

CREATE POLICY "Admins can manage platform settings" ON platform_settings
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- INDEXES
-- ============================================================

-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_handle ON users(handle);
CREATE INDEX idx_users_account_status ON users(account_status);

-- Wallets indexes
CREATE INDEX idx_wallets_user_id ON wallets(user_id);

-- Creator profiles indexes
CREATE INDEX idx_creator_profiles_user_id ON creator_profiles(user_id);
CREATE INDEX idx_creator_profiles_category ON creator_profiles(category);

-- Brand profiles indexes
CREATE INDEX idx_brand_profiles_user_id ON brand_profiles(user_id);

-- Campaigns indexes
CREATE INDEX idx_campaigns_brand_id ON campaigns(brand_id);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_category ON campaigns(category);
CREATE INDEX idx_campaigns_platform ON campaigns(platform);
CREATE INDEX idx_campaigns_deadline ON campaigns(deadline);

-- Applications indexes
CREATE INDEX idx_applications_campaign_id ON applications(campaign_id);
CREATE INDEX idx_applications_creator_id ON applications(creator_id);
CREATE INDEX idx_applications_status ON applications(status);

-- Submissions indexes
CREATE INDEX idx_submissions_application_id ON submissions(application_id);
CREATE INDEX idx_submissions_campaign_id ON submissions(campaign_id);
CREATE INDEX idx_submissions_creator_id ON submissions(creator_id);
CREATE INDEX idx_submissions_status ON submissions(status);

-- Deposits indexes
CREATE INDEX idx_deposits_user_id ON deposits(user_id);
CREATE INDEX idx_deposits_status ON deposits(status);

-- Withdrawals indexes
CREATE INDEX idx_withdrawals_user_id ON withdrawals(user_id);
CREATE INDEX idx_withdrawals_status ON withdrawals(status);

-- Products indexes
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_is_active ON products(is_active);

-- Orders indexes
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);

-- Order items indexes
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- Audit logs indexes
CREATE INDEX idx_audit_logs_admin_id ON audit_logs(admin_id);
CREATE INDEX idx_audit_logs_action_type ON audit_logs(action_type);
CREATE INDEX idx_audit_logs_target_id ON audit_logs(target_id);

-- Messages indexes
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

-- KYC documents indexes
CREATE INDEX idx_kyc_documents_user_id ON kyc_documents(user_id);
CREATE INDEX idx_kyc_documents_status ON kyc_documents(status);

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES
    ('avatars', 'avatars', TRUE),
    ('kyc-documents', 'kyc-documents', FALSE),
    ('campaign-assets', 'campaign-assets', TRUE),
    ('product-images', 'product-images', TRUE),
    ('deposit-proofs', 'deposit-proofs', FALSE)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STORAGE OBJECTS RLS POLICIES
-- ============================================================

-- Avatars (public bucket) policies
CREATE POLICY "Users can upload avatars" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can update own avatars" ON storage.objects
    FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own avatars" ON storage.objects
    FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- KYC Documents (private bucket) policies
CREATE POLICY "Users can upload kyc documents" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'kyc-documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own kyc documents" ON storage.objects
    FOR SELECT USING (bucket_id = 'kyc-documents' AND (auth.uid()::text = (storage.foldername(name))[1] OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')));

CREATE POLICY "Users can update own kyc documents" ON storage.objects
    FOR UPDATE USING (bucket_id = 'kyc-documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own kyc documents" ON storage.objects
    FOR DELETE USING (bucket_id = 'kyc-documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Campaign Assets (public bucket) policies
CREATE POLICY "Users can upload campaign assets" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'campaign-assets' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view campaign assets" ON storage.objects
    FOR SELECT USING (bucket_id = 'campaign-assets');

CREATE POLICY "Users can update own campaign assets" ON storage.objects
    FOR UPDATE USING (bucket_id = 'campaign-assets' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own campaign assets" ON storage.objects
    FOR DELETE USING (bucket_id = 'campaign-assets' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Product Images (public bucket) policies
CREATE POLICY "Users can upload product images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'product-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view product images" ON storage.objects
    FOR SELECT USING (bucket_id = 'product-images');

CREATE POLICY "Users can update own product images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'product-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own product images" ON storage.objects
    FOR DELETE USING (bucket_id = 'product-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Deposit Proofs (private bucket) policies
CREATE POLICY "Users can upload deposit proofs" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'deposit-proofs' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own deposit proofs" ON storage.objects
    FOR SELECT USING (bucket_id = 'deposit-proofs' AND (auth.uid()::text = (storage.foldername(name))[1] OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')));

CREATE POLICY "Users can update own deposit proofs" ON storage.objects
    FOR UPDATE USING (bucket_id = 'deposit-proofs' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own deposit proofs" ON storage.objects
    FOR DELETE USING (bucket_id = 'deposit-proofs' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================================
-- TRIGGER: Auto-create user profile when auth.users signup
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name, role, account_status)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'creator'),
        'active'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_auth_user();

-- ============================================================
-- TRIGGER: Auto-create wallet when user is created
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user_wallet()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.wallets (user_id)
    VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_user_created_create_wallet
    AFTER INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_wallet();

-- ============================================================
-- TRIGGER: Prevent withdrawals exceeding available balance
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_withdrawal_balance()
RETURNS TRIGGER AS $$
DECLARE
    current_balance DECIMAL(12, 2);
BEGIN
    SELECT available_balance INTO current_balance
    FROM public.wallets
    WHERE user_id = NEW.user_id;

    IF current_balance IS NULL THEN
        RAISE EXCEPTION 'No wallet found for user %', NEW.user_id;
    END IF;

    IF NEW.amount > current_balance THEN
        RAISE EXCEPTION 'Insufficient balance: requested %, available %', NEW.amount, current_balance;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_withdrawal_check_balance
    BEFORE INSERT ON public.withdrawals
    FOR EACH ROW
    EXECUTE FUNCTION public.check_withdrawal_balance();

-- ============================================================
-- TRIGGER: Check and decrement stock on order item insert
-- ============================================================
CREATE OR REPLACE FUNCTION check_and_decrement_stock()
RETURNS TRIGGER AS $$
DECLARE
  current_stock INTEGER;
BEGIN
  SELECT stock INTO current_stock FROM products WHERE id = NEW.product_id FOR UPDATE;
  IF current_stock IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;
  IF current_stock < NEW.quantity THEN
    RAISE EXCEPTION 'Insufficient stock. Available: %, Requested: %', current_stock, NEW.quantity;
  END IF;
  UPDATE products SET stock = stock - NEW.quantity WHERE id = NEW.product_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_order_item_check_stock
  BEFORE INSERT ON order_items
  FOR EACH ROW
  EXECUTE FUNCTION check_and_decrement_stock();

-- ============================================================
-- TABLE: linked_accounts
-- ============================================================
CREATE TABLE IF NOT EXISTS public.linked_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    platform TEXT NOT NULL,
    handle TEXT NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.linked_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own linked accounts"
    ON public.linked_accounts FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own linked accounts"
    ON public.linked_accounts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own linked accounts"
    ON public.linked_accounts FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own linked accounts"
    ON public.linked_accounts FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all linked accounts"
    ON public.linked_accounts FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: addresses
-- ============================================================
CREATE TABLE IF NOT EXISTS public.addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    pincode TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own addresses"
    ON public.addresses FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own addresses"
    ON public.addresses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own addresses"
    ON public.addresses FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own addresses"
    ON public.addresses FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all addresses"
    ON public.addresses FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: reviews
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    target_id UUID,
    target_type TEXT,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own reviews"
    ON public.reviews FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own reviews"
    ON public.reviews FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reviews"
    ON public.reviews FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reviews"
    ON public.reviews FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all reviews"
    ON public.reviews FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: reward_points
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reward_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    points INTEGER DEFAULT 0,
    last_earned_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.reward_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own reward points"
    ON public.reward_points FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own reward points"
    ON public.reward_points FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage all reward points"
    ON public.reward_points FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: coupons
-- ============================================================
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    discount_type TEXT NOT NULL,
    discount_value DECIMAL NOT NULL,
    min_order DECIMAL,
    max_uses INTEGER,
    used_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read active coupons"
    ON public.coupons FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage all coupons"
    ON public.coupons FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: product_categories
-- ============================================================
CREATE TABLE IF NOT EXISTS public.product_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    parent_id UUID REFERENCES public.product_categories(id) ON DELETE SET NULL,
    icon_url TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read product categories"
    ON public.product_categories FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage all product categories"
    ON public.product_categories FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: seller_profiles
-- ============================================================
CREATE TABLE IF NOT EXISTS public.seller_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    store_name TEXT,
    description TEXT,
    logo_url TEXT,
    rating DECIMAL DEFAULT 0,
    total_sales INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.seller_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own seller profile"
    ON public.seller_profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own seller profile"
    ON public.seller_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own seller profile"
    ON public.seller_profiles FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all seller profiles"
    ON public.seller_profiles FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: services
-- ============================================================
CREATE TABLE IF NOT EXISTS public.services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    service_type TEXT,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own services"
    ON public.services FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own services"
    ON public.services FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own services"
    ON public.services FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own services"
    ON public.services FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all services"
    ON public.services FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: subscription_plans
-- ============================================================
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    price DECIMAL NOT NULL,
    features JSONB,
    duration_days INTEGER NOT NULL,
    interval TEXT DEFAULT 'month' CHECK (interval IN ('month', 'year', 'week', 'day')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read subscription plans"
    ON public.subscription_plans FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage all subscription plans"
    ON public.subscription_plans FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: user_subscriptions
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES public.subscription_plans(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active',
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own subscriptions"
    ON public.user_subscriptions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions"
    ON public.user_subscriptions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage all subscriptions"
    ON public.user_subscriptions FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: user_devices
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    device_name TEXT,
    device_type TEXT,
    os_version TEXT,
    app_version TEXT,
    fcm_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own devices"
    ON public.user_devices FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own devices"
    ON public.user_devices FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own devices"
    ON public.user_devices FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own devices"
    ON public.user_devices FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all devices"
    ON public.user_devices FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: user_sessions
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    device_id UUID,
    ip_address TEXT,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own sessions"
    ON public.user_sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions"
    ON public.user_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions"
    ON public.user_sessions FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all sessions"
    ON public.user_sessions FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: user_settings
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    theme TEXT DEFAULT 'system',
    language TEXT DEFAULT 'en',
    notifications_enabled BOOLEAN DEFAULT TRUE,
    email_notifications BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own settings"
    ON public.user_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings"
    ON public.user_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own settings"
    ON public.user_settings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all settings"
    ON public.user_settings FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: user_suspensions
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_suspensions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reason TEXT,
    suspended_by UUID REFERENCES public.users(id),
    starts_at TIMESTAMPTZ DEFAULT NOW(),
    ends_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    appeal_text TEXT,
    appeal_status TEXT DEFAULT 'none',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_suspensions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own suspensions"
    ON public.user_suspensions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all suspensions"
    ON public.user_suspensions FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: user_warnings
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_warnings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reason TEXT,
    severity TEXT DEFAULT 'low',
    issued_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_warnings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own warnings"
    ON public.user_warnings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all warnings"
    ON public.user_warnings FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: ai_moderation_logs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.ai_moderation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID,
    content_type TEXT,
    flagged_reason TEXT,
    confidence_score DECIMAL,
    action_taken TEXT,
    reviewed_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.ai_moderation_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage ai moderation logs"
    ON public.ai_moderation_logs FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: device_fingerprints
-- ============================================================
CREATE TABLE IF NOT EXISTS public.device_fingerprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    fingerprint_hash TEXT UNIQUE,
    device_info JSONB,
    ip_address TEXT,
    is_trusted BOOLEAN DEFAULT FALSE,
    first_seen_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.device_fingerprints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own device fingerprints"
    ON public.device_fingerprints FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own device fingerprints"
    ON public.device_fingerprints FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own device fingerprints"
    ON public.device_fingerprints FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all device fingerprints"
    ON public.device_fingerprints FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: security_audit_logs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.security_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    event_type TEXT NOT NULL,
    ip_address TEXT,
    device_info TEXT,
    severity TEXT DEFAULT 'info',
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.security_audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage security audit logs"
    ON public.security_audit_logs FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: security_logs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.security_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    ip_address TEXT,
    device_info TEXT,
    location TEXT,
    is_suspicious BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.security_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own security logs"
    ON public.security_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all security logs"
    ON public.security_logs FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: disputes
-- ============================================================
CREATE TABLE IF NOT EXISTS public.disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    order_id UUID,
    campaign_id UUID,
    subject TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'open',
    resolution TEXT,
    admin_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own disputes"
    ON public.disputes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own disputes"
    ON public.disputes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own disputes"
    ON public.disputes FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all disputes"
    ON public.disputes FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- TABLE: moderation_queue
-- ============================================================
CREATE TABLE IF NOT EXISTS public.moderation_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID,
    content_type TEXT,
    reported_by UUID REFERENCES public.users(id),
    reason TEXT,
    status TEXT DEFAULT 'pending',
    reviewed_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.moderation_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert moderation reports"
    ON public.moderation_queue FOR INSERT
    WITH CHECK (auth.uid() = reported_by);

CREATE POLICY "Users can read own moderation reports"
    ON public.moderation_queue FOR SELECT
    USING (auth.uid() = reported_by);

CREATE POLICY "Admins can manage all moderation queue"
    ON public.moderation_queue FOR ALL
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- INDEXES for new tables
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_linked_accounts_user_id ON public.linked_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON public.addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_target ON public.reviews(target_id, target_type);
CREATE INDEX IF NOT EXISTS idx_reward_points_user_id ON public.reward_points(user_id);
CREATE INDEX IF NOT EXISTS idx_seller_profiles_user_id ON public.seller_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_services_user_id ON public.services(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON public.user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON public.user_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_suspensions_user_id ON public.user_suspensions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_warnings_user_id ON public.user_warnings(user_id);
CREATE INDEX IF NOT EXISTS idx_device_fingerprints_user_id ON public.device_fingerprints(user_id);
CREATE INDEX IF NOT EXISTS idx_security_audit_logs_user_id ON public.security_audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_security_logs_user_id ON public.security_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_disputes_user_id ON public.disputes(user_id);
CREATE INDEX IF NOT EXISTS idx_moderation_queue_status ON public.moderation_queue(status);
CREATE INDEX IF NOT EXISTS idx_coupons_code ON public.coupons(code);
CREATE INDEX IF NOT EXISTS idx_product_categories_parent ON public.product_categories(parent_id);

-- ============================================================
-- TABLE: rexo_program_applications
-- ============================================================
CREATE TABLE IF NOT EXISTS public.rexo_program_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES public.users(id) ON DELETE SET NULL
);

ALTER TABLE public.rexo_program_applications ENABLE ROW LEVEL SECURITY;

-- Creator can view own applications
CREATE POLICY "Creators can read own rexo applications"
    ON public.rexo_program_applications FOR SELECT
    USING (auth.uid() = creator_id);

-- Creator can insert own application
CREATE POLICY "Creators can apply for rexo program"
    ON public.rexo_program_applications FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

-- Admins can view all applications
CREATE POLICY "Admins can read all rexo applications"
    ON public.rexo_program_applications FOR SELECT
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Admins can update (approve/reject) any application
CREATE POLICY "Admins can update rexo applications"
    ON public.rexo_program_applications FOR UPDATE
    USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE INDEX IF NOT EXISTS idx_rexo_program_creator_id ON public.rexo_program_applications(creator_id);
CREATE INDEX IF NOT EXISTS idx_rexo_program_status ON public.rexo_program_applications(status);

-- ============================================================
-- SEED: Admin user
-- ============================================================
-- The admin user must first sign up through the app via Supabase Auth.
-- After the admin user has signed up and authenticated, run the following
-- SQL to promote their account to admin (replace <auth-user-uuid> with the
-- actual UUID from auth.users after signup):
--
-- INSERT INTO public.users (id, email, name, role, admin_sub_role, is_verified, account_status)
-- VALUES (
--     '<auth-user-uuid>',
--     'rexoagency.in@gmail.com',
--     'Rexo Admin',
--     'admin',
--     'super_admin',
--     TRUE,
--     'active'
-- );
--
-- Alternatively, if the user already exists from signup, update their role:
--
-- UPDATE public.users
-- SET role = 'admin', admin_sub_role = 'super_admin', is_verified = TRUE
-- WHERE email = 'rexoagency.in@gmail.com';
