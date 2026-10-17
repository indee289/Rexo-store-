-- ============================================================
-- FIX: Platform Settings RLS — Allow ALL authenticated users to read
-- ============================================================
-- PROBLEM: Banners are stored in the `platform_settings` table as a JSON
-- value under key='home_banners'. If the SELECT RLS policy is missing or
-- only grants access to admins, non-admin users see zero banners.
--
-- This script ensures the correct SELECT policy exists so every
-- authenticated user can read platform_settings (including banners).
-- Only admins can write (INSERT/UPDATE/DELETE) — that policy is preserved.
-- ============================================================

-- Enable RLS if not already enabled
ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;

-- Drop the old SELECT policy if it exists (safe to re-run)
DROP POLICY IF EXISTS "Anyone can read platform settings" ON platform_settings;

-- Recreate the SELECT policy: any authenticated user can read ALL rows
CREATE POLICY "Anyone can read platform settings"
  ON platform_settings
  FOR SELECT
  TO authenticated
  USING (true);

-- Ensure the admin write policy exists too (idempotent)
DROP POLICY IF EXISTS "Admins can manage platform settings" ON platform_settings;

CREATE POLICY "Admins can manage platform settings"
  ON platform_settings
  FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users WHERE uid = auth.uid()::text AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE uid = auth.uid()::text AND role = 'admin')
  );

-- ============================================================
-- VERIFICATION: Run this after applying the above to confirm
-- ============================================================
-- SELECT policyname, cmd, qual FROM pg_policies
--   WHERE tablename = 'platform_settings';
--
-- Expected output:
--   "Anyone can read platform settings"    | SELECT | true
--   "Admins can manage platform settings"  | ALL    | (EXISTS ...)
-- ============================================================
