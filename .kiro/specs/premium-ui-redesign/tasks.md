# Implementation Plan: Premium UI/UX Redesign

## Overview

This plan converts the Premium UI/UX Redesign design into incremental Flutter (Dart) coding tasks. It follows the design's four-layer strategy — build the **design tokens** first, then the **premium primitives**, then the **composites**, then wire the **screens** — so the premium look stays centralized and every later task builds on stable foundations.

Work order:

1. Extend `Theme_System` tokens and add the premium `Component_Library` primitives.
2. Add loading/motion infrastructure (shimmer skeletons, staggered entrance, transitions).
3. Build the compact shared `CampaignCard` and fix cover-image rendering in exactly three locations.
4. Add the Supabase message soft-state migration + RLS, then the messaging data layer and premium Inbox/Chat.
5. Repurpose the Campaigns tab to applied-only.
6. Fix resilient creator resolution and build the Instagram-style creator profile with follow/unfollow.
7. Roll the design system out across the remaining screens.
8. Track the FCM push-notification key fix as a separate backend/config task.

All code examples in the design use Dart; implementation is in Dart/Flutter. Property-based test sub-tasks reference the design's 10 correctness properties. Test-related sub-tasks are marked optional with `*`.

## Tasks

- [x] 1. Extend the design token system (Theme_System)
  - [x] 1.1 Add spacing, radius, elevation, and motion tokens
    - Create `AppSpacing` (xs/sm/md/lg/xl/xxl), `AppRadius` (sm/md/lg/xl/pill), `AppElevation.card(isDark)`, and `AppMotion` (fast/base/slow durations; standard/emphasized/exit curves; stagger) in `lib/core/theme/`
    - Add the new semantic `surfaceAlt` and `border` color tokens to `AppColors` for both light and dark
    - Standardize `AppTextStyles` usage (h1–h6, body*, caption, button, label*) with no inline color so they inherit theme contrast
    - _Requirements: 10.1, 10.5_

  - [x] 1.2 Apply consistent theme + app bar styling in ThemeData
    - Wire tokens into light and dark `ThemeData` (colorScheme, textTheme, inputDecorationTheme)
    - Configure the shared app bar theme: `surface` background, `elevation: 0`, `scrolledUnderElevation: 0.5`, standard `AppTextStyles.h5` title
    - _Requirements: 10.4, 10.5_

- [x] 2. Build the premium component library primitives (Component_Library)
  - [x] 2.1 Implement PremiumButton with variants, states, and press-scale
    - Variants `filled`/`tonal`/`outline`/`ghost`, optional gradient, leading Iconsax icon, `expand`
    - Disabled styling + ignore taps when `onPressed == null`; spinner + ignore taps when `loading`; press-scale to 0.97 over `AppMotion.fast`
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

  - [ ]* 2.2 Write widget tests for PremiumButton states
    - Disabled when `onPressed == null`; spinner shown and taps blocked when `loading`; press animates within fast motion
    - _Requirements: 11.2, 11.3, 11.4_

  - [x] 2.3 Implement PremiumChip, PremiumIconButton, and PremiumTextField
    - `PremiumChip` (selected/unselected, optional count badge, Iconsax leading icon)
    - `PremiumIconButton` (44×44 tap target, Iconsax, optional tonal background)
    - `PremiumTextField` (search + multiline variants using `inputDecorationTheme`)
    - _Requirements: 11.1, 11.5_

  - [x] 2.4 Implement PremiumSheet helper
    - `showPremiumSheet<T>` with grab handle, title row + close `PremiumIconButton`, `AppRadius.xl` top corners, `surface` background, safe-area, scroll-controlled height
    - _Requirements: 11.6_

  - [x] 2.5 Implement PremiumAvatar, SectionHeader, EmptyState, and RoleBadge/StatPill
    - `PremiumAvatar` consolidates avatar rendering with ring/verified overlay via `cached_network_image`
    - `SectionHeader` (title + optional action), `EmptyState` (Iconsax glyph + title + subtitle + optional CTA)
    - `RoleBadge`/`StatPill` pull hard-coded role/stat colors into tokens
    - _Requirements: 11.1, 11.5_

  - [x] 2.6 Standardize on Iconsax icons across the primitive layer
    - Replace remaining raw `Icons.*` usages in shared widgets with Iconsax equivalents so no default Material glyphs remain
    - _Requirements: 11.5_

