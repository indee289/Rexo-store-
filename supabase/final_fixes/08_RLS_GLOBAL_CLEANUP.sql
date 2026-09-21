-- ============================================================================
-- 08_RLS_GLOBAL_CLEANUP.sql
-- Rexo — Remove Dangerous ALL=true Policies
--
-- PURPOSE
--   The live Supabase database contains "Allow all for public" ALL/true
--   policies on multiple tables. These were created directly in the Supabase
--   Dashboard. This file replaces each dangerous policy with the correct
--   least-privilege equivalent.
--
-- LIVE DEPLOYMENT STATE (confirmed September 2026 after partial run)
--   The file previously failed mid-run because:
--     1. §6 transactions: "Users can view own transactions" already existed —
--        now fixed by explicit DROP before CREATE inside the DO block.
--     2. §13 (old): campaign_access_requests / verification_requests used a
--        nonexistent user_id column — now fixed with correct column names.
--   All sections now use DROP POLICY IF EXISTS immediately before every
--   CREATE POLICY, making the entire file safely idempotent.
--
-- LIVE POLICY NAMES CONFIRMED (partial-run audit)
--   applications has THREE dangerous override names (all must be dropped):
--     "Allow all applications"
--     "Allow all for applications"
--     "Allow all for public applications"
--   campaigns has TWO dangerous override names:
--     "Allow all for campaigns"
--     "Allow all for public campaigns"
--   reviews:    "Allow all for public reviews"
--   notifications: "Allow all for public notifications"
--   transactions:  "Allow all for public transactions"
--   users:         "Allow all for public users"
--
-- STRATEGY
--   1. Drop ALL dangerous "Allow all" override policies by their confirmed names.
--   2. Flutter-active tables (applications, campaigns, notifications, reviews,
--      users): correct policies already exist in schema.sql and 01_RLS_FIXES.sql.
--      This file only drops the override. It does NOT recreate policies that
--      already exist.
--   3. Flutter-inactive tables (transactions, escrows, config, user_follows,
--      chat_*, posts, post_comments, post_likes, campaign_access_requests,
--      verification_requests, admin_audit_logs): drop ALL=true and add
--      least-privilege fallbacks.
--   4. recovery_* tables: DO NOT TOUCH. These belong to an independent
--      subsystem whose access model has not been confirmed.
--   5. config: preserve the intentional SELECT/true public read policy.
--      Only remove ALL=true write access.
--
-- CONFIRMED LIVE users SCHEMA NOTE
--   Live public.users uses uid (text) as the RLS identity column — NOT id.
--   Any policy referencing users ownership uses uid = auth.uid()::text.
--
-- CONFIRMED LIVE notifications SCHEMA NOTE
--   Ownership column is "userId" (text, camelCase). RLS expressions use
--   auth.uid()::text = "userId"::text.
--
-- CONFIRMED LIVE transactions SCHEMA NOTE
--   Ownership column is "userId" (text, camelCase). The existing
--   "Users can view own transactions" policy already uses the correct
--   expression. We DROP + recreate it to guarantee the correct definition
--   is in place regardless of prior partial-run state.
--
-- IDEMPOTENCY
--   Every CREATE POLICY is preceded by DROP POLICY IF EXISTS.
--   All sensitive blocks use IF EXISTS guards on the table itself.
--   Safe to run multiple times.
--
-- DEPENDENCIES
--   01_RLS_FIXES.sql must run first (defines public.is_admin()).
--
-- DO NOT RUN AGAINST PRODUCTION UNTIL:
--   - 01_RLS_FIXES.sql has been successfully applied.
--   - The dangerous policy names above have been confirmed against live DB.
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- 1. APPLICATIONS — Drop ALL dangerous override policies
--    THREE confirmed policy names in the live DB (all must be dropped).
--    Correct policies already exist in schema.sql and 01_RLS_FIXES.sql.
--    This section drops only the overrides. No new policies are created here.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Allow all applications"            ON public.applications;
DROP POLICY IF EXISTS "Allow all for applications"        ON public.applications;
DROP POLICY IF EXISTS "Allow all for public applications" ON public.applications;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CAMPAIGNS — Drop ALL dangerous override policies
--    TWO confirmed policy names in the live DB.
--    Correct policies already exist in schema.sql.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Allow all for campaigns"        ON public.campaigns;
DROP POLICY IF EXISTS "Allow all for public campaigns" ON public.campaigns;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. USERS — Drop the dangerous ALL=true override.
--    Correct policies already exist in the live DB:
--      "Anyone can view users"         SELECT  hidden=false OR uid=auth.uid()...
--      "Users can insert own profile"  INSERT
--      "Users can update own profile"  UPDATE  uid=auth.uid()::text OR is_admin()
--      "Users or Admin can delete..."  DELETE
--    These are legitimate and must NOT be touched.
--    The self-escalation trigger (01_RLS_FIXES.sql §D2) closes the update gap.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Allow all for public users" ON public.users;
DROP POLICY IF EXISTS "Public users access"        ON public.users;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. NOTIFICATIONS — Drop the dangerous ALL=true override.
--    Live DB already has correct per-user SELECT/UPDATE/DELETE policies.
--    01_RLS_FIXES.sql §B adds the user-scoped INSERT policy.
--    The existing "Admins/system can insert notifications" (no WITH CHECK)
--    is intentionally preserved — it covers service-role and admin inserts.
--    Only the dangerous "Allow all for public notifications" is dropped here.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Allow all for public notifications" ON public.notifications;
DROP POLICY IF EXISTS "Public notifications access"        ON public.notifications;


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. REVIEWS — Drop the dangerous ALL=true override.
--    Correct per-user + admin policies exist in schema.sql.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Allow all for public reviews" ON public.reviews;
DROP POLICY IF EXISTS "Public reviews access"        ON public.reviews;


