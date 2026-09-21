-- Seed subscription plans for Rexo Store
-- These UUIDs must match any hardcoded references in the client apps.
-- Run this after schema.sql to populate the subscription_plans table.
--
-- UPDATED: Now populates both interval and duration_days for compatibility
-- - interval: Used for display and compatibility (TEXT)
-- - duration_days: Primary field for application logic (INTEGER)

INSERT INTO public.subscription_plans (id, name, price, interval, duration_days, features) VALUES
  ('a1b2c3d4-0001-4000-8000-000000000001', 'Free', 0, 'month', 30, '["Basic features", "5 campaign applications/month", "Standard support"]'),
  ('a1b2c3d4-0002-4000-8000-000000000002', 'Pro', 299, 'month', 30, '["Unlimited applications", "Priority listing", "Analytics dashboard", "Email support"]'),
  ('a1b2c3d4-0003-4000-8000-000000000003', 'Ultra', 599, 'month', 30, '["Everything in Pro", "Verified badge", "Featured placement", "Priority support"]'),
  ('a1b2c3d4-0004-4000-8000-000000000004', 'Premium Max', 999, 'month', 30, '["Everything in Ultra", "Dedicated manager", "Custom media kit", "Priority payouts"]')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  interval = EXCLUDED.interval,
  duration_days = EXCLUDED.duration_days,
  features = EXCLUDED.features;
