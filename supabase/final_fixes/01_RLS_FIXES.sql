-- ============================================================================
-- 01_RLS_FIXES.sql
-- Rexo — Row Level Security Fixes
--
-- CONFIRMED LIVE users SCHEMA (relevant columns)
--   uid          text NOT NULL   ← RLS ownership column
--   role         text            ← DEFAULT 'CREATOR'
--   "isVerified" boolean
--   "isBanned"   boolean
--   (NO account_status, NO admin_sub_role, NO is_verified, NO id-based RLS)
--
-- CONFIRMED LIVE notifications SCHEMA
--   "userId" text NOT NULL, "title" text, "message" text,
--   "type" text, "read" boolean, "link" text, "createdAt" timestamptz
--
-- CONFIRMED LIVE applications SCHEMA (relevant columns)
--   "creatorId" text  ← camelCase (NOT creator_id)
--   "campaignId" text ← camelCase (NOT campaign_id)
--   status text
--
-- TABLES NOT IN LIVE DB (skipped with comments):
--   public.products — does not exist in live DB
--
-- ALL SECTIONS USE IF EXISTS GUARDS — safe to run multiple times.
-- RUN THIS FILE FIRST — it defines is_admin() used by all other files.
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- A. is_admin() — uses uid (text), not id (uuid)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE uid = auth.uid()::text
      AND lower(role) = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- D2. Self-escalation guard function (defined before trigger below)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.prevent_user_self_escalation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF public.is_admin() THEN RETURN NEW; END IF;
    NEW.role         := OLD.role;
    NEW."isVerified" := OLD."isVerified";
    NEW."isBanned"   := OLD."isBanned";
    RETURN NEW;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- B. Notifications INSERT policy
--    Live column: "userId" (camelCase text)
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='notifications') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "System can create notifications" ON public.notifications$p$;
        EXECUTE $p$
            CREATE POLICY "System can create notifications" ON public.notifications
                FOR INSERT
                WITH CHECK (
                    auth.uid()::text = "userId"::text
                    OR public.is_admin()
                )
        $p$;
        RAISE NOTICE 'notifications: INSERT policy applied';
    ELSE
        RAISE NOTICE 'notifications: table not found — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- C. Applications UPDATE policy
--    Live column: "creatorId" (camelCase text, NOT creator_id)
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='applications') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Creators can update own applications" ON public.applications$p$;
        EXECUTE $p$
            CREATE POLICY "Creators can update own applications" ON public.applications
                FOR UPDATE
                USING  (auth.uid()::text = "creatorId"::text)
                WITH CHECK (
                    auth.uid()::text = "creatorId"::text
                    AND status IN ('pending', 'withdrawn')
                )
        $p$;
        RAISE NOTICE 'applications: UPDATE policy applied';
    ELSE
        RAISE NOTICE 'applications: table not found — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- D. Drop old broken JWT-based admin update policy on users
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Admins can update any user" ON public.users;


-- ─────────────────────────────────────────────────────────────────────────────
-- D2. Self-escalation trigger on users
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='users') THEN
        EXECUTE $p$DROP TRIGGER IF EXISTS trg_prevent_user_self_escalation ON public.users$p$;
        EXECUTE $p$
            CREATE TRIGGER trg_prevent_user_self_escalation
                BEFORE UPDATE ON public.users
                FOR EACH ROW
                EXECUTE FUNCTION public.prevent_user_self_escalation()
        $p$;
        RAISE NOTICE 'users: self-escalation trigger applied';
    ELSE
        RAISE NOTICE 'users: table not found — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- E. Products DELETE — SKIPPED
--    public.products does NOT exist in the live DB.
-- ─────────────────────────────────────────────────────────────────────────────

-- (commented out — table absent in live DB)
-- DROP POLICY IF EXISTS "Admins can delete products" ON public.products;
-- CREATE POLICY "Admins can delete products" ON public.products FOR DELETE USING (public.is_admin());


-- ─────────────────────────────────────────────────────────────────────────────
-- F. Campaigns DELETE policy
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='campaigns') THEN
        EXECUTE $p$DROP POLICY IF EXISTS "Admins can delete campaigns" ON public.campaigns$p$;
        EXECUTE $p$
            CREATE POLICY "Admins can delete campaigns" ON public.campaigns
                FOR DELETE
                USING (public.is_admin())
        $p$;
        RAISE NOTICE 'campaigns: DELETE policy applied';
    ELSE
        RAISE NOTICE 'campaigns: table not found — skipped';
    END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- G. Reload PostgREST schema cache
-- ─────────────────────────────────────────────────────────────────────────────

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
