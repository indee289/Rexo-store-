-- 008_views.sql
CREATE VIEW admin_dashboard_stats AS
SELECT
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM campaigns WHERE status = 'published') as active_campaigns,
    (SELECT COUNT(*) FROM deposits WHERE status = 'pending') as pending_deposits,
    (SELECT COUNT(*) FROM withdrawals WHERE status = 'pending') as pending_withdrawals,
    (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE status = 'delivered') as total_shop_revenue;
