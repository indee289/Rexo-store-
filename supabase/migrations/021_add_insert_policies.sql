-- 021_add_insert_policies.sql
-- Add INSERT policies for users and wallets tables to allow auto-provisioning
-- When a new user signs up via Supabase Auth, the app creates their profile and wallet rows
-- These policies allow authenticated users to insert their own rows only

-- Users can create their own profile row (auth.uid() must match the id being inserted)
CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT WITH CHECK (auth.uid()::text = id);

-- Users can create their own wallet row (auth.uid() must match user_id being inserted)
CREATE POLICY "Users can insert own wallet" ON wallets
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Users can insert their own creator profile
CREATE POLICY "Users can insert own creator profile" ON creator_profiles
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Users can insert their own brand profile
CREATE POLICY "Users can insert own brand profile" ON brand_profiles
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Allow authenticated users to read notifications
CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT USING (auth.uid()::text = user_id);

-- Allow users to update own notifications (mark as read)
CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (auth.uid()::text = user_id);
