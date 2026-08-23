-- ============================================================
-- FIX: Infinite recursion in RLS policies on "users" table
-- ============================================================
-- 
-- Problem: The original RLS policies on the "users" table contained
-- subqueries that SELECT from the "users" table itself:
--
--   EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
--
-- This causes PostgreSQL error 42P17:
--   "infinite recursion detected in policy for relation users"
--
-- The fix removes the recursive admin-check policies and replaces them
-- with policies that use auth.uid() and auth.jwt() claims instead.
--
-- Run this file directly against your live Supabase database to fix
-- the issue without re-running the full schema.sql.
-- ============================================================

-- Step 1: Drop ALL existing policies on the users table
DROP POLICY IF EXISTS "Authenticated users can read all profiles" ON users;
DROP POLICY IF EXISTS "Admins can read all users" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Admins can update any user" ON users;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON users;
DROP POLICY IF EXISTS "Service role can delete users" ON users;

-- Step 2: Recreate policies WITHOUT self-referencing subqueries
-- IMPORTANT: Policies on the users table must NEVER subquery the users table itself.

-- Any authenticated user can read profiles (needed for cross-user joins, public data)
CREATE POLICY "Authenticated users can read all profiles" ON users
    FOR SELECT USING (auth.role() = 'authenticated');

-- Users can update their own data
CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Admins can update any user - use JWT metadata claim to avoid recursion
CREATE POLICY "Admins can update any user" ON users
    FOR UPDATE USING (
        (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
        OR auth.uid() = id
    );

-- Allow insert for authenticated users (own row only, for signup flow)
CREATE POLICY "Allow insert for authenticated users" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow delete for service role only (admin operations via server-side)
CREATE POLICY "Service role can delete users" ON users
    FOR DELETE USING (auth.role() = 'service_role');

-- ============================================================
-- VERIFICATION: After running this, test by querying the users table
-- as an authenticated user. The infinite recursion error should be gone.
-- ============================================================
