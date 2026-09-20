-- ============================================================================
-- 08_RLS_GLOBAL_CLEANUP.sql
-- Rexo — Remove Dangerous ALL=true Policies
--
-- PURPOSE
--   The live Supabase database contains "Allow all for public" policies on
--   multiple tables. These were created directly in the Supabase Dashboard —
--   they do NOT exist in any repository SQL file. This file replaces each
--   dangerous policy with the least-privilege equivalent.
--
-- TABLES WITH CONFIRMED ALL=true POLICIES
--   From live DB verification:
--     admin_audit_logs         — ALL / true
--     applications             — ALL / true
--     campaign_access_requests — ALL / true
--     campaigns                — ALL / true
--     chat_messages            — ALL / true
--     chat_rooms               — ALL / true
--     config                   — ALL / true (+ SELECT / true — public read)
--     escrows                  — ALL / true
--     notifications            — ALL / true (fixed in 01_RLS_FIXES.sql)
--     post_comments            — ALL / true
--     post_likes               — ALL / true
--     posts                    — ALL / true
--     recovery_admin_notes     — ALL / true
--     recovery_audit_logs      — ALL / true
--     recovery_customer_updates— ALL / true
--     recovery_evidence        — ALL / true
--     recovery_messages        — ALL / true
--     recovery_payments        — ALL / true
--     recovery_requests        — ALL / true
--     reviews                  — ALL / true (has correct policies too)
--     transactions             — ALL / true (0 rows, legacy table)
--     user_follows             — ALL / true
--     users                    — ALL / true (has correct policies too)
--     verification_requests    — ALL / true
--
-- DART USAGE ANALYSIS
--   Of the above tables, the Flutter app ONLY references:
--     applications  — active use (campaigns/jobs)
--     campaigns     — active use
--     notifications — active use (fixed in 01_RLS_FIXES.sql)
--     reviews       — active use
--     users         — active use
--   All others are NOT referenced in the Flutter Dart codebase.
--
-- STRATEGY
--   1. Drop the unsafe "Allow all for public" override policy.
--   2. For Flutter-active tables: correct policies already exist in 01_RLS_FIXES.sql.
--   3. For Flutter-inactive tables: drop ALL=true and add least-privilege fallback.
--   4. For recovery_ tables: restrict to authenticated admin access only.
--   5. For legacy tables (transactions, escrows): secure, do not delete.
--   6. For config: preserve SELECT public read, remove ALL write access.
--
-- IDEMPOTENCY
--   DROP POLICY IF EXISTS + CREATE POLICY. Safe to run multiple times.
--
-- DEPENDENCIES
--   01_RLS_FIXES.sql must run first (defines public.is_admin()).
--
-- WARNING
--   Some tables listed below (admin_audit_logs, campaign_access_requests,
--   chat_rooms, chat_messages, posts, etc.) are NOT in this repository's
--   schema.sql. They were created directly in the Supabase Dashboard.
--   This file secures them with safe minimal policies but does NOT define
--   their schemas. If any table does not exist when this runs, the
--   DROP POLICY / CREATE POLICY statements will fail gracefully (IF EXISTS).
--   Wrap in DO $$ BEGIN ... EXCEPTION WHEN OTHERS THEN NULL; END $$;
--   if you want silent skipping for tables that don't exist.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- HELPER: safe policy apply (skips if table doesn't exist)
-- ─────────────────────────────────────────────────────────────────────────────

-- We use DO blocks with EXCEPTION handlers for tables that may not exist.
-- Tables confirmed to exist (from live DB): applications, campaigns, reviews,
-- users, notifications, transactions, escrows, config, user_follows.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. APPLICATIONS — Drop ALL=true override
--    Correct policies already defined in 01_RLS_FIXES.sql (creator UPDATE + admin).
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Allow all for public applications" ON public.applications;
DROP POLICY IF EXISTS "Public applications access" ON public.applications;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CAMPAIGNS — Drop ALL=true override
--    Correct policies exist in schema.sql (anyone read active, brands create/update,
--    admins manage). These are the correct policies.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Allow all for public campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Public campaigns access" ON public.campaigns;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. USERS — Drop ALL=true override
--    Correct policies exist in 01_RLS_FIXES.sql and schema.sql.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Allow all for public users" ON public.users;
DROP POLICY IF EXISTS "Public users access" ON public.users;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. NOTIFICATIONS — Drop ALL=true override
--    Correct INSERT policy already fixed in 01_RLS_FIXES.sql.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Allow all for public notifications" ON public.notifications;
DROP POLICY IF EXISTS "Public notifications access" ON public.notifications;


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. REVIEWS — Drop ALL=true override
--    Correct per-user + admin policies exist in schema.sql.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Allow all for public reviews" ON public.reviews;
DROP POLICY IF EXISTS "Public reviews access" ON public.reviews;


