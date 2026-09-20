-- ============================================================================
-- 06_MESSAGES_SOFT_STATE.sql
-- Rexo — Messages Soft-State (edit / unsend / delete-for-me)
--
-- PURPOSE
--   Adds non-destructive soft-state to public.messages so the chat screen can:
--     - EDIT a message (sender only), tracking an "edited" timestamp
--     - UNSEND a message (sender only), hiding content for BOTH parties
--     - DELETE-FOR-ME (either participant) without affecting the other party
--
-- NEW COLUMNS
--   is_unsent   boolean       NOT NULL DEFAULT false   — terminal unsend flag
--   edited_at   timestamptz   NULL                     — last edit timestamp
--   deleted_for uuid[]        NOT NULL DEFAULT '{}'    — per-user delete set
--
-- SECURITY
--   Column-level rules are enforced by a BEFORE UPDATE trigger because Postgres
--   RLS alone cannot compare OLD vs NEW values:
--     - edit / unsend  → allowed ONLY when auth.uid() = sender_id
--     - deleted_for    → append-only, own id only, participant only
--
-- IDEMPOTENCY
--   ADD COLUMN IF NOT EXISTS, CREATE INDEX IF NOT EXISTS,
--   DROP POLICY IF EXISTS + CREATE POLICY, CREATE OR REPLACE FUNCTION,
--   DROP TRIGGER IF EXISTS + CREATE TRIGGER.
--   Safe to run multiple times.
--
-- DEPENDENCIES
--   schema.sql messages table must exist.
--   Does NOT depend on 01_RLS_FIXES.sql.
-- ============================================================================

ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS is_unsent   BOOLEAN  NOT NULL DEFAULT FALSE;
ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS edited_at   TIMESTAMPTZ;
ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS deleted_for UUID[]   NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_messages_deleted_for
    ON public.messages USING GIN (deleted_for);


-- ─────────────────────────────────────────────────────────────────────────────
-- Column-level enforcement trigger
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.enforce_messages_soft_state()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    caller UUID := auth.uid();
BEGIN
    -- Structural columns are immutable.
    IF NEW.id            <> OLD.id
       OR NEW.sender_id   <> OLD.sender_id
       OR NEW.receiver_id <> OLD.receiver_id
       OR NEW.created_at  <> OLD.created_at THEN
        RAISE EXCEPTION 'messages: id, sender_id, receiver_id and created_at are immutable';
    END IF;

    -- Content / soft-state edits → sender only.
    IF (NEW.content   IS DISTINCT FROM OLD.content)
       OR (NEW.is_unsent IS DISTINCT FROM OLD.is_unsent)
       OR (NEW.edited_at IS DISTINCT FROM OLD.edited_at) THEN

        IF caller IS NULL OR caller <> OLD.sender_id THEN
            RAISE EXCEPTION 'messages: only the sender may edit or unsend a message';
        END IF;

        IF OLD.is_unsent = TRUE AND NEW.is_unsent = FALSE THEN
            RAISE EXCEPTION 'messages: unsend is terminal and cannot be reverted';
        END IF;

        IF OLD.is_unsent = TRUE
           AND ((NEW.content IS DISTINCT FROM OLD.content)
                OR (NEW.edited_at IS DISTINCT FROM OLD.edited_at)) THEN
            RAISE EXCEPTION 'messages: cannot edit a message that is already unsent';
        END IF;
    END IF;

    -- deleted_for changes → participant only, append-only, own id only.
    IF NEW.deleted_for IS DISTINCT FROM OLD.deleted_for THEN
        IF caller IS NULL
           OR (caller <> OLD.sender_id AND caller <> OLD.receiver_id) THEN
            RAISE EXCEPTION 'messages: only a conversation participant may delete a message for themselves';
        END IF;

        IF EXISTS (
            SELECT 1 FROM unnest(OLD.deleted_for) old_id
            WHERE old_id <> ALL (NEW.deleted_for)
        ) THEN
            RAISE EXCEPTION 'messages: deleted_for is append-only; existing ids cannot be removed';
        END IF;

        IF EXISTS (
            SELECT 1 FROM unnest(NEW.deleted_for) new_id
            WHERE new_id <> ALL (OLD.deleted_for) AND new_id <> caller
        ) THEN
            RAISE EXCEPTION 'messages: a participant may only add their own id to deleted_for';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_messages_soft_state ON public.messages;
CREATE TRIGGER trg_messages_soft_state
    BEFORE UPDATE ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_messages_soft_state();


-- ─────────────────────────────────────────────────────────────────────────────
-- Additional UPDATE policies (additive — do not drop existing policies)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Sender can edit or unsend own messages" ON public.messages;
CREATE POLICY "Sender can edit or unsend own messages"
    ON public.messages FOR UPDATE
    USING (auth.uid() = sender_id)
    WITH CHECK (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Participants can delete messages for themselves" ON public.messages;
CREATE POLICY "Participants can delete messages for themselves"
    ON public.messages FOR UPDATE
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id)
    WITH CHECK (auth.uid() = sender_id OR auth.uid() = receiver_id);
