-- Create Enums if they don't exist
-- NEUTRALIZED FOR SECURITY: Blocked mass DROP POLICY loop
SELECT 1;

-- NEUTRALIZED FOR SECURITY: Blocked mass DROP POLICY loop
SELECT 1;

-- NEUTRALIZED FOR SECURITY: Blocked mass DROP POLICY loop
SELECT 1;

-- 1. Users
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    email TEXT,
    role user_role DEFAULT 'customer',
    name TEXT,
    avatar_url TEXT,
    accountStatus account_status DEFAULT 'active',
    kyc_status TEXT DEFAULT 'unverified',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Wallets
CREATE TABLE IF NOT EXISTS wallets (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    available_balance NUMERIC DEFAULT 0,
    pending_balance NUMERIC DEFAULT 0,
    total_earned NUMERIC DEFAULT 0,
    total_spent NUMERIC DEFAULT 0,
    is_frozen BOOLEAN DEFAULT false,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. KYC Documents
CREATE TABLE IF NOT EXISTS kyc_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    document_type TEXT,
    document_url TEXT,
    status TEXT DEFAULT 'pending',
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    admin_notes TEXT
);

-- 4. Campaigns
CREATE TABLE IF NOT EXISTS campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id UUID REFERENCES users(id),
    title TEXT,
    description TEXT,
    budget NUMERIC,
    status TEXT DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Campaign Applications
CREATE TABLE IF NOT EXISTS campaign_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id),
    creator_id UUID REFERENCES users(id),
    status TEXT DEFAULT 'pending',
    cover_letter TEXT,
    proposed_rate NUMERIC,
    applied_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Products
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES users(id),
    title TEXT,
    description TEXT,
    price NUMERIC,
    type TEXT,
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Withdrawals
CREATE TABLE IF NOT EXISTS withdrawals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    amount NUMERIC,
    method TEXT,
    status TEXT DEFAULT 'pending',
    requested_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Deposits
CREATE TABLE IF NOT EXISTS deposits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    amount NUMERIC,
    method TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Disputes
CREATE TABLE IF NOT EXISTS disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID,
    user_id UUID REFERENCES users(id),
    reason TEXT,
    status TEXT DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Audit Logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action TEXT,
    category TEXT,
    target_id TEXT,
    target_name TEXT,
    admin_id UUID REFERENCES users(id),
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Policies (Enable RLS & Admin Master Access)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Allow everything policy for quick admin enablement 
-- Note: Replace with proper role-based policies in production
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
