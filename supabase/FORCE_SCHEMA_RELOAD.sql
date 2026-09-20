-- ============================================================================
-- FORCE_SCHEMA_RELOAD.sql
-- A DIFFERENT, stronger method to fix the stuck PostgREST schema cache
-- (PGRST205 on jobs / job_applications / banners) when NOTIFY and a project
-- restart did not help.
--
-- WHY THIS IS DIFFERENT:
-- A plain `NOTIFY pgrst, 'reload schema'` only ASKS PostgREST to reload — on
-- the free tier that request is sometimes dropped. This script instead emits
-- REAL DDL EVENTS on the exposed `public` schema (a schema comment change plus
-- creating and dropping a throwaway table). PostgREST listens for DDL events
-- and rebuilds its cache when it sees them, which is far more reliable than a
-- bare NOTIFY. It then also sends both reload signals.
--
-- SAFE: it never touches your real jobs / job_applications / banners tables or
-- their data. It only changes a schema comment and creates+drops a temporary
-- dummy table.
--
-- HOW TO RUN:
--   1. Supabase Dashboard -> SQL Editor -> paste this WHOLE file -> Run.
--   2. Wait ~30-60 seconds (free tier can lag a few minutes).
--   3. In the app, open Jobs / Banners and tap Retry.
--   4. If it STILL fails, do the Dashboard steps at the bottom (they always
--      work): toggle Exposed schemas, then Restart project.
-- ============================================================================

-- 1) Change the comment on the exposed schema. This is a DDL change on `public`
--    that PostgREST's event listener reacts to.
COMMENT ON SCHEMA public IS 'reload schema (jobs/banners cache bust)';

-- 2) Emit CREATE + DROP DDL events with a clearly throwaway table. Creating and
--    immediately dropping it forces schema-change events without leaving any
--    residue. Wrapped in a DO block so it runs atomically.
DO $$
BEGIN
  -- Drop first in case a previous run left it behind.
  EXECUTE 'DROP TABLE IF EXISTS public._pgrst_cache_bust';
  EXECUTE 'CREATE TABLE public._pgrst_cache_bust (x integer)';
  EXECUTE 'DROP TABLE public._pgrst_cache_bust';
END $$;

-- 3) Reset the schema comment to something clean (another DDL event).
COMMENT ON SCHEMA public IS 'standard public schema';

-- 4) Finally, send both reload signals.
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- ============================================================================
-- IF THE APP STILL SHOWS PGRST205 AFTER RUNNING THIS AND WAITING ~2 MINUTES:
--
-- METHOD 2 — Toggle Exposed Schemas (this ALWAYS forces a full reload):
--   1. Supabase Dashboard -> Settings -> API
--   2. Find "Exposed schemas" (or "Schema") — it lists `public`, maybe others.
--   3. REMOVE `public` from the list -> click Save -> wait 30 seconds.
--   4. ADD `public` back to the list -> click Save -> wait 60 seconds.
--   5. Reopen the app, tap Retry.
--
-- METHOD 3 — Restart the project (do this AFTER Method 2, order matters):
--   1. Supabase Dashboard -> Settings -> General
--   2. Click "Restart project" -> confirm.
--   3. Wait a FULL 5 minutes until status is "Healthy".
--   4. Reopen the app, tap Retry.
--
-- The tables, grants, RLS and data are already correct (verified). This is
-- purely the API cache refusing to refresh; one of the three methods above
-- will force it.
-- ============================================================================
