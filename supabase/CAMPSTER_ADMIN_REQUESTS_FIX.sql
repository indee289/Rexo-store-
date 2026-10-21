-- ============================================================================
-- CAMPSTER — ADMIN REQUESTS FIX (run once in the Supabase SQL editor)
-- ============================================================================
-- IDEMPOTENT (safe to run many times). Does NOT delete any data.
-- Run AFTER CAMPSTER_FIX_RUN_THIS.sql (needs public.is_admin()).
--
-- Fixes:
--   1. Disputes raised by brand/creator never reached the admin
--        -> makes sure `disputes` exists with the columns the app writes and
--           that admins can read/resolve every row.
--   2. Reports (moderation_queue) + job submissions (applications) missing
--      columns / admin policies.
--   3. Admins got NO notification when a user sent a dispute / withdrawal /
--      report / job submission / support message
--        -> adds SECURITY DEFINER RPCs the app calls:
--             notify_admins(title, message, type)
--             notify_admin_of_message(receiver, preview)
--   4. Help & Support "Message us" needs to find an admin to chat with
--        -> get_support_admin() returns the admin's user id.
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- 0) Helper (re-asserted so this file also works standalone)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u
    WHERE COALESCE(to_jsonb(u)->>'uid', to_jsonb(u)->>'id') = auth.uid()::text
      AND lower(COALESCE(to_jsonb(u)->>'role', '')) = 'admin'
  );
$$;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- 1) DISPUTES — table + columns + RLS
--    (types are TEXT on purpose: the app sends free-typed order/campaign ids
--     and the live users table keys on a text uid.)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.disputes (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     TEXT,
    order_id    TEXT,
    campaign_id TEXT,
    subject     TEXT,
    description TEXT,
    status      TEXT        DEFAULT 'open',
    resolution  TEXT,
    admin_id    TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);
ALTER TABLE public.disputes ADD COLUMN IF NOT EXISTS user_id     TEXT;
ALTER TABLE public.disputes ADD COLUMN IF NOT EXISTS order_id    TEXT;
ALTER TABLE public.disputes ADD COLUMN IF NOT EXISTS campaign_id TEXT;
ALTER TABLE public.disputes ADD COLUMN IF NOT EXISTS subject     TEXT;
ALTER TABLE public.disputes ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.disputes ADD COLUMN IF NOT EXISTS status      TEXT DEFAULT 'open';
ALTER TABLE public.disputes ADD COLUMN IF NOT EXISTS resolution  TEXT;
ALTER TABLE public.disputes ADD COLUMN IF NOT EXISTS admin_id    TEXT;
ALTER TABLE public.disputes ADD COLUMN IF NOT EXISTS created_at  TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.disputes ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;

ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own disputes"      ON public.disputes;
DROP POLICY IF EXISTS "Users can insert own disputes"    ON public.disputes;
DROP POLICY IF EXISTS "Users can update own disputes"    ON public.disputes;
DROP POLICY IF EXISTS "Admins can manage all disputes"   ON public.disputes;

CREATE POLICY "Users can read own disputes" ON public.disputes
  FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own disputes" ON public.disputes
  FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

-- Admins: full access (read every dispute, resolve it).
CREATE POLICY "Admins can manage all disputes" ON public.disputes
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());


-- ─────────────────────────────────────────────────────────────────────────────
-- 2) REPORTS (moderation_queue) — details column + admin policies
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF to_regclass('public.moderation_queue') IS NOT NULL THEN
    ALTER TABLE public.moderation_queue ADD COLUMN IF NOT EXISTS details     TEXT;
    ALTER TABLE public.moderation_queue ADD COLUMN IF NOT EXISTS reviewed_by TEXT;
    ALTER TABLE public.moderation_queue ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "Users can insert moderation reports" ON public.moderation_queue;
    CREATE POLICY "Users can insert moderation reports" ON public.moderation_queue
      FOR INSERT WITH CHECK (auth.uid()::text = reported_by::text);

    DROP POLICY IF EXISTS "Users can read own reports" ON public.moderation_queue;
    CREATE POLICY "Users can read own reports" ON public.moderation_queue
      FOR SELECT USING (auth.uid()::text = reported_by::text);

    DROP POLICY IF EXISTS "Admins can manage moderation queue" ON public.moderation_queue;
    CREATE POLICY "Admins can manage moderation queue" ON public.moderation_queue
      FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
  END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3) APPLICATIONS — columns written when a creator submits job/task proof
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF to_regclass('public.applications') IS NOT NULL THEN
    ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_type TEXT;
    ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_url  TEXT;
    ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_note TEXT;
  END IF;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4) notify_admins — insert an in-app notification for EVERY admin.
