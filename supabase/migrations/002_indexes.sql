-- 002_indexes.sql
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_wallets_user_id ON wallets(user_id);
CREATE INDEX idx_transactions_wallet_id ON transactions(wallet_id);
CREATE INDEX idx_deposits_user_id ON deposits(user_id);
CREATE INDEX idx_withdrawals_user_id ON withdrawals(user_id);
CREATE INDEX idx_campaigns_brand_id ON campaigns(brand_id);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_applications_campaign_creator ON campaign_applications(campaign_id, creator_id);
CREATE INDEX idx_products_seller_id ON products(seller_id);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_notifications_user_id_read ON notifications(user_id, is_read);
CREATE INDEX idx_audit_logs_admin_id ON audit_logs(admin_id);
