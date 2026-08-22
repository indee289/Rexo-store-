-- ============================================================
-- FIX: Auto-create user in public.users on Auth signup
-- Run this AFTER the main schema.sql
-- ============================================================

-- Step 1: Make name nullable (so trigger doesn't fail)
ALTER TABLE public.users ALTER COLUMN name SET DEFAULT '';
ALTER TABLE public.users ALTER COLUMN name DROP NOT NULL;

-- Step 2: Create trigger function to auto-insert user on auth signup
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name, role, account_status)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            split_part(NEW.email, '@', 1)
        ),
        COALESCE(NEW.raw_user_meta_data->>'role', 'creator'),
        'active'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_auth_user();

-- Step 4: Insert users row for the admin (if already signed up)
-- Replace the UUID with actual auth.users id for rexoagency.in@gmail.com
-- You can find it in Supabase Dashboard → Authentication → Users
--
-- INSERT INTO public.users (id, email, name, role, admin_sub_role, is_verified, account_status)
-- SELECT id, email, 'Rexo Admin', 'admin', 'super_admin', true, 'active'
-- FROM auth.users
-- WHERE email = 'rexoagency.in@gmail.com'
-- ON CONFLICT (id) DO UPDATE SET role = 'admin', admin_sub_role = 'super_admin', is_verified = true;

-- Step 5: Auto-fix existing auth users who don't have a public.users row
INSERT INTO public.users (id, email, name, role, account_status)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'full_name', au.raw_user_meta_data->>'name', split_part(au.email, '@', 1)),
    'creator',
    'active'
FROM auth.users au
LEFT JOIN public.users pu ON pu.id = au.id
WHERE pu.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- Step 6: Set admin role for the admin email
UPDATE public.users 
SET role = 'admin', admin_sub_role = 'super_admin', is_verified = true
WHERE email = 'rexoagency.in@gmail.com';

-- Step 7: Create wallets for any users who don't have one
INSERT INTO public.wallets (user_id)
SELECT u.id FROM public.users u
LEFT JOIN public.wallets w ON w.user_id = u.id
WHERE w.id IS NULL;

-- ============================================================
-- VERIFICATION: Run this to check everything is working
-- ============================================================
-- SELECT * FROM public.users;
-- SELECT * FROM public.wallets;
-- Now try creating a new user from Auth → Users → Create User
-- It should automatically create a row in public.users AND public.wallets