--    SECURITY DEFINER so a normal user (blocked by RLS from writing other
--    people's notifications) can still alert the admins. Handles both the live
--    camelCase notifications table ("userId"/message/read/"createdAt") and the
--    snake_case one (user_id/body/is_read/created_at). Returns #admins notified.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_admins(
  p_title   text,
  p_message text,
  p_type    text DEFAULT 'admin_request'
)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_admin   text;
  v_count   integer := 0;
  v_camel   boolean;
BEGIN
  IF auth.uid() IS NULL THEN RETURN 0; END IF;
  IF to_regclass('public.notifications') IS NULL THEN RETURN 0; END IF;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications'
      AND column_name = 'userId'
  ) INTO v_camel;

  FOR v_admin IN
    SELECT COALESCE(to_jsonb(u)->>'uid', to_jsonb(u)->>'id')
    FROM public.users u
    WHERE lower(COALESCE(to_jsonb(u)->>'role', '')) = 'admin'
  LOOP
    CONTINUE WHEN v_admin IS NULL;
    BEGIN
      IF v_camel THEN
        INSERT INTO public.notifications ("userId", title, message, type, read, "createdAt")
        VALUES (v_admin, p_title, p_message, p_type, false, now());
      ELSE
        INSERT INTO public.notifications (user_id, title, body, type, is_read, created_at)
        VALUES (v_admin::uuid, p_title, p_message, p_type, false, now());
      END IF;
      v_count := v_count + 1;
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'notify_admins skipped %: %', v_admin, SQLERRM;
    END;
  END LOOP;

  RETURN v_count;
END;
$$;
GRANT EXECUTE ON FUNCTION public.notify_admins(text, text, text) TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- 5) notify_admin_of_message — when a user chats with an admin, put an unread
--    notification on that admin. Does nothing if the receiver is not an admin
--    (so it cannot be abused to spam normal users).
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_admin_of_message(
  p_receiver text,
  p_preview  text
)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_is_admin boolean;
  v_name     text;
  v_camel    boolean;
  v_title    text;
BEGIN
  IF auth.uid() IS NULL OR p_receiver IS NULL THEN RETURN false; END IF;
  IF to_regclass('public.notifications') IS NULL THEN RETURN false; END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.users u
    WHERE COALESCE(to_jsonb(u)->>'uid', to_jsonb(u)->>'id') = p_receiver
      AND lower(COALESCE(to_jsonb(u)->>'role', '')) = 'admin'
  ) INTO v_is_admin;
  IF NOT v_is_admin THEN RETURN false; END IF;

  SELECT COALESCE(to_jsonb(u)->>'name', to_jsonb(u)->>'username', 'A user')
    INTO v_name
  FROM public.users u
  WHERE COALESCE(to_jsonb(u)->>'uid', to_jsonb(u)->>'id') = auth.uid()::text
  LIMIT 1;

  v_title := 'New support message from ' || COALESCE(v_name, 'a user');

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications'
      AND column_name = 'userId'
  ) INTO v_camel;

  IF v_camel THEN
    INSERT INTO public.notifications ("userId", title, message, type, read, "createdAt")
    VALUES (p_receiver, v_title, left(COALESCE(p_preview, ''), 200), 'message', false, now());
  ELSE
    INSERT INTO public.notifications (user_id, title, body, type, is_read, created_at)
    VALUES (p_receiver::uuid, v_title, left(COALESCE(p_preview, ''), 200), 'message', false, now());
  END IF;
  RETURN true;
EXCEPTION WHEN others THEN
  RAISE NOTICE 'notify_admin_of_message failed: %', SQLERRM;
  RETURN false;
END;
$$;
GRANT EXECUTE ON FUNCTION public.notify_admin_of_message(text, text) TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- 6) get_support_admin — the user id of an admin the Help screen can chat with.
--    SECURITY DEFINER because normal users may not be allowed to SELECT the
--    users table by role. Returns only the id (no other admin data).
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_support_admin()
RETURNS text
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $$
  SELECT COALESCE(to_jsonb(u)->>'uid', to_jsonb(u)->>'id')
  FROM public.users u
  WHERE lower(COALESCE(to_jsonb(u)->>'role', '')) = 'admin'
    AND COALESCE(to_jsonb(u)->>'uid', to_jsonb(u)->>'id') IS NOT NULL
  ORDER BY COALESCE(to_jsonb(u)->>'uid', to_jsonb(u)->>'id')
  LIMIT 1;
$$;
GRANT EXECUTE ON FUNCTION public.get_support_admin() TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- Reload the PostgREST schema cache.
-- ─────────────────────────────────────────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- DONE. Disputes/reports now reach the admin, admins get a notification for
-- every new request, and "Help & Support → Message us" opens an admin chat.
