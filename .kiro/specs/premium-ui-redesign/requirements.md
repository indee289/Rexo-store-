# Requirements Document

## Introduction

This document specifies the requirements for the **Premium UI/UX Redesign** of the Rexo Marketplace Flutter app. The requirements are derived from the approved design document and describe the observable behavior the redesigned app must deliver.

The redesign pursues five product outcomes plus one operational fix:

1. Compact premium campaign cards with cover images rendering reliably in exactly three locations.
2. An applied-only Campaigns tab that shows the current user's applied campaigns.
3. A premium messaging inbox and chat with edit, unsend, and delete-for-me actions.
4. Instagram-style public creator profiles reachable from Top Creators (fixing the "creator not found" bug), with follow/unfollow, copy-profile-link, and message actions.
5. A cohesive, premium visual language across every screen (consistent theme tokens, premium icons, a custom component library, smooth motion, and fast perceived loading).
6. Resolution of the failing push-notification delivery caused by an FCM private-key encoding error.

The redesign extends the existing theme token system and shared widget library and reuses the current dependency set. Data-model changes are additive and backward compatible.

## Glossary

- **App**: The Rexo Marketplace Flutter client application.
- **Campaign_Card**: The single shared compact card widget used to render a campaign summary on the Home screen and the Campaigns tab.
- **Cover_Header**: The `CampaignCoverHeader` widget that renders a campaign's cover image with a brand-gradient fallback.
- **Campaigns_Tab**: The bottom-navigation destination that lists the current user's applied campaigns.
- **Inbox**: The messaging conversation list screen.
- **Chat_Screen**: The one-to-one conversation screen showing message bubbles.
- **Message_Store**: The backend messages data store and the providers that read/write it, including the soft-state columns `is_unsent`, `edited_at`, and `deleted_for`.
- **Creator_Resolver**: The `resolveCreator` logic (and `creatorProfileProvider`) that returns a normalized `CreatorView` for a creator `user_id`.
- **Creator_Profile_Screen**: The Instagram-style public profile screen for a creator.
- **Follow_Service**: The providers that manage follow/unfollow state and follower counts.
- **Theme_System**: The `lib/core/theme` token set (`AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`, `AppElevation`, `AppMotion`).
- **Component_Library**: The `lib/core/widgets` premium primitives (e.g. `PremiumButton`, `PremiumChip`, `PremiumSheet`, `PremiumAvatar`).
- **Current_User**: The signed-in user of the App.
- **Participant**: The sender or receiver of a given message.
- **Push_Service**: The backend service responsible for sending push notifications via FCM.
- **Application_Status**: The lifecycle status of a campaign application (pending, approved, or rejected).

## Requirements

### Requirement 1: Compact campaign cards

**User Story:** As a creator, I want compact campaign cards, so that I can scan more campaigns at a glance without oversized cards dominating the screen.

#### Acceptance Criteria

1. THE Campaign_Card SHALL render campaign title, brand, budget value, slot progress, and cover image within a single compact layout.
2. WHERE the compact list layout is used, THE Campaign_Card SHALL render at a height of 210 pixels or less for representative campaign data without layout overflow.
3. WHERE the horizontal home layout is used, THE Campaign_Card SHALL render the cover image at a height of 120 pixels.
4. WHERE the compact list layout is used, THE Campaign_Card SHALL render the cover image at a height of 96 pixels.
5. THE App SHALL use one shared Campaign_Card widget for both the Home screen and the Campaigns_Tab.

### Requirement 2: Reliable cover image rendering

**User Story:** As a user, I want campaign cover images to appear consistently, so that campaigns look complete and trustworthy.

#### Acceptance Criteria

1. WHEN a campaign has a non-empty cover image URL, THE App SHALL render the cover image in the home card, the campaign list card, and the campaign detail header.
2. THE App SHALL render a campaign cover image in no location other than the home card, the campaign list card, and the campaign detail header.
3. IF a campaign has an empty cover image URL, THEN THE Cover_Header SHALL render the brand gradient fallback in all three cover locations.
4. IF a cover image fails to load, THEN THE Cover_Header SHALL render the brand gradient fallback.
5. THE App SHALL include the cover image URL column in every campaign query that supplies data to a card or the detail header.
6. THE Cover_Header SHALL load cover images through the caching image loader to provide caching, placeholder, and error fallback behavior.

### Requirement 3: Applied-only Campaigns tab

**User Story:** As a creator, I want the Campaigns tab to show the campaigns I have applied to, so that I can track my applications in one place.

#### Acceptance Criteria