-- ─────────────────────────────────────────────────────────────────────────────
-- 6. TRANSACTIONS (live table, 0 rows, legacy/unused by Flutter)
--
--    CONFIRMED LIVE SCHEMA:
--      id       uuid
--      "userId" text NOT NULL   ← ownership column (camelCase, quoted in SQL)
--      amount   numeric
--      type     text
--      status   text  DEFAULT 'Pending'
--      "createdAt" timestamptz
--
--    CONFIRMED LIVE POLICIES THAT ALREADY EXIST:
--      "Admins can delete transactions"      DELETE  is_admin()
--      "Admins can update transactions"      UPDATE  is_admin()
--      "Admins/system can insert transactions" INSERT (no WITH CHECK)
--      "Allow all for public transactions"   ALL     true   ← DROP THIS
--      "Users can view own transactions"     SELECT  "userId"=auth.uid()::text OR is_admin()
--
--    ACTION:
--      - Drop the dangerous "Allow all for public transactions".
--      - DROP + recreate "Users can view own transactions" to guarantee the
--        correct column expression is set, regardless of partial-run state.
--      - Do NOT add "Admins can manage transactions" ALL policy — the three
--        granular admin policies (INSERT/UPDATE/DELETE) already exist and
--        must remain. Adding an ALL policy on top would be redundant.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='transactions') THEN

        -- Remove the dangerous public ALL policy
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public transactions" ON public.transactions$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public transactions access"        ON public.transactions$p$;

        -- Refresh "Users can view own transactions" with the confirmed correct
        -- column expression. DROP first to handle prior partial-run state.
        EXECUTE $p$DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions$p$;
        EXECUTE $p$
            CREATE POLICY "Users can view own transactions" ON public.transactions
                FOR SELECT
                USING (auth.uid()::text = "userId"::text OR public.is_admin())
        $p$;

        RAISE NOTICE 'transactions: dangerous ALL policy removed, user view policy confirmed';
    ELSE
        RAISE NOTICE 'transactions: table does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 7. ESCROWS (live table, Flutter does NOT use it directly)
--    Drop the dangerous ALL=true override only.
--    The existing 4 correct policies (view/insert/update/delete) are preserved.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='escrows') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public escrows" ON public.escrows$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public escrows access"        ON public.escrows$p$;
        RAISE NOTICE 'escrows: dangerous ALL policy removed';
    ELSE
        RAISE NOTICE 'escrows: table does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 8. CONFIG (live table, public read is intentional)
--    The existing SELECT/true policy is INTENTIONALLY PUBLIC — config data is
--    designed to be readable by anyone. Do NOT remove it.
--    Only the dangerous ALL=true write override is dropped.
--    An admin-only write policy is added.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='config') THEN
        -- Drop ALL=true write override only
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public config" ON public.config$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public config access"        ON public.config$p$;

        -- Ensure public SELECT remains (intentional)
        EXECUTE $p$DROP POLICY IF EXISTS "Anyone can read config" ON public.config$p$;
        EXECUTE $p$
            CREATE POLICY "Anyone can read config" ON public.config
                FOR SELECT USING (true)
        $p$;

        -- Admin-only write
        EXECUTE $p$DROP POLICY IF EXISTS "Admins can manage config" ON public.config$p$;
        EXECUTE $p$
            CREATE POLICY "Admins can manage config" ON public.config
                FOR ALL
                USING (public.is_admin())
                WITH CHECK (public.is_admin())
        $p$;

        RAISE NOTICE 'config: ALL write removed, public SELECT preserved, admin write added';
    ELSE
        RAISE NOTICE 'config: table does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 9. USER_FOLLOWS (live table, Flutter does NOT use it)
