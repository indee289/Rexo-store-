-- ============================================================================
-- FIX_PGRST205_permanent.sql
-- Permanent fix for: PGRST205 "Could not find the table 'public.jobs' in the
-- schema cache" (also affects public.job_applications and public.banners).
-- ============================================================================
--
-- HOW TO USE THIS FILE
-- --------------------
-- 1. Open the Supabase Dashboard, then open the SQL Editor.
-- 2. OPTIONAL but recommended: copy and run ONLY Section A (the diagnostics)
--    first. Look at the grants result. You will see that "campaigns" has rows
--    for anon and authenticated, while jobs / job_applications / banners have
--    little or nothing for those roles. THAT missing grant IS the bug.
-- 3. Copy the WHOLE file and click Run once. It is safe to run repeatedly.
-- 4. Wait about 10 seconds so PostgREST can reload its schema cache.
-- 5. In the Flutter app, pull-to-refresh or reopen the Jobs and Banners
--    screens. The PGRST205 error should now be gone.
-- 6. If it STILL fails, run the verification queries in Section E, then follow
--    the Dashboard fallback note at the very bottom of this file.
--
-- WHY DID THE PREVIOUS ATTEMPTS NOT WORK?
-- ---------------------------------------
-- Rebuilding the tables, running NOTIFY, and restarting the project never
-- ADDED the missing table-level GRANTs to the anon and authenticated roles.
-- PostgREST reads your tables AS those roles, so without an explicit GRANT it
-- literally cannot see the tables and reports them as "not found" (PGRST205).
-- The "campaigns" table works only because it happened to inherit Supabase's
-- built-in default privileges when it was first created. The newer tables did
-- not get those grants. This script adds the grants (plus schema USAGE,
-- sequence grants, ownership, and default privileges), so the fix is permanent.
--
-- This script does NOT drop or recreate the tables. Your existing rows are
-- kept. It only re-asserts grants, ownership, RLS, and policies, then reloads.
-- ============================================================================


-- ============================================================================
-- SECTION A - DIAGNOSTICS  (RUN THIS FIRST AND SHARE THE RESULT)
-- ----------------------------------------------------------------------------
-- These three queries reveal WHY jobs/job_applications/banners differ from the
-- working campaigns table. Compare campaigns (works) against the others (fail):
-- campaigns will show anon/authenticated grants and the others will not.
-- ============================================================================

-- A1. Table-level grants for each role. campaigns will have anon/authenticated
--     rows; the broken tables will be missing them.
SELECT table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name IN ('jobs','job_applications','banners','campaigns')
  AND grantee IN ('anon','authenticated','service_role')
ORDER BY table_name, grantee, privilege_type;

-- A2. Table ownership. All four should ideally be owned by postgres.
SELECT tablename, tableowner
FROM pg_tables
WHERE tablename IN ('jobs','job_applications','banners','campaigns')
ORDER BY tablename;

-- A3. Does the anon role have USAGE on the public schema? (must be true)
SELECT nspname, has_schema_privilege('anon', nspname, 'USAGE') AS anon_usage
FROM pg_namespace
WHERE nspname = 'public';


-- ============================================================================
-- SECTION B - THE FIX  (idempotent, safe to re-run)
-- ============================================================================

-- B1. Schema usage: PostgREST roles must be allowed to use the public schema.
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- B2. Table-level grants: the core of the fix. Without these, PostgREST cannot
--     see the tables and returns PGRST205.
GRANT ALL ON TABLE public.jobs             TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.job_applications TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.banners          TO anon, authenticated, service_role;

-- B3. Sequence grants: needed for inserts that use identity/serial defaults.
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- B4. Default privileges: any FUTURE table or sequence created in this schema
--     inherits the same grants, so this problem does not come back.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- B5. Normalize ownership to postgres, matching the working campaigns table.
ALTER TABLE public.jobs             OWNER TO postgres;
ALTER TABLE public.job_applications OWNER TO postgres;
ALTER TABLE public.banners          OWNER TO postgres;