-- ─────────────────────────────────────────────────────────────────────────────
-- 6. TRANSACTIONS (live table, 0 rows, legacy/unused by Flutter)
--    Remove ALL=true. Add least-privilege: users read own, admins manage all.
--    Column naming uses live schema: userId (text), createdAt (timestamptz).
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='transactions') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public transactions" ON public.transactions$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public transactions access" ON public.transactions$p$;
        EXECUTE $p$
            CREATE POLICY "Users can view own transactions" ON public.transactions
                FOR SELECT USING (auth.uid()::text = "userId"::text)$p$;
        EXECUTE $p$
            CREATE POLICY "Admins can manage transactions" ON public.transactions
                FOR ALL
                USING (public.is_admin())
                WITH CHECK (public.is_admin())$p$;
        RAISE NOTICE 'transactions: dangerous policy removed, secure policies applied';
    ELSE
        RAISE NOTICE 'transactions table does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 7. ESCROWS (live table, Flutter does NOT use it directly)
--    Remove ALL=true. Preserve the 4 correct policies that already exist
--    (view for involved users, insert for brands/admins, update for admin/involved,
--    delete for admins). Only drop the unsafe one.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='escrows') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public escrows" ON public.escrows$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public escrows access" ON public.escrows$p$;
        RAISE NOTICE 'escrows: dangerous ALL=true policy removed';
    ELSE
        RAISE NOTICE 'escrows table does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 8. CONFIG (live table, Flutter does NOT use it)
--    Has ALL=true AND SELECT=true (public read). 
--    Action: drop ALL=true. Preserve SELECT=true only (config is intended public).
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='config') THEN
        -- Drop the dangerous ALL override
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public config" ON public.config$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public config access" ON public.config$p$;
        -- Ensure SELECT is still available for public (config is intentionally public read)
        EXECUTE $p$DROP POLICY IF EXISTS "Anyone can read config" ON public.config$p$;
        EXECUTE $p$
            CREATE POLICY "Anyone can read config" ON public.config
                FOR SELECT USING (true)$p$;
        -- Admins only for write operations
        EXECUTE $p$DROP POLICY IF EXISTS "Admins can manage config" ON public.config$p$;
        EXECUTE $p$
            CREATE POLICY "Admins can manage config" ON public.config
                FOR ALL
                USING (public.is_admin())
                WITH CHECK (public.is_admin())$p$;
        RAISE NOTICE 'config: ALL=true removed, SELECT=public + admin write applied';
    ELSE
        RAISE NOTICE 'config table does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 9. USER_FOLLOWS (live table, NOT in repo schema.sql, Flutter does NOT use it)
--    Drop ALL=true. Add safe authenticated-only follow policies.
--
--    LIVE SCHEMA (verified against production DB):
--      id            uuid
--      follower_uid  text          -- the user doing the following
--      following_uid text          -- the user being followed
--      created_at    timestamptz
--    Column identity is matched against auth.uid()::text (text UIDs).
--
--    NOTE: The Flutter app does NOT reference user_follows. It uses a
--    SEPARATE `follows` table (follower_id / following_id). This block only
--    secures the live user_follows table's dangerous ALL=true policy.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='user_follows') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public user_follows" ON public.user_follows$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public user_follows access" ON public.user_follows$p$;
        -- Authenticated read (needed for follower count displays)
        EXECUTE $p$DROP POLICY IF EXISTS "Authenticated users can read follows" ON public.user_follows$p$;
        EXECUTE $p$
            CREATE POLICY "Authenticated users can read follows" ON public.user_follows
                FOR SELECT USING (auth.role() = 'authenticated')$p$;
        -- Users can only follow/unfollow as themselves (identity via follower_uid).
        EXECUTE $p$DROP POLICY IF EXISTS "Users can manage own follows" ON public.user_follows$p$;
        EXECUTE $p$
            CREATE POLICY "Users can manage own follows" ON public.user_follows
                FOR ALL
                USING (auth.uid()::text = follower_uid OR auth.uid()::text = following_uid)
                WITH CHECK (auth.uid()::text = follower_uid)$p$;
        RAISE NOTICE 'user_follows: dangerous policy removed, secure policies applied';
    ELSE
        RAISE NOTICE 'user_follows table does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 10. CHAT_MESSAGES, CHAT_ROOMS (live, NOT in repo schema.sql, Flutter DOESN'T use)
