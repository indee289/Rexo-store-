-- Drop conflicting tables first to fix the foreign key issue
DROP TABLE IF EXISTS campaign_applications CASCADE;
DROP TABLE IF EXISTS campaigns CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS kyc_documents CASCADE;
DROP TABLE IF EXISTS wallets CASCADE;
DROP TABLE IF EXISTS withdrawals CASCADE;
DROP TABLE IF EXISTS deposits CASCADE;
DROP TABLE IF EXISTS disputes CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;

-- We don't drop users as it is tied to auth, just make sure we alter it instead if needed, but it seems users table is fine.

CREATE TABLE IF NOT EXISTS wallets (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    available_balance NUMERIC DEFAULT 0,
    pending_balance NUMERIC DEFAULT 0,
    total_earned NUMERIC DEFAULT 0,
    total_spent NUMERIC DEFAULT 0,
    is_frozen BOOLEAN DEFAULT false,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

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

CREATE TABLE IF NOT EXISTS campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id UUID REFERENCES users(id),
    title TEXT,
    description TEXT,
    budget NUMERIC,
    status TEXT DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS campaign_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id),
    creator_id UUID REFERENCES users(id),
    status TEXT DEFAULT 'pending',
    cover_letter TEXT,
    proposed_rate NUMERIC,
    applied_at TIMESTAMPTZ DEFAULT NOW()
);

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

CREATE TABLE IF NOT EXISTS withdrawals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    amount NUMERIC,
    method TEXT,
    status TEXT DEFAULT 'pending',
    requested_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS deposits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    amount NUMERIC,
    method TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID,
    user_id UUID REFERENCES users(id),
    reason TEXT,
    status TEXT DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

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

-- 2. Drop existing conflicting policies automatically
-- NEUTRALIZED FOR SECURITY: Blocked mass DROP POLICY loop
SELECT 1;

-- 3. Apply Full Allow Policies (Admin Control enable karega)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;

ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;

ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;

ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;

ALTER TABLE campaign_applications ENABLE ROW LEVEL SECURITY;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;

ALTER TABLE products ENABLE ROW LEVEL SECURITY;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;

ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;

ALTER TABLE deposits ENABLE ROW LEVEL SECURITY;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;

ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
