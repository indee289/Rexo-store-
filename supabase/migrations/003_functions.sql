-- 003_functions.sql
-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Sync auth.users to public.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    new.id,
    new.email,
    raw_user_meta_data->>'name',
    COALESCE((raw_user_meta_data->>'role')::user_role, 'customer'::user_role)
  );
  -- Auto create wallet
  INSERT INTO public.wallets (user_id) VALUES (new.id);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Is Admin Check Function
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  is_adm BOOLEAN;
BEGIN
  SELECT (role = 'admin') INTO is_adm FROM public.users WHERE id = user_id;
  RETURN COALESCE(is_adm, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