--    CONFIRMED LIVE SCHEMA:
--      id            uuid
--      follower_uid  text   ← ownership column (text UID)
--      following_uid text
--      created_at    timestamptz
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='user_follows') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public user_follows" ON public.user_follows$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public user_follows access"        ON public.user_follows$p$;

        EXECUTE $p$DROP POLICY IF EXISTS "Authenticated users can read follows" ON public.user_follows$p$;
        EXECUTE $p$
            CREATE POLICY "Authenticated users can read follows" ON public.user_follows
                FOR SELECT USING (auth.role() = 'authenticated')
        $p$;

        EXECUTE $p$DROP POLICY IF EXISTS "Users can manage own follows" ON public.user_follows$p$;
        EXECUTE $p$
            CREATE POLICY "Users can manage own follows" ON public.user_follows
                FOR ALL
                USING  (auth.uid()::text = follower_uid OR auth.uid()::text = following_uid)
                WITH CHECK (auth.uid()::text = follower_uid)
        $p$;

        RAISE NOTICE 'user_follows: dangerous policy removed, secure policies applied';
    ELSE
        RAISE NOTICE 'user_follows: table does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 10. CHAT_MESSAGES, CHAT_ROOMS (live, Flutter does not use them)
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='chat_rooms') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public chat_rooms" ON public.chat_rooms$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public chat_rooms access"        ON public.chat_rooms$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Authenticated room access" ON public.chat_rooms$p$;
        EXECUTE $p$
            CREATE POLICY "Authenticated room access" ON public.chat_rooms
                FOR SELECT USING (auth.role() = 'authenticated')
        $p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Admins can manage chat rooms" ON public.chat_rooms$p$;
        EXECUTE $p$
            CREATE POLICY "Admins can manage chat rooms" ON public.chat_rooms
                FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())
        $p$;
        RAISE NOTICE 'chat_rooms: dangerous policy removed';
    END IF;

    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='chat_messages') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public chat_messages" ON public.chat_messages$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public chat_messages access"        ON public.chat_messages$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Authenticated message access" ON public.chat_messages$p$;
        EXECUTE $p$
            CREATE POLICY "Authenticated message access" ON public.chat_messages
                FOR SELECT USING (auth.role() = 'authenticated')
        $p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Admins can manage chat messages" ON public.chat_messages$p$;
        EXECUTE $p$
            CREATE POLICY "Admins can manage chat messages" ON public.chat_messages
                FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())
        $p$;
        RAISE NOTICE 'chat_messages: dangerous policy removed';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 11. POSTS, POST_COMMENTS, POST_LIKES (live, Flutter does not use them)
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['posts', 'post_comments', 'post_likes'] LOOP
        IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename=t) THEN
            EXECUTE format($f$DROP POLICY IF EXISTS "Allow all for public %I" ON public.%I$f$, t, t);
            EXECUTE format($f$DROP POLICY IF EXISTS "Public %I access" ON public.%I$f$, t, t);
            EXECUTE format($f$DROP POLICY IF EXISTS "Authenticated %I read" ON public.%I$f$, t, t);
            EXECUTE format($f$
                CREATE POLICY "Authenticated %I read" ON public.%I
                    FOR SELECT USING (auth.role() = 'authenticated')
            $f$, t, t);
            EXECUTE format($f$DROP POLICY IF EXISTS "Admins manage %I" ON public.%I$f$, t, t);
            EXECUTE format($f$
                CREATE POLICY "Admins manage %I" ON public.%I
                    FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())
            $f$, t, t);
            RAISE NOTICE '%: dangerous policy removed', t;
        ELSE
            RAISE NOTICE '%: does not exist — skipped', t;
        END IF;
    END LOOP;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 12. RECOVERY_* TABLES — DO NOT TOUCH
