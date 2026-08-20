-- 007_seed_admin.sql
-- Creates a helper function to elevate a user to admin manually via SQL editor
CREATE OR REPLACE FUNCTION promote_to_admin(user_email TEXT)
RETURNS void AS $$
BEGIN
  UPDATE public.users SET role = 'admin' WHERE email = user_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