--     Drop ALL=true. Add authenticated participant-only access.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    -- chat_rooms
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='chat_rooms') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public chat_rooms" ON public.chat_rooms$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public chat_rooms access" ON public.chat_rooms$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Authenticated room access" ON public.chat_rooms$p$;
        EXECUTE $p$
            CREATE POLICY "Authenticated room access" ON public.chat_rooms
                FOR SELECT USING (auth.role() = 'authenticated')$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Admins can manage chat rooms" ON public.chat_rooms$p$;
        EXECUTE $p$
            CREATE POLICY "Admins can manage chat rooms" ON public.chat_rooms
                FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())$p$;
        RAISE NOTICE 'chat_rooms: dangerous policy removed';
    END IF;
    -- chat_messages
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='chat_messages') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public chat_messages" ON public.chat_messages$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public chat_messages access" ON public.chat_messages$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Authenticated message access" ON public.chat_messages$p$;
        EXECUTE $p$
            CREATE POLICY "Authenticated message access" ON public.chat_messages
                FOR SELECT USING (auth.role() = 'authenticated')$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Admins can manage chat messages" ON public.chat_messages$p$;
        EXECUTE $p$
            CREATE POLICY "Admins can manage chat messages" ON public.chat_messages
                FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())$p$;
        RAISE NOTICE 'chat_messages: dangerous policy removed';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 11. POSTS, POST_COMMENTS, POST_LIKES (live, NOT in repo schema.sql, Flutter unused)
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['posts', 'post_comments', 'post_likes'] LOOP
        IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename=t) THEN
            EXECUTE format('DROP POLICY IF EXISTS "Allow all for public %I" ON public.%I', t, t);
            EXECUTE format('DROP POLICY IF EXISTS "Public %I access" ON public.%I', t, t);
            -- Authenticated read only; admins manage
            EXECUTE format('DROP POLICY IF EXISTS "Authenticated %I read" ON public.%I', t, t);
            EXECUTE format('CREATE POLICY "Authenticated %I read" ON public.%I
                FOR SELECT USING (auth.role() = ''authenticated'')', t, t);
            EXECUTE format('DROP POLICY IF EXISTS "Admins manage %I" ON public.%I', t, t);
            EXECUTE format('CREATE POLICY "Admins manage %I" ON public.%I
                FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())', t, t);
            RAISE NOTICE '%: dangerous policy removed', t;
        ELSE
            RAISE NOTICE '% does not exist — skipped', t;
        END IF;
    END LOOP;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 12. RECOVERY_* TABLES (live, NOT in repo schema.sql, NOT in admin_app, Flutter unused)
--     These are an INDEPENDENT subsystem — possibly a third-party integration
--     or separate admin tool. Flutter does not reference them at all.
--     Action: Remove ALL=true. Restrict to authenticated admin access only.
--     This preserves the tables' data and functionality while closing the
--     public access hole. If a separate recovery system needs its own auth,
--     the policies here can be adjusted by whoever owns that system.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'recovery_requests', 'recovery_messages', 'recovery_evidence',
        'recovery_customer_updates', 'recovery_admin_notes',
        'recovery_audit_logs', 'recovery_payments'
    ] LOOP
        IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename=t) THEN
            EXECUTE format('DROP POLICY IF EXISTS "Allow all for public %I" ON public.%I', t, t);
            EXECUTE format('DROP POLICY IF EXISTS "Public %I access" ON public.%I', t, t);
            -- Admin-only access (recovery system is internal)
            EXECUTE format('DROP POLICY IF EXISTS "Admin only %I" ON public.%I', t, t);
            EXECUTE format('CREATE POLICY "Admin only %I" ON public.%I
                FOR ALL
                USING (public.is_admin())
                WITH CHECK (public.is_admin())', t, t);
            RAISE NOTICE '%: restricted to admin-only access', t;
        ELSE
            RAISE NOTICE '% does not exist — skipped', t;
        END IF;
    END LOOP;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 13a. CAMPAIGN_ACCESS_REQUESTS
--    LIVE SCHEMA (verified): id uuid, "brandId" text, "brandName" text,
--    status text, "createdAt" timestamptz.
--    There is NO per-user / creator ownership column on this table — it is keyed
--    by brand, and there is no column that maps a row to the authenticated
--    end-user requesting access. Because ownership cannot be expressed safely,
--    this table is secured as ADMIN-ONLY management. Removing the ALL=true
--    override closes the public hole; admins retain full access to process
--    requests. (If a per-user ownership column is added later, add a
--    user-scoped policy at that time.)
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='campaign_access_requests') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public campaign_access_requests" ON public.campaign_access_requests$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public campaign_access_requests access" ON public.campaign_access_requests$p$;
        -- No ownership column exists → admin-only management.
        EXECUTE $p$DROP POLICY IF EXISTS "Admins manage campaign_access_requests" ON public.campaign_access_requests$p$;
        EXECUTE $p$
            CREATE POLICY "Admins manage campaign_access_requests" ON public.campaign_access_requests
                FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())$p$;
        RAISE NOTICE 'campaign_access_requests: dangerous policy removed, admin-only access applied (no ownership column exists)';
    ELSE
        RAISE NOTICE 'campaign_access_requests table does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 13b. VERIFICATION_REQUESTS