- [x] 3. Add loading and motion infrastructure
  - [x] 3.1 Implement shimmer skeletons and skeleton→content cross-fade
    - Create reusable skeleton widgets that match final row/card layouts; cross-fade from skeleton to content over `AppMotion.base` when a provider resolves
    - Add image caching helper that sets `memCacheWidth`/`memCacheHeight` to decode at display size
    - _Requirements: 12.1, 12.2, 12.4_

  - [x] 3.2 Implement staggered list entrance and shared-axis route transitions
    - Standard list entrance (`fadeIn + slideY(0.08)` over `base`, staggered by `AppMotion.stagger`, capped for large lists)
    - `CustomTransitionPage` helper for shared-axis detail pushes over `AppMotion.base`; slide-up for modal-ish pushes
    - Preserve tab scroll position/state via the existing indexed-stack shell
    - _Requirements: 12.3, 12.5, 12.6_

- [x] 4. Checkpoint - foundation ready
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Compact campaign card and cover-image fix
  - [x] 5.1 Ensure CampaignCoverHeader uses the caching image loader with gradient fallback
    - Confirm `CampaignCoverHeader` renders cover via `CachedNetworkImage` with placeholder + brand-gradient error/empty fallback
    - _Requirements: 2.3, 2.4, 2.6_

  - [x] 5.2 Implement the single shared compact CampaignCard
    - One `CampaignCard` with `CampaignCardLayout.horizontal` (cover 120px) and `compact` (cover 96px); render title, brand, budget value pill, slot progress; compact total height ≤ 210px
    - Replace the two divergent cards so Home and the Campaigns tab share this widget
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [ ]* 5.3 Write widget test for compact card height budget
    - **Property 9: Compact card height** — renders ≤ 210px tall for min/typical/max data with no overflow
    - **Validates: Requirements 1.2**

  - [x] 5.4 Standardize campaign queries to include cover_image_url and render 3 cover sites
    - Add `cover_image_url` to every campaign `select(...)` used by cards/detail
    - Render cover only in the home card, the campaign list card, and the campaign detail header (as hero); no other location
    - _Requirements: 2.1, 2.2, 2.5_

  - [ ]* 5.5 Write test for cover-image locations and fallback
    - **Property 1: Cover-image locations** — non-empty URL renders in exactly the three sites; empty URL falls back to brand gradient in all three
    - **Validates: Requirements 2.1, 2.2, 2.3**

- [x] 6. Applied-only Campaigns tab
  - [x] 6.1 Implement appliedCampaignsProvider and ApplicationStatus mapping
    - `appliedCampaignsProvider` returns the current user's applications joined with campaigns, augmented with `application_status` + `applied_at`, ordered newest application first
    - `ApplicationStatus` enum + extension mapping label/color (pending→warning, approved→success, rejected→error)
    - _Requirements: 3.1, 3.2, 3.3, 3.5_

  - [x] 6.2 Rebuild the Campaigns tab UI as applied-only
    - Compact `CampaignCard` list with status chip per card; empty state with "Browse campaigns" CTA; sanitized error via `ErrorUtils` + retry `PremiumButton`
    - _Requirements: 3.4, 3.6, 3.7_

  - [ ]* 6.3 Write test for applied-only visibility
    - **Property 3: Applied-only visibility** — every shown campaign has a matching application row for the current user; unapplied campaigns never appear
    - **Validates: Requirements 3.1, 3.2**

- [x] 7. Message soft-state backend migration
  - [x] 7.1 Add messages soft-state columns and RLS policies (Supabase migration)
    - Migration adds `is_unsent boolean default false`, `edited_at timestamptz`, `deleted_for uuid[] default '{}'`
    - RLS: `edit`/`unsend` allowed only when `auth.uid() = sender_id`; `deleted_for` updates allowed only for participants and may append only the caller's own id
    - _Requirements: 4.2, 5.1, 6.1, 6.2_

