-- ============================================================================
-- Rexo Collab — User Reports + User Blocking
-- ============================================================================
--
-- REPORTS: reuse the existing public.moderation_queue table (do NOT create a
-- duplicate system). We only add an optional free-text `details` column. The
-- existing RLS already lets an authenticated user INSERT rows where
-- reported_by = auth.uid(), SELECT their own rows, and lets admins manage all.
--
-- BLOCKS: a new public.user_blocks table with strict RLS so a user manages only
-- their own block list.
--
-- LIVE SCHEMA NOTE: identities in the app are the auth uid. moderation_queue
-- .reported_by is uuid = auth.uid(); content_id is uuid (a user id, campaign id
-- or chat_messages id — all uuids). user_blocks stores the auth uid on both
-- sides as uuid.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. REPORTS — extend moderation_queue with optional details
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    BEGIN
        ALTER TABLE public.moderation_queue
            ADD COLUMN IF NOT EXISTS details TEXT;
    EXCEPTION WHEN undefined_table THEN
        RAISE NOTICE 'moderation_queue does not exist; creating it';
        CREATE TABLE public.moderation_queue (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            content_id UUID,
            content_type TEXT,
            reported_by UUID REFERENCES public.users(id),
            reason TEXT,
            details TEXT,
            status TEXT DEFAULT 'pending',
            reviewed_by UUID,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
        ALTER TABLE public.moderation_queue ENABLE ROW LEVEL SECURITY;

        CREATE POLICY "Users can insert moderation reports"
            ON public.moderation_queue FOR INSERT
            WITH CHECK (auth.uid() = reported_by);

        CREATE POLICY "Users can read own moderation reports"
            ON public.moderation_queue FOR SELECT
            USING (auth.uid() = reported_by);

        CREATE POLICY "Admins can manage all moderation queue"
            ON public.moderation_queue FOR ALL
            USING (
                EXISTS (SELECT 1 FROM public.users
                        WHERE id = auth.uid() AND lower(role) = 'admin')
            );
    END;
END $$;

CREATE INDEX IF NOT EXISTS idx_moderation_queue_reported_by
    ON public.moderation_queue(reported_by);
CREATE INDEX IF NOT EXISTS idx_moderation_queue_status
    ON public.moderation_queue(status);

-- ---------------------------------------------------------------------------
-- 2. BLOCKS — user_blocks table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_blocks (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL,
    blocked_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT user_blocks_no_self_block CHECK (blocker_id <> blocked_id),
    CONSTRAINT user_blocks_unique_pair UNIQUE (blocker_id, blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker ON public.user_blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked ON public.user_blocks(blocked_id);

ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

-- A user may create blocks only as themselves (and never block themselves —
-- also enforced by the CHECK constraint above).
DROP POLICY IF EXISTS "Users can create own blocks" ON public.user_blocks;
CREATE POLICY "Users can create own blocks"
    ON public.user_blocks FOR INSERT
    WITH CHECK (auth.uid() = blocker_id AND blocker_id <> blocked_id);

-- A user can see blocks they created, AND rows where they are the blocked party
-- (needed so the app can two-way-hide a user who blocked them). No broad
-- USING(true).
DROP POLICY IF EXISTS "Users can read relevant blocks" ON public.user_blocks;
CREATE POLICY "Users can read relevant blocks"
    ON public.user_blocks FOR SELECT
    USING (auth.uid() = blocker_id OR auth.uid() = blocked_id);

-- A user can remove (unblock) only their own blocks.
DROP POLICY IF EXISTS "Users can delete own blocks" ON public.user_blocks;
CREATE POLICY "Users can delete own blocks"
    ON public.user_blocks FOR DELETE
    USING (auth.uid() = blocker_id);

-- Admins can review all blocks.
DROP POLICY IF EXISTS "Admins can read all blocks" ON public.user_blocks;
CREATE POLICY "Admins can read all blocks"
    ON public.user_blocks FOR SELECT
    USING (
        EXISTS (SELECT 1 FROM public.users
                WHERE id = auth.uid() AND lower(role) = 'admin')
    );

-- ============================================================================
-- VERIFICATION:
--   -- Report (as authenticated user):
--   INSERT INTO public.moderation_queue (content_id, content_type, reported_by, reason, details)
--   VALUES ('<target-uuid>', 'user', auth.uid(), 'Spam', 'optional text');
--   -- Block:
--   INSERT INTO public.user_blocks (blocker_id, blocked_id) VALUES (auth.uid(), '<target-uuid>');
--   -- Self-block should FAIL (check constraint + policy).
-- ============================================================================