-- ============================================================================
-- SECTION C - DEFENSIVE RLS RE-ASSERTION
-- ----------------------------------------------------------------------------
-- Re-enable RLS and re-assert the campaigns-style policies. DROP POLICY
-- IF EXISTS before each CREATE POLICY makes this safe to run repeatedly and
-- clears any half-applied prior state. Policy bodies are copied verbatim from
-- supabase/jobs_banners_LIKE_CAMPAIGNS.sql. Tables are NOT dropped/recreated.
-- ============================================================================

ALTER TABLE public.jobs             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners          ENABLE ROW LEVEL SECURITY;

-- ─── JOBS POLICIES ───────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Anyone can read active jobs" ON jobs;
CREATE POLICY "Anyone can read active jobs" ON jobs
    FOR SELECT USING (status = 'active' OR created_by = auth.uid() OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Admins can create jobs" ON jobs;
CREATE POLICY "Admins can create jobs" ON jobs
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Admins can update jobs" ON jobs;
CREATE POLICY "Admins can update jobs" ON jobs
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Admins can delete jobs" ON jobs;
CREATE POLICY "Admins can delete jobs" ON jobs
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- ─── JOB APPLICATIONS POLICIES ───────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can read own applications" ON job_applications;
CREATE POLICY "Users can read own applications" ON job_applications
    FOR SELECT USING (auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Users can create own applications" ON job_applications;
CREATE POLICY "Users can create own applications" ON job_applications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own applications" ON job_applications;
CREATE POLICY "Users can update own applications" ON job_applications
    FOR UPDATE USING (
        (auth.uid() = user_id AND status = 'applied') OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Admins can delete applications" ON job_applications;
CREATE POLICY "Admins can delete applications" ON job_applications
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- ─── BANNERS POLICIES ────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Anyone can read visible banners" ON banners;
CREATE POLICY "Anyone can read visible banners" ON banners
    FOR SELECT USING (is_visible = TRUE OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Admins can create banners" ON banners;
CREATE POLICY "Admins can create banners" ON banners
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Admins can update banners" ON banners;
CREATE POLICY "Admins can update banners" ON banners
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Admins can delete banners" ON banners;
CREATE POLICY "Admins can delete banners" ON banners
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );


-- ============================================================================
-- SECTION D - RELOAD POSTGREST
-- ----------------------------------------------------------------------------
-- Tell PostgREST to reload its schema cache and configuration so the new
-- grants take effect immediately.
-- ============================================================================
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';


-- ============================================================================
-- SECTION E - VERIFICATION  (run these after the fix; they are comments only)
-- ----------------------------------------------------------------------------
-- E1. Should each return TRUE now:
--     SELECT has_table_privilege('anon','public.jobs','SELECT');
--     SELECT has_table_privilege('anon','public.job_applications','SELECT');
--     SELECT has_table_privilege('anon','public.banners','SELECT');
--
-- E2. Re-run the Section A grants query and confirm jobs/job_applications/
--     banners now show the same anon/authenticated rows that campaigns has:
--     SELECT table_name, grantee, privilege_type
--     FROM information_schema.role_table_grants
--     WHERE table_name IN ('jobs','job_applications','banners','campaigns')
--       AND grantee IN ('anon','authenticated','service_role')
--     ORDER BY table_name, grantee, privilege_type;
--
-- E3. Confirm the tables are exposed and readable (should not error):
--     SELECT count(*) FROM public.jobs;
--     SELECT count(*) FROM public.banners;
--
-- ----------------------------------------------------------------------------
-- IF PGRST205 STILL PERSISTS AFTER ALL OF THE ABOVE:
--   1. Go to Supabase Dashboard -> Settings -> API and confirm that
--      "Exposed schemas" includes 'public'. If it does not, add it and save.
--   2. As a last resort, use the Dashboard "Restart project" button
--      (Settings -> General -> Restart project) to force a full cache refresh.
-- ============================================================================