- [x] 8. Messaging data layer (soft-state model + actions)
  - [x] 8.1 Implement MessageView parsing and visibleMessages
    - `MessageView` parses row incl. `is_unsent`, `edited_at`, `deleted_for`; displayed body = `is_unsent ? "" : content`
    - Pure `visibleMessages(all, currentUserId)` excludes messages the current user deleted-for-me, preserving ascending order
    - _Requirements: 5.3, 6.3, 6.5_

  - [ ]* 8.2 Write property test for visibleMessages
    - **Property 8: Visible-message order & filtering** — order-preserving, returns exactly not-deleted-for-me messages, pure and idempotent
    - **Validates: Requirements 6.3, 6.5**

  - [x] 8.3 Implement editMessage, unsendMessage, and deleteForMe provider actions
    - `editMessage` requires sender + non-empty trimmed content + not-unsent; sets content and `edited_at`
    - `unsendMessage` requires sender; sets `is_unsent = true` (terminal)
    - `deleteForMe` appends caller id to `deleted_for` with set semantics (any participant)
    - _Requirements: 4.2, 4.4, 4.5, 4.6, 5.1, 5.3, 5.4, 5.5, 6.1, 6.2, 6.4_

  - [ ]* 8.4 Write property tests for message action authorization and terminality
    - **Property 6: Edit authorization** — edit/unsend succeed only for the sender; otherwise false, no state change (**Validates: Requirements 4.4, 5.5**)
    - **Property 5: Unsend terminality** — after unsend, content empty for both and `editMessage` returns false (**Validates: Requirements 5.2, 5.3, 4.6**)
    - **Property 4: Delete-for-me isolation** — after delete-for-me by u, hidden for u and still visible to the other participant (**Validates: Requirements 6.3, 6.4**)

- [x] 9. Premium Inbox and Chat screens
  - [x] 9.1 Build the premium Inbox
    - Conversation rows with `PremiumAvatar`, counterpart name, message preview, timestamp, unread badge; tap navigates to Chat for the conversation's user id; shimmer skeletons while loading
    - _Requirements: 13.1, 13.2, 13.3_

  - [x] 9.2 Build ChatBubble and grouped/date-separated message list
    - `ChatBubble` renders normal / edited ("edited" label) / unsent ("message unsent" placeholder, no actions); group consecutive same-sender messages; date separators across days
    - Render current-user messages in ascending order, excluding deleted-for-me (via `visibleMessages`)
    - _Requirements: 4.3, 5.2, 6.5, 13.4_

  - [x] 9.3 Wire long-press message actions sheet and realtime resilience
    - Long-press own non-unsent message opens `PremiumSheet` with Edit/Unsend/Delete-for-me/Copy dispatched via `onMessageAction`; edit sheet rejects empty-trimmed input
    - On realtime disconnect, show last snapshot and resubscribe on reconnect
    - _Requirements: 4.1, 5.2, 6.1, 13.5_

  - [ ]* 9.4 Write widget tests for ChatBubble states
    - Normal, edited label, unsent placeholder (no long-press actions), mine vs theirs
    - _Requirements: 4.3, 5.2_

- [x] 10. Checkpoint - messaging complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Resilient creator resolution
  - [x] 11.1 Implement CreatorView and resolveCreator with users fallback
    - `CreatorView.fromCreatorProfileRow` / `fromUserRow`; `resolveCreator` returns creator-profile-based view when present, else users-row-based view, else null only when no users row
    - Default values when no creator_profiles row: empty category, empty bio, zero rating, zero completed campaigns
    - _Requirements: 7.2, 7.3, 7.4, 7.5_

  - [ ]* 11.2 Write property test for creator resolution totality
    - **Property 2: Creator resolution totality** — `resolveCreator(id) ≠ null` whenever a users row exists; null implies no users row
    - **Validates: Requirements 7.2, 7.3, 7.4**

