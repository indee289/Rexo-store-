-- ============================================================================
-- DIAGNOSTIC — Jobs / Job Applications / Banners feature full health check
-- Run EACH query below one-by-one in Supabase SQL Editor and share the result
-- of each. This tells us exactly what exists and what is missing/broken.
-- ============================================================================


-- ── 1. Do the 3 tables exist? ────────────────────────────────────────────────
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('jobs','job_applications','banners')
ORDER BY table_name;
-- EXPECT: 3 rows (banners, job_applications, jobs)


-- ── 2. Columns + types of each table ─────────────────────────────────────────
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('jobs','job_applications','banners')
ORDER BY table_name, ordinal_position;
-- Look for: jobs.id(uuid), job_applications.user_id(text), job_applications.job_id(uuid),
--           banners.id(uuid). Note any column the app expects but is missing.


-- ── 3. RLS enabled on the 3 tables? ──────────────────────────────────────────
SELECT relname AS table_name, relrowsecurity AS rls_enabled
FROM pg_class
WHERE relname IN ('jobs','job_applications','banners');
-- EXPECT: rls_enabled = true for all 3


-- ── 4. All policies on the 3 tables ──────────────────────────────────────────
SELECT tablename, policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('jobs','job_applications','banners')
ORDER BY tablename, cmd;
-- EXPECT: 8 rows (2 jobs, 4 job_applications, 2 banners)


-- ── 5. All RPC functions for this feature ────────────────────────────────────
SELECT routine_name, data_type AS returns, security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'get_active_jobs','get_jobs','get_job_by_id','get_job_applications',
    'get_submitted_applications','get_job_applicant_count','get_job_slot_count',
    'has_applied_to_job','get_banners','get_all_banners',
    'apply_to_job','submit_job_task','create_job','update_job','delete_job',
    'get_application_core','update_application_status',
    'create_banner','update_banner','delete_banner','is_admin'
  )
ORDER BY routine_name;
-- EXPECT: 21 rows, all security_type = DEFINER


-- ── 6. Function argument signatures (to confirm param names/types) ───────────
SELECT p.proname AS function_name,
       pg_get_function_arguments(p.oid) AS arguments,
       pg_get_function_result(p.oid) AS returns
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'get_active_jobs','get_job_applications','get_banners','get_all_banners',
    'get_submitted_applications','has_applied_to_job','get_job_by_id',
    'get_job_slot_count','get_job_applicant_count','is_admin'
  )
ORDER BY p.proname;
-- Confirms exact arg names: get_active_jobs(p_category text, p_search text) etc.


-- ── 7. EXECUTE grants to 'authenticated' ─────────────────────────────────────
SELECT routine_name, grantee, privilege_type
FROM information_schema.routine_privileges
WHERE routine_schema = 'public'
  AND grantee = 'authenticated'
  AND routine_name IN (
    'get_active_jobs','get_jobs','get_job_applications','get_banners',
    'get_all_banners','get_submitted_applications','apply_to_job','create_job',
    'is_admin'
  )
ORDER BY routine_name;
-- EXPECT: every function listed with privilege_type = EXECUTE


-- ── 8. Does is_admin() exist and what does it compare? ───────────────────────
SELECT pg_get_functiondef(p.oid) AS is_admin_definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'is_admin';
-- Confirms is_admin() body (should compare users.id::text = auth.uid()::text)


-- ── 9. Actually TEST the read RPCs (these run as postgres, so is_admin()=false,
--       but get_active_jobs / get_banners have no admin gate and must return rows
--       or at least NOT error) ───────────────────────────────────────────────
SELECT * FROM public.get_active_jobs(NULL, NULL);
-- EXPECT: your posted active jobs (or 0 rows if none) — but NO error.

SELECT * FROM public.get_banners();
-- EXPECT: visible banners (or 0 rows) — but NO error.


-- ── 10. How many rows actually exist in each table? ──────────────────────────
SELECT 'jobs' AS tbl, count(*) FROM public.jobs
UNION ALL
SELECT 'job_applications', count(*) FROM public.job_applications
UNION ALL
SELECT 'banners', count(*) FROM public.banners;
-- Tells us whether there is real data to show.


-- ── 11. Column mismatch check — app writes submission_url; does it exist? ────
SELECT column_name
FROM information_schema.columns
WHERE table_schema='public' AND table_name='job_applications'
  AND column_name IN ('submission_url','submission_proof','submission_type','submission_note');
-- EXPECT: submission_url present (app uses it).
