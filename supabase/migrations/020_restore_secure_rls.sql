-- 020_restore_secure_rls.sql
-- 1. CLEAN SLATE: Drop all existing policies safely to remove USING (true) overrides
DO $$ DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
    END LOOP;
END $$;

-- 2. RE-ENABLE RLS GLOBALLY ON ALL TABLES
ALTER TABLE IF EXISTS users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS kyc_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS campaign_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS products ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS creator_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS brand_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS seller_profiles ENABLE ROW LEVEL SECURITY;

-- 3. RECREATE STRICT, ROLE-BOUND POLICIES

-- USERS Table
CREATE POLICY "Users can read own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can read all users" ON users FOR SELECT USING (is_admin(auth.uid()));
CREATE POLICY "Admins can update all users" ON users FOR UPDATE USING (is_admin(auth.uid()));
CREATE POLICY "Admins can delete all users" ON users FOR DELETE USING (is_admin(auth.uid()));

-- PUBLIC PROFILES
CREATE POLICY "Public read creator profiles" ON creator_profiles FOR SELECT USING (true);
CREATE POLICY "Public read brand profiles" ON brand_profiles FOR SELECT USING (true);
CREATE POLICY "Public read seller profiles" ON seller_profiles FOR SELECT USING (true);
CREATE POLICY "Users update own creator profile" ON creator_profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users update own brand profile" ON brand_profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users update own seller profile" ON seller_profiles FOR UPDATE USING (auth.uid() = user_id);

-- WALLETS Table (Strict Ownership & No Client-Side Updates)
CREATE POLICY "Users can view own wallet" ON wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all wallets" ON wallets FOR SELECT USING (is_admin(auth.uid()));
CREATE POLICY "Admins can update all wallets" ON wallets FOR UPDATE USING (is_admin(auth.uid()));

-- KYC DOCUMENTS
CREATE POLICY "Users can view own KYC" ON kyc_documents FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own KYC" ON kyc_documents FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own KYC if pending" ON kyc_documents FOR UPDATE USING (auth.uid() = user_id AND (status = 'pending' OR status = 'rejected'));
CREATE POLICY "Admins manage all KYC" ON kyc_documents FOR ALL USING (is_admin(auth.uid()));

-- CAMPAIGNS
CREATE POLICY "Anyone can view campaigns" ON campaigns FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Brands manage own campaigns" ON campaigns FOR ALL USING (auth.uid() = brand_id);
CREATE POLICY "Admins manage all campaigns" ON campaigns FOR ALL USING (is_admin(auth.uid()));

-- CAMPAIGN APPLICATIONS
CREATE POLICY "Creators view own applications" ON campaign_applications FOR SELECT USING (auth.uid() = creator_id);
CREATE POLICY "Creators can insert own applications" ON campaign_applications FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Brands view applications for own campaigns" ON campaign_applications FOR SELECT USING (
    EXISTS (SELECT 1 FROM campaigns WHERE id = campaign_applications.campaign_id AND brand_id = auth.uid())
);
CREATE POLICY "Brands update applications for own campaigns" ON campaign_applications FOR UPDATE USING (
    EXISTS (SELECT 1 FROM campaigns WHERE id = campaign_applications.campaign_id AND brand_id = auth.uid())
);
CREATE POLICY "Admins manage all applications" ON campaign_applications FOR ALL USING (is_admin(auth.uid()));

-- PRODUCTS
CREATE POLICY "Anyone can view products" ON products FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Sellers manage own products" ON products FOR ALL USING (auth.uid() = seller_id);
CREATE POLICY "Admins manage all products" ON products FOR ALL USING (is_admin(auth.uid()));

-- WITHDRAWALS & DEPOSITS
CREATE POLICY "Users view own withdrawals" ON withdrawals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own withdrawals" ON withdrawals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage all withdrawals" ON withdrawals FOR ALL USING (is_admin(auth.uid()));

CREATE POLICY "Users view own deposits" ON deposits FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own deposits" ON deposits FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage all deposits" ON deposits FOR ALL USING (is_admin(auth.uid()));

-- DISPUTES
CREATE POLICY "Users view own disputes" ON disputes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own disputes" ON disputes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage all disputes" ON disputes FOR ALL USING (is_admin(auth.uid()));

-- SYSTEM SETTINGS
CREATE POLICY "Anyone can view system settings" ON system_settings FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Admins update system settings" ON system_settings FOR ALL USING (is_admin(auth.uid()));

-- AUDIT LOGS
CREATE POLICY "Admins manage audit logs" ON audit_logs FOR ALL USING (is_admin(auth.uid()));

-- USER SETTINGS / SUBSCRIPTIONS (Using text cast in case 013 schema used TEXT for user_id)
CREATE POLICY "Users manage own settings" ON user_settings FOR ALL USING (auth.uid()::text = "userId");
CREATE POLICY "Admins manage all user settings" ON user_settings FOR ALL USING (is_admin(auth.uid()));

CREATE POLICY "Users view own subscriptions" ON user_subscriptions FOR SELECT USING (auth.uid()::text = "userId");
CREATE POLICY "Admins manage all user subscriptions" ON user_subscriptions FOR ALL USING (is_admin(auth.uid()));
