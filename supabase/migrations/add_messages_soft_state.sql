-- ============================================================================
-- MIGRATION: Messages Soft-State (edit / unsend / delete-for-me) + RLS
--
-- PART OF: Premium UI/UX Redesign  (spec: premium-ui-redesign, task 7.1)
--
-- PURPOSE: Add non-destructive, auditable soft-state support to the existing
--          public.messages table so the redesigned Chat screen can:
--            - EDIT a message (sender only), tracking an "edited" timestamp
--            - UNSEND a message (sender only), hiding content for BOTH parties
--            - DELETE-FOR-ME (either participant) without affecting the other
--
-- NEW COLUMNS (additive, backward compatible):
--   - is_unsent    boolean       NOT NULL DEFAULT false
--   - edited_at    timestamptz   NULL
--   - deleted_for  uuid[]        NOT NULL DEFAULT '{}'
--
-- SECURITY MODEL (from design "Security Considerations"):
--   - edit / unsend            => allowed ONLY when auth.uid() = sender_id
--   - deleted_for append       => allowed ONLY for participants (sender OR
--                                 receiver) and each caller may append ONLY
--                                 their OWN id (append-only set semantics).
--   Row-level access is granted by RLS UPDATE policies; the precise
--   column-level rules are enforced by a BEFORE UPDATE trigger, because
--   Postgres RLS alone cannot compare OLD vs NEW to detect which columns
--   changed or restrict which id was appended.
--
-- REQUIREMENTS: 4.2 (edit sets content + edited_at, sender only),
--               5.1 (unsend sets is_unsent, sender only),
--               6.1 / 6.2 (delete-for-me appends caller id, set semantics)
--
-- PRESERVATION: Existing messages RLS policies are NOT dropped or weakened.
--   - "Users can read own messages"   (SELECT)  -> untouched
--   - "Users can send messages"       (INSERT)  -> untouched
--   - "Users can update own messages" (UPDATE, receiver -> is_read) -> untouched
--   This migration only ADDS columns, an index, one UPDATE policy for the
--   sender, one UPDATE policy for participant delete-for-me, and a trigger.
--
-- IDEMPOTENT: Safe to run multiple times
--   (ADD COLUMN IF NOT EXISTS, CREATE INDEX IF NOT EXISTS,
--    DROP POLICY IF EXISTS + CREATE POLICY, CREATE OR REPLACE FUNCTION,
--    DROP TRIGGER IF EXISTS + CREATE TRIGGER).
--
-- DEPENDENCIES: Requires the public.messages table (see supabase/schema.sql).
--               Must land BEFORE the messaging data layer (spec task 8).
-- ============================================================================