1. WHEN the Current_User opens the Campaigns_Tab, THE App SHALL display only campaigns for which an application row exists with `creator_id` equal to the Current_User.
2. THE Campaigns_Tab SHALL exclude any campaign for which the Current_User has no application row.
3. THE Campaigns_Tab SHALL order applied campaigns by application date with the newest application first.
4. THE Campaigns_Tab SHALL display the Application_Status for each applied campaign as a status chip.
5. WHERE the Application_Status is pending, approved, or rejected, THE App SHALL display the corresponding label and status color.
6. IF the Current_User has no applied campaigns, THEN THE Campaigns_Tab SHALL display an empty state with a call to action to browse campaigns.
7. IF the applied-campaigns query fails, THEN THE App SHALL display a sanitized error message with a retry control.

### Requirement 4: Edit message

**User Story:** As a message sender, I want to edit a message I sent, so that I can correct mistakes after sending.

#### Acceptance Criteria

1. WHEN the Current_User long-presses a message they sent that is not unsent, THE Chat_Screen SHALL present an edit action.
2. WHEN the sender confirms an edit with non-empty trimmed content, THE Message_Store SHALL update the message content and set the edited timestamp.
3. WHEN a message has a non-null edited timestamp, THE Chat_Screen SHALL display an "edited" label on that message.
4. IF a user who is not the sender attempts to edit a message, THEN THE Message_Store SHALL reject the edit and leave the message unchanged.
5. IF the edit content is empty after trimming, THEN THE Message_Store SHALL reject the edit and leave the message unchanged.
6. IF the target message is already unsent, THEN THE Message_Store SHALL reject the edit and leave the message unchanged.

### Requirement 5: Unsend message

**User Story:** As a message sender, I want to unsend a message, so that its content is removed from both participants' view.

#### Acceptance Criteria

1. WHEN the sender chooses unsend for a message they sent, THE Message_Store SHALL set the message to unsent.
2. WHILE a message is unsent, THE Chat_Screen SHALL display an "message unsent" placeholder to both participants and expose no message actions for that message.
3. WHILE a message is unsent, THE Message_Store SHALL present the displayed content as empty for both participants.
4. IF an edit is attempted on an unsent message, THEN THE Message_Store SHALL reject the edit and leave the message unchanged.
5. IF a user who is not the sender attempts to unsend a message, THEN THE Message_Store SHALL reject the unsend and leave the message unchanged.

### Requirement 6: Delete message for me

**User Story:** As a conversation participant, I want to delete a message for myself, so that I can clear it from my view without affecting the other person.

#### Acceptance Criteria

1. WHEN a Participant chooses delete-for-me on a message, THE Message_Store SHALL append that Participant's user id to the message's deleted-for set.
2. THE Message_Store SHALL treat the deleted-for set with set semantics so that a Participant's id appears at most once.
3. WHEN the Current_User has deleted a message for themselves, THE Chat_Screen SHALL exclude that message from the Current_User's view.
4. WHEN one Participant deletes a message for themselves, THE Chat_Screen SHALL continue to display that message to the other Participant.
5. THE App SHALL display messages to the Current_User in ascending creation-time order, excluding messages the Current_User has deleted for themselves.

### Requirement 7: Resilient creator profile resolution

**User Story:** As a user, I want to open a creator's profile from Top Creators, so that I can view their details instead of a "creator not found" error.

#### Acceptance Criteria

1. WHEN the Current_User taps a creator in Top Creators, THE App SHALL navigate to the Creator_Profile_Screen for that creator's user id.
2. WHEN a creator profile row exists for a requested user id, THE Creator_Resolver SHALL return a normalized creator view built from the creator profile row.
3. IF no creator profile row exists but a user row exists for the requested user id, THEN THE Creator_Resolver SHALL return a normalized creator view built from the user row.
4. IF no user row exists for the requested user id, THEN THE Creator_Resolver SHALL return no creator and THE Creator_Profile_Screen SHALL display a "creator unavailable" empty state.
5. WHERE a creator has no creator profile row, THE Creator_Resolver SHALL provide default values of empty category, empty bio, zero rating, and zero completed campaigns.

### Requirement 8: Instagram-style creator profile

**User Story:** As a user, I want an Instagram-style creator profile, so that I can view a creator's identity, stats, and take actions in a familiar layout.

#### Acceptance Criteria

1. THE Creator_Profile_Screen SHALL display the creator avatar, name, handle, verification indicator, and bio.
2. THE Creator_Profile_Screen SHALL display a horizontal stats row containing follower count, campaign count, and rating.
3. THE Creator_Profile_Screen SHALL display a follow action, a message action, and a copy-profile-link action.
4. WHEN the Current_User selects the copy-profile-link action, THE App SHALL copy a safe profile link that references the creator handle and excludes internal user ids.
5. WHEN the Current_User selects the message action, THE App SHALL navigate to the Chat_Screen for that creator.