--    LIVE SCHEMA (verified): id uuid, "creatorId" text, "creatorName" text,
--    "creatorEmail" text, "proofLink" text, status text, "createdAt" timestamptz.
--    Ownership is the "creatorId" column (text UID). A creator may create and
--    read their own request; admins manage all.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='verification_requests') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public verification_requests" ON public.verification_requests$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public verification_requests access" ON public.verification_requests$p$;
        -- Creators can read + create their own verification requests.
        EXECUTE $p$DROP POLICY IF EXISTS "Creators read own verification_requests" ON public.verification_requests$p$;
        EXECUTE $p$
            CREATE POLICY "Creators read own verification_requests" ON public.verification_requests
                FOR SELECT USING (auth.uid()::text = "creatorId"::text)$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Creators create own verification_requests" ON public.verification_requests$p$;
        EXECUTE $p$
            CREATE POLICY "Creators create own verification_requests" ON public.verification_requests
                FOR INSERT WITH CHECK (auth.uid()::text = "creatorId"::text)$p$;
        -- Admins manage all.
        EXECUTE $p$DROP POLICY IF EXISTS "Admins manage verification_requests" ON public.verification_requests$p$;
        EXECUTE $p$
            CREATE POLICY "Admins manage verification_requests" ON public.verification_requests
                FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())$p$;
        RAISE NOTICE 'verification_requests: dangerous policy removed, creator-owned + admin policies applied';
    ELSE
        RAISE NOTICE 'verification_requests table does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 13c. ADMIN_AUDIT_LOGS — admin read/write only.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='admin_audit_logs') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public admin_audit_logs" ON public.admin_audit_logs$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public admin_audit_logs access" ON public.admin_audit_logs$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Admins manage admin_audit_logs" ON public.admin_audit_logs$p$;
        EXECUTE $p$
            CREATE POLICY "Admins manage admin_audit_logs" ON public.admin_audit_logs
                FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())$p$;
        RAISE NOTICE 'admin_audit_logs: dangerous policy removed, admin-only access applied';
    ELSE
        RAISE NOTICE 'admin_audit_logs table does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- FINAL: Global scan query — run to verify no ALL=true remain
-- ─────────────────────────────────────────────────────────────────────────────
-- Run this after applying the file to confirm cleanup:
--
-- SELECT tablename, policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE schemaname = 'public'
--   AND (
--       lower(coalesce(qual, '')) = 'true'
--       OR lower(coalesce(with_check, '')) = 'true'
--   )
-- ORDER BY tablename, policyname;
--
-- EXPECTED REMAINING true policies (intentional):
--   config — SELECT / true        (public config read is intentional)
--   Any other table should have ZERO remaining true policies.
--   NOTE: user_follows read is scoped to authenticated users
--   (auth.role() = 'authenticated'), NOT a bare true, so it will not appear
--   in the scan above.
