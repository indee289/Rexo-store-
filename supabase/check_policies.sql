-- ============================================================
-- CHECK RLS POLICIES FOR ALL TABLES
-- Run this in Supabase SQL Editor to see which tables have policies
-- ============================================================

-- Show all tables and their RLS status + policy count
SELECT 
    t.tablename AS table_name,
    t.rowsecurity AS rls_enabled,
    COUNT(p.policyname) AS policy_count,
    CASE 
        WHEN t.rowsecurity = true AND COUNT(p.policyname) > 0 THEN '✅ OK'
        WHEN t.rowsecurity = true AND COUNT(p.policyname) = 0 THEN '🔴 RLS ON but NO POLICIES (LOCKED!)'
        WHEN t.rowsecurity = false THEN '⚠️ RLS OFF (open access)'
    END AS status
FROM pg_tables t
LEFT JOIN pg_policies p ON p.tablename = t.tablename AND p.schemaname = t.schemaname
WHERE t.schemaname = 'public'
GROUP BY t.tablename, t.rowsecurity
ORDER BY t.tablename;