### Requirement 9: Follow and unfollow with optimistic updates

**User Story:** As a user, I want to follow or unfollow a creator, so that I can track creators I care about with immediate feedback.

#### Acceptance Criteria

1. WHEN the Current_User selects the follow action while not following the creator, THE App SHALL update the follow indicator to "following" immediately and request the follow operation.
2. WHEN the Current_User selects the follow action while following the creator, THE App SHALL update the follow indicator to "follow" immediately and request the unfollow operation.
3. WHEN a follow or unfollow operation succeeds, THE App SHALL reflect the new follow state and the updated follower count.
4. IF a follow or unfollow operation fails, THEN THE App SHALL revert the follow indicator and follower count to their pre-toggle values and display a retry message.
5. THE Follow_Service SHALL maintain a unique follower-following pair so that duplicate follows are rejected.

### Requirement 10: Consistent premium theme tokens

**User Story:** As a user, I want a consistent premium visual language, so that the app feels cohesive across every screen in both light and dark themes.

#### Acceptance Criteria

1. THE App SHALL source all colors, text styles, spacing, radii, elevation, and motion values from the Theme_System tokens.
2. THE App SHALL render feature screens without raw color literals in feature widgets.
3. THE App SHALL render feature text without inline font construction in feature widgets, using the shared text style scale instead.
4. THE App SHALL apply consistent app bar styling with a surface background, zero base elevation, a scrolled-under elevation, a premium back control, and the standard title text style.
5. THE App SHALL apply the theme tokens consistently in both light and dark themes.

### Requirement 11: Premium component library and icons

**User Story:** As a user, I want custom premium components instead of a stock Material look, so that the app feels polished and branded.

#### Acceptance Criteria

1. THE App SHALL render primary, tonal, outline, and ghost actions using the Component_Library button rather than stock Material buttons.
2. WHEN a Component_Library button is configured with no action, THE App SHALL render the button in a disabled style and ignore taps.
3. WHILE a Component_Library button is in a loading state, THE App SHALL display a spinner and ignore taps on that button.
4. WHEN the Current_User presses a Component_Library primitive, THE App SHALL animate a press-scale feedback within the fast motion duration.
5. THE App SHALL render icons from the premium Iconsax icon pack in place of default Material glyphs.
6. THE App SHALL present modal bottom sheets through the Component_Library sheet primitive with a grab handle, a title row, and safe-area padding.

### Requirement 12: Fast perceived loading and smooth motion

**User Story:** As a user, I want fast, smooth loading, so that the app feels responsive while data loads.

#### Acceptance Criteria

1. WHILE list or screen data is loading, THE App SHALL display a shimmer skeleton that matches the final content layout.
2. WHEN a data provider resolves, THE App SHALL cross-fade from the skeleton to the content within the base motion duration.
3. WHEN a list first paints, THE App SHALL animate list items with a staggered fade-and-slide entrance.
4. THE App SHALL cache cover and avatar images and decode them at their display size to reduce memory usage.
5. WHEN pushing a detail route, THE App SHALL apply a shared-axis transition within the base motion duration.
6. WHEN switching bottom-navigation tabs, THE App SHALL preserve each tab's scroll position and state.

### Requirement 13: Premium messaging inbox

**User Story:** As a user, I want a premium inbox, so that I can browse conversations clearly and access them quickly.

#### Acceptance Criteria

1. THE Inbox SHALL display each conversation with a premium avatar, the counterpart name, a message preview, and a timestamp.
2. WHERE a conversation has unread messages, THE Inbox SHALL display an unread badge.
3. WHEN the Current_User taps a conversation, THE App SHALL navigate to the Chat_Screen for that conversation's user id.
4. THE Chat_Screen SHALL group consecutive messages from the same sender and display date separators between messages on different days.
5. IF the realtime message channel disconnects, THEN THE Chat_Screen SHALL display the most recent message snapshot and resubscribe when the connection is restored.

### Requirement 14: Push notification delivery fix

**User Story:** As a user, I want to reliably receive push notifications, so that I stay informed of relevant activity.

#### Acceptance Criteria

1. THE Push_Service SHALL load the FCM service credential using a correctly decoded private key so that push dispatch does not fail with a key-encoding error.
2. WHEN a notification-triggering event occurs, THE Push_Service SHALL dispatch the notification to the target device without a private-key encoding failure.
3. IF the Push_Service cannot authenticate with the messaging provider, THEN THE Push_Service SHALL log a sanitized error and record the delivery as failed without crashing the request.

> Note: Requirement 14 addresses a backend/configuration concern (FCM private-key encoding) that is outside the Flutter presentation-layer scope of this redesign. It is captured here for traceability but is expected to be remediated in the backend push service configuration rather than in the UI code covered by the rest of this spec.
