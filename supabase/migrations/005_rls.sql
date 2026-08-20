-- 005_rls.sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE brand_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE deliverables ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_downloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- USERS
CREATE POLICY "Users can view their own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can view all users" ON users FOR SELECT USING (is_admin(auth.uid()));
CREATE POLICY "Admins can update all users" ON users FOR UPDATE USING (is_admin(auth.uid()));
CREATE POLICY "Admins can delete all users" ON users FOR DELETE USING (is_admin(auth.uid()));

-- PUBLIC PROFILES (Brands can see creators, creators can see brands)
CREATE POLICY "Public read profiles" ON creator_profiles FOR SELECT USING (true);
CREATE POLICY "Public read brand profiles" ON brand_profiles FOR SELECT USING (true);
CREATE POLICY "Public read seller profiles" ON seller_profiles FOR SELECT USING (true);

CREATE POLICY "Update own creator profile" ON creator_profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Update own brand profile" ON brand_profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Update own seller profile" ON seller_profiles FOR UPDATE USING (auth.uid() = user_id);

-- WALLETS
CREATE POLICY "Users view own wallet" ON wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins view all wallets" ON wallets FOR SELECT USING (is_admin(auth.uid()));
CREATE POLICY "Admins manage wallets" ON wallets FOR UPDATE USING (is_admin(auth.uid()));

-- DEPOSITS & WITHDRAWALS
CREATE POLICY "Users view own deposits" ON deposits FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own deposits" ON deposits FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage deposits" ON deposits FOR ALL USING (is_admin(auth.uid()));

CREATE POLICY "Users view own withdrawals" ON withdrawals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own withdrawals" ON withdrawals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage withdrawals" ON withdrawals FOR ALL USING (is_admin(auth.uid()));

-- TRANSACTIONS
CREATE POLICY "Users view own transactions" ON transactions FOR SELECT USING (wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid()));
CREATE POLICY "Admins manage transactions" ON transactions FOR ALL USING (is_admin(auth.uid()));

-- CAMPAIGNS
CREATE POLICY "Anyone can view published campaigns" ON campaigns FOR SELECT USING (status = 'published' OR brand_id = auth.uid() OR is_admin(auth.uid()));
CREATE POLICY "Brands can manage own campaigns" ON campaigns FOR ALL USING (brand_id = auth.uid());
CREATE POLICY "Admins can manage all campaigns" ON campaigns FOR ALL USING (is_admin(auth.uid()));

-- APPLICATIONS
CREATE POLICY "Creators view own apps" ON campaign_applications FOR SELECT USING (creator_id = auth.uid() OR is_admin(auth.uid()));
CREATE POLICY "Brands view apps for their campaigns" ON campaign_applications FOR SELECT USING (campaign_id IN (SELECT id FROM campaigns WHERE brand_id = auth.uid()));
CREATE POLICY "Creators apply to campaigns" ON campaign_applications FOR INSERT WITH CHECK (creator_id = auth.uid());

-- DELIVERABLES
CREATE POLICY "Creators view own deliverables" ON deliverables FOR SELECT USING (application_id IN (SELECT id FROM campaign_applications WHERE creator_id = auth.uid()));
CREATE POLICY "Brands view campaign deliverables" ON deliverables FOR SELECT USING (application_id IN (SELECT id FROM campaign_applications WHERE campaign_id IN (SELECT id FROM campaigns WHERE brand_id = auth.uid())));
CREATE POLICY "Admins view all deliverables" ON deliverables FOR ALL USING (is_admin(auth.uid()));

-- SHOP
CREATE POLICY "Public can view active products" ON products FOR SELECT USING (status = 'active' OR seller_id = auth.uid() OR is_admin(auth.uid()));
CREATE POLICY "Sellers manage own products" ON products FOR ALL USING (seller_id = auth.uid());
CREATE POLICY "Admins manage products" ON products FOR ALL USING (is_admin(auth.uid()));

CREATE POLICY "Public view categories" ON product_categories FOR SELECT USING (true);

-- ORDERS
CREATE POLICY "Users view own orders" ON orders FOR SELECT USING (user_id = auth.uid() OR is_admin(auth.uid()));
CREATE POLICY "Users place orders" ON orders FOR INSERT WITH CHECK (user_id = auth.uid());

-- NOTIFICATIONS
CREATE POLICY "Users view own notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Admins manage notifications" ON notifications FOR ALL USING (is_admin(auth.uid()));

-- KYC
CREATE POLICY "Users view own kyc" ON kyc_documents FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users upload kyc" ON kyc_documents FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins manage kyc" ON kyc_documents FOR ALL USING (is_admin(auth.uid()));

-- AUDIT LOGS
CREATE POLICY "Only admins view audit logs" ON audit_logs FOR SELECT USING (is_admin(auth.uid()));
CREATE POLICY "Only admins insert audit logs" ON audit_logs FOR INSERT WITH CHECK (is_admin(auth.uid()));