-- ============================================================================
-- 1. ADD SOFT-STATE COLUMNS (idempotent, additive)
-- ============================================================================

ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS is_unsent BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ;

ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS deleted_for UUID[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN public.messages.is_unsent IS
'Sender unsent the message; displayed content is empty for BOTH participants. Terminal state (cannot be reverted).';

COMMENT ON COLUMN public.messages.edited_at IS
'Last edit time. NULL means never edited; a non-null value tells the UI to show an "edited" label.';

COMMENT ON COLUMN public.messages.deleted_for IS
'Set (append-only) of user ids who deleted the message for themselves. A message is visible to user u iff u is NOT in this array. Never removes content for the other participant.';

-- ============================================================================
-- 2. INDEX to keep per-user delete-for-me filtering efficient
--    (GIN index supports array containment / ANY() membership checks).
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_messages_deleted_for
    ON public.messages USING GIN (deleted_for);

-- ============================================================================
-- 3. COLUMN-LEVEL ENFORCEMENT TRIGGER
--
-- RLS grants row-level access, but the fine-grained invariants below cannot
-- be expressed with USING/WITH CHECK alone (they need OLD vs NEW). This
-- BEFORE UPDATE trigger enforces:
--   - Immutable identity columns (id, sender_id, receiver_id, created_at).
--   - content / is_unsent / edited_at may change ONLY when caller = sender.
--   - Editing content/edited_at is rejected once the message is unsent.
--   - Unsend is terminal (is_unsent cannot revert true -> false).
--   - deleted_for changes require the caller to be a participant, are
--     append-only (no ids removed), and each caller may add ONLY their own id.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.enforce_messages_soft_state()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    caller UUID := auth.uid();
BEGIN
    -- Identity / structural columns are immutable via UPDATE.
    IF NEW.id            <> OLD.id
       OR NEW.sender_id  <> OLD.sender_id
       OR NEW.receiver_id <> OLD.receiver_id
       OR NEW.created_at <> OLD.created_at THEN
        RAISE EXCEPTION
            'messages: id, sender_id, receiver_id and created_at are immutable';
    END IF;

    -- Content / soft-state edits (content, is_unsent, edited_at) => sender only.
    IF (NEW.content   IS DISTINCT FROM OLD.content)
       OR (NEW.is_unsent IS DISTINCT FROM OLD.is_unsent)
       OR (NEW.edited_at IS DISTINCT FROM OLD.edited_at) THEN

        IF caller IS NULL OR caller <> OLD.sender_id THEN
            RAISE EXCEPTION
                'messages: only the sender may edit or unsend a message';
        END IF;

        -- Unsend is terminal: cannot flip is_unsent back to false.
        IF OLD.is_unsent = TRUE AND NEW.is_unsent = FALSE THEN
            RAISE EXCEPTION
                'messages: unsend is terminal and cannot be reverted';
        END IF;

        -- Editing an already-unsent message is disallowed (content/edited_at
        -- may not change once unsent). Setting is_unsent=true itself is fine.
        IF OLD.is_unsent = TRUE
           AND ((NEW.content IS DISTINCT FROM OLD.content)
                OR (NEW.edited_at IS DISTINCT FROM OLD.edited_at)) THEN
            RAISE EXCEPTION
                'messages: cannot edit a message that is already unsent';
        END IF;
    END IF;

    -- deleted_for changes => participant only, append-only, own id only.
    IF NEW.deleted_for IS DISTINCT FROM OLD.deleted_for THEN

        IF caller IS NULL
           OR (caller <> OLD.sender_id AND caller <> OLD.receiver_id) THEN
            RAISE EXCEPTION
                'messages: only a conversation participant may delete a message for themselves';
        END IF;

        -- Append-only: no existing id may be removed.
        IF EXISTS (
            SELECT 1 FROM unnest(OLD.deleted_for) AS old_id
            WHERE old_id <> ALL (NEW.deleted_for)
        ) THEN
            RAISE EXCEPTION
                'messages: deleted_for is append-only; existing ids cannot be removed';
        END IF;

        -- Own id only: every newly added id must equal the caller.
        IF EXISTS (
            SELECT 1 FROM unnest(NEW.deleted_for) AS new_id
            WHERE new_id <> ALL (OLD.deleted_for)
              AND new_id <> caller
        ) THEN
            RAISE EXCEPTION
                'messages: a participant may only add their own id to deleted_for';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.enforce_messages_soft_state() IS
'BEFORE UPDATE guard for public.messages soft-state: enforces sender-only edit/unsend, terminal unsend, and append-only own-id delete-for-me. Complements RLS row-access policies.';

DROP TRIGGER IF EXISTS trg_messages_soft_state ON public.messages;
CREATE TRIGGER trg_messages_soft_state
    BEFORE UPDATE ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_messages_soft_state();

-- ============================================================================
-- 4. RLS POLICIES (additive)
--
-- messages already has RLS enabled (see schema.sql). We only ADD UPDATE
-- policies. Permissive UPDATE policies are OR-combined, so these coexist with
-- the existing receiver "Users can update own messages" policy (is_read).
-- The trigger above provides the column-level guarantees.
-- ============================================================================

-- Ensure RLS stays enabled (no-op if already on).
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Sender may UPDATE their own message (edit content/edited_at, set is_unsent).
DROP POLICY IF EXISTS "Sender can edit or unsend own messages" ON public.messages;
CREATE POLICY "Sender can edit or unsend own messages"
    ON public.messages FOR UPDATE
    USING (auth.uid() = sender_id)
    WITH CHECK (auth.uid() = sender_id);

-- Either participant may UPDATE to record a delete-for-me. Row-level access is
-- granted here; append-only + own-id-only rules are enforced by the trigger.
DROP POLICY IF EXISTS "Participants can delete messages for themselves" ON public.messages;
CREATE POLICY "Participants can delete messages for themselves"
    ON public.messages FOR UPDATE
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id)
    WITH CHECK (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- ============================================================================
-- MIGRATION VALIDATION (run after applying)
--
-- 1. Columns present:
--    SELECT column_name, data_type, column_default, is_nullable
--      FROM information_schema.columns
--     WHERE table_schema = 'public' AND table_name = 'messages'
--       AND column_name IN ('is_unsent','edited_at','deleted_for');
--
-- 2. Trigger present:
--    SELECT tgname FROM pg_trigger
--     WHERE tgrelid = 'public.messages'::regclass AND NOT tgisinternal;
--
-- 3. Policies present (existing + new):
--    SELECT policyname, cmd FROM pg_policies
--     WHERE schemaname = 'public' AND tablename = 'messages'
--     ORDER BY policyname;
--
-- 4. Behavioural checks (as authenticated users):
--    - Sender UPDATE content + edited_at            -> succeeds
--    - Receiver UPDATE content                      -> raises (sender only)
--    - Sender UPDATE is_unsent = true               -> succeeds
--    - Any attempt to set is_unsent back to false   -> raises (terminal)
--    - Participant appends own id to deleted_for     -> succeeds
--    - Participant appends someone else's id         -> raises (own id only)
--    - Removing an id from deleted_for               -> raises (append-only)
--    - Receiver UPDATE is_read = true                -> still succeeds (unchanged)
-- ============================================================================

-- ============================================================================
-- ROLLBACK INSTRUCTIONS
--
-- To fully revert this migration, execute (in this order):
--
--   -- Drop the added UPDATE policies (leaves existing policies intact)
--   DROP POLICY IF EXISTS "Sender can edit or unsend own messages" ON public.messages;
--   DROP POLICY IF EXISTS "Participants can delete messages for themselves" ON public.messages;
--
--   -- Drop the enforcement trigger + function
--   DROP TRIGGER IF EXISTS trg_messages_soft_state ON public.messages;
--   DROP FUNCTION IF EXISTS public.enforce_messages_soft_state();
--
--   -- Drop the supporting index
--   DROP INDEX IF EXISTS public.idx_messages_deleted_for;
--
--   -- Drop the soft-state columns (DESTRUCTIVE: loses edit/unsend/delete state)
--   ALTER TABLE public.messages DROP COLUMN IF EXISTS deleted_for;
--   ALTER TABLE public.messages DROP COLUMN IF EXISTS edited_at;
--   ALTER TABLE public.messages DROP COLUMN IF EXISTS is_unsent;
--
-- IMPACT OF ROLLBACK:
-- - Edit / unsend / delete-for-me features stop working in the app.
-- - Existing send + read (is_read) messaging behavior is unaffected.
-- - Any stored soft-state (edited_at, is_unsent, deleted_for) is lost.
-- ============================================================================

-- ============================================================================
-- DEPLOYMENT NOTES
-- - Can be applied online (no downtime): only adds columns with defaults,
--   one index, a trigger, and two permissive UPDATE policies.
-- - No impact on existing SELECT/INSERT/UPDATE(is_read) behavior.
-- - Must be applied before spec task 8 (messaging data layer).
-- ============================================================================