- [x] 12. Instagram-style creator profile and follow
  - [x] 12.1 Build CreatorProfileHeader and Creator_Profile_Screen
    - Header with avatar, name, handle, verification indicator, bio; horizontal stats row (followers · campaigns · rating); action row (follow, message, copy link)
    - Navigate to Creator_Profile_Screen from Top Creators by user id; "creator unavailable" empty state when `resolveCreator` returns null
    - _Requirements: 7.1, 7.4, 8.1, 8.2, 8.3_

  - [x] 12.2 Implement copy-profile-link and message actions
    - Copy link references the creator handle and excludes internal user ids (e.g. `rexo://profile/@handle`); message action navigates to Chat for the creator
    - _Requirements: 8.4, 8.5_

  - [x] 12.3 Implement optimistic follow/unfollow toggle
    - Flip follow indicator immediately then request follow/unfollow; on success reflect new state + follower count; on failure revert both and show retry message; unique follower-following pair enforced
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

  - [ ]* 12.4 Write property test for follow toggle convergence
    - **Property 7: Follow toggle convergence** — success reflects new state; failure reverts indicator and follower count to pre-toggle values
    - **Validates: Requirements 9.3, 9.4**

- [x] 13. Roll out the design system across remaining screens
  - [x] 13.1 Apply tokens and primitives to Home and auth screens
    - Home greeting header, segmented Campaigns/Creators `PremiumChip` toggle, compact `CampaignCard`, staggered entrance, shimmer; auth screens use `PremiumTextField`/`PremiumButton` with inline validation
    - _Requirements: 10.1, 10.2, 10.3, 11.1, 12.1, 12.3_

  - [x] 13.2 Apply tokens and primitives to campaign detail/apply/create screens
    - Cover hero header, sticky CTA, `SectionHeader` sections, application-status banner; apply/create forms use `PremiumTextField`/`PremiumButton`
    - _Requirements: 2.1, 10.1, 10.2, 11.1, 11.6_

  - [x] 13.3 Apply tokens and primitives to shop, wallet, notifications, and settings screens
    - Product cards, wallet balance hero, notification list glyphs, grouped settings rows using primitives; consistent app bars, shimmer skeletons, and `EmptyState`
    - _Requirements: 10.1, 10.2, 10.4, 11.1, 11.5, 12.1_

  - [x] 13.4 Apply tokens and primitives to remaining secondary screens
    - Seller profile/services/subscriptions/orders/disputes/reviews/coupons and admin shell adopt tokens + primitives, removing raw color literals and inline `GoogleFonts.poppins(...)`
    - _Requirements: 10.1, 10.2, 10.3, 11.5_

  - [ ]* 13.5 Add static-check test for token consistency
    - **Property 10: Token consistency** — no feature widget references a raw color literal or inline `GoogleFonts.poppins(...)`
    - **Validates: Requirements 10.2, 10.3**

- [x] 14. Push-notification FCM key fix (backend/config — separate from UI)
  - [x] 14.1 Fix FCM private-key decoding in the push service
    - Load the FCM service credential using a correctly decoded private key so dispatch does not fail with a key-encoding error; on auth failure log a sanitized error and record delivery as failed without crashing the request
    - Note: this is a backend/configuration concern outside the Flutter presentation layer, captured here for traceability
    - _Requirements: 14.1, 14.2, 14.3_

- [x] 15. Final checkpoint - ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional test sub-tasks and can be skipped for a faster MVP; core implementation tasks are never optional.
- Property-based test sub-tasks each reference one of the design's 10 correctness properties and the requirement clause it validates.
- Foundation (tokens → primitives → motion) is built first so composites and screens depend only on stable lower layers.
- Task 7 (Supabase migration + RLS) must land before the messaging data layer (task 8) and screens (task 9).
- Requirement 14 (FCM fix) is a backend/config task tracked separately from the Flutter UI work.
- Each task references specific requirement clauses for traceability; checkpoints provide incremental validation points.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "7.1"] },
    { "id": 1, "tasks": ["1.2", "2.1", "2.3", "2.4", "2.5", "8.1"] },
    { "id": 2, "tasks": ["2.2", "2.6", "3.1", "3.2", "5.1", "8.2", "8.3", "11.1", "14.1"] },
    { "id": 3, "tasks": ["5.2", "5.4", "6.1", "8.4", "9.1", "9.2", "11.2", "12.1"] },
    { "id": 4, "tasks": ["5.3", "5.5", "6.2", "9.3", "9.4", "12.2", "12.3", "13.1", "13.2", "13.3", "13.4"] },
    { "id": 5, "tasks": ["6.3", "12.4", "13.5"] }
  ]
}
```