--
--    These 7 tables (recovery_requests, recovery_messages, recovery_evidence,
--    recovery_customer_updates, recovery_admin_notes, recovery_audit_logs,
--    recovery_payments) belong to an independent subsystem whose access model
--    has NOT been confirmed.
--
--    Their dangerous ALL=true policies are a known security gap but modifying
--    them without understanding the recovery system's auth requirements could
--    break a live external system. They are explicitly excluded from this
--    cleanup run and must be addressed separately after the recovery system's
--    access requirements are confirmed.
-- ─────────────────────────────────────────────────────────────────────────────

-- (No statements — intentionally left untouched)


-- ─────────────────────────────────────────────────────────────────────────────
-- 13a. CAMPAIGN_ACCESS_REQUESTS
--
--    CONFIRMED LIVE SCHEMA:
--      id          uuid
--      "brandId"   text
--      "brandName" text
--      status      text
--      "createdAt" timestamptz
--
--    There is NO per-user/creator ownership column on this table. Ownership
--    cannot be expressed safely in RLS → ADMIN-ONLY management.
--    If a per-user column is added later, add a user-scoped policy at that time.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='campaign_access_requests') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public campaign_access_requests" ON public.campaign_access_requests$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public campaign_access_requests access"        ON public.campaign_access_requests$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Admins manage campaign_access_requests"        ON public.campaign_access_requests$p$;
        EXECUTE $p$
            CREATE POLICY "Admins manage campaign_access_requests" ON public.campaign_access_requests
                FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())
        $p$;
        RAISE NOTICE 'campaign_access_requests: secured (admin-only — no ownership column)';
    ELSE
        RAISE NOTICE 'campaign_access_requests: does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 13b. VERIFICATION_REQUESTS
--
--    CONFIRMED LIVE SCHEMA:
--      id              uuid
--      "creatorId"     text   ← ownership column (camelCase, quoted)
--      "creatorName"   text
--      "creatorEmail"  text
--      "proofLink"     text
--      status          text
--      "createdAt"     timestamptz
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='verification_requests') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public verification_requests" ON public.verification_requests$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public verification_requests access"        ON public.verification_requests$p$;

        EXECUTE $p$DROP POLICY IF EXISTS "Creators read own verification_requests" ON public.verification_requests$p$;
        EXECUTE $p$
            CREATE POLICY "Creators read own verification_requests" ON public.verification_requests
                FOR SELECT USING (auth.uid()::text = "creatorId"::text)
        $p$;

        EXECUTE $p$DROP POLICY IF EXISTS "Creators create own verification_requests" ON public.verification_requests$p$;
        EXECUTE $p$
            CREATE POLICY "Creators create own verification_requests" ON public.verification_requests
                FOR INSERT WITH CHECK (auth.uid()::text = "creatorId"::text)
        $p$;

        EXECUTE $p$DROP POLICY IF EXISTS "Admins manage verification_requests" ON public.verification_requests$p$;
        EXECUTE $p$
            CREATE POLICY "Admins manage verification_requests" ON public.verification_requests
                FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())
        $p$;

        RAISE NOTICE 'verification_requests: creator-owned + admin policies applied';
    ELSE
        RAISE NOTICE 'verification_requests: does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 13c. ADMIN_AUDIT_LOGS — admin-only
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='admin_audit_logs') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Allow all for public admin_audit_logs" ON public.admin_audit_logs$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Public admin_audit_logs access"        ON public.admin_audit_logs$p$;
        EXECUTE $p$DROP POLICY IF EXISTS "Admins manage admin_audit_logs"        ON public.admin_audit_logs$p$;
        EXECUTE $p$
            CREATE POLICY "Admins manage admin_audit_logs" ON public.admin_audit_logs
                FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())
        $p$;
        RAISE NOTICE 'admin_audit_logs: admin-only access applied';
    ELSE
        RAISE NOTICE 'admin_audit_logs: does not exist — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- FINAL VERIFICATION QUERY
-- Run this after applying the file to confirm no ALL=true policies remain
-- (except the intentional config SELECT/true):
--
-- SELECT tablename, policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE schemaname = 'public'
--   AND (
--       lower(coalesce(qual,       '')) = 'true'
--       OR lower(coalesce(with_check, '')) = 'true'
--   )
-- ORDER BY tablename, policyname;
--
-- EXPECTED after cleanup:
--   config — SELECT / true       (intentional public read)
-- All other rows = remaining dangerous policies still needing attention.
--
-- KNOWN REMAINING GAP after this file:
--   recovery_* (7 tables) — intentionally untouched pending access model review.
-- ─────────────────────────────────────────────────────────────────────────────
