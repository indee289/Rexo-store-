import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../models/creator_view.dart';
import '../providers/creators_provider.dart';
import '../widgets/creator_profile_header.dart';

/// Instagram-style public creator profile screen.
///
/// Navigated to from the Top Creators section on the home screen via
/// `/creators/{userId}`. It watches the resilient [creatorViewProvider] (which
/// falls back to the `users` row) so tapping a creator that only exists as a
/// `users` row no longer shows "creator not found" — the previous bug. A
/// "creator unavailable" [EmptyState] now only appears when the user id is
/// genuinely unknown (Requirement 7.4).
///
/// This is a [ConsumerStatefulWidget] so it can hold **optimistic** follow
/// state ([_optimisticFollowing] / [_optimisticCount]). [isFollowingProvider]
/// and [followerCountProvider] remain the source of truth; the optimistic
/// overrides only provide immediate visual feedback until the providers
/// reconcile after a successful toggle (Requirements 9.1–9.4).
class CreatorProfileScreen extends ConsumerStatefulWidget {
  final String creatorUserId;

  const CreatorProfileScreen({super.key, required this.creatorUserId});

  @override
  ConsumerState<CreatorProfileScreen> createState() =>
      _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends ConsumerState<CreatorProfileScreen> {
  /// Optimistic follow indicator. `null` => defer to [isFollowingProvider].
  bool? _optimisticFollowing;

  /// Optimistic follower count. `null` => defer to [followerCountProvider].
  int? _optimisticCount;

  String get _creatorUserId => widget.creatorUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creatorAsync = ref.watch(creatorViewProvider(_creatorUserId));
    final isFollowingAsync = ref.watch(isFollowingProvider(_creatorUserId));
    final followerCountAsync = ref.watch(followerCountProvider(_creatorUserId));

    // Reconcile: once the providers catch up to a successful optimistic
    // toggle, drop the local overrides so the providers resume as the single
    // source of truth (flicker-free — we only clear when they already match).
    _maybeReconcile(isFollowingAsync, followerCountAsync);

    // Displayed values: optimistic override wins, otherwise provider truth.
    final bool displayedFollowing = _optimisticFollowing ??
        isFollowingAsync.maybeWhen<bool>(data: (v) => v, orElse: () => false);
    final int displayedCount = _optimisticCount ??
        followerCountAsync.maybeWhen<int>(data: (v) => v, orElse: () => 0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Creator Profile', showBack: true),
      body: creatorAsync.when(
        data: (creator) {
          // Genuinely unknown user id → creator unavailable (Req 7.4).
          if (creator == null) {
            return const EmptyState(
              icon: Iconsax.user_remove,
              title: 'Creator unavailable',
              subtitle:
                  "We couldn't find this creator's profile. They may no "
                  'longer be available.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            child: CreatorProfileHeader(
              creator: creator,
              isFollowing: displayedFollowing,
              followerCount: displayedCount,
              onToggleFollow: () => _toggleFollow(
                currentlyFollowing: displayedFollowing,
                currentCount: displayedCount,
              ),
              onMessage: () => context.push('/messages/$_creatorUserId'),
              onCopyLink: () => _copyProfileLink(creator),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              'Failed to load creator profile',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  /// Clears the optimistic overrides once the providers have resolved to the
  /// same values, so [isFollowingProvider] / [followerCountProvider] resume as
  /// the source of truth. Scheduled post-frame to avoid setState-during-build.
  void _maybeReconcile(
    AsyncValue<bool> isFollowingAsync,
    AsyncValue<int> followerCountAsync,
  ) {
    if (_optimisticFollowing == null && _optimisticCount == null) return;

    final followingSettled =
        isFollowingAsync.maybeWhen(data: (v) => v, orElse: () => null);
    final countSettled =
        followerCountAsync.maybeWhen(data: (v) => v, orElse: () => null);
    if (followingSettled == null || countSettled == null) return;

    if (followingSettled == _optimisticFollowing &&
        countSettled == _optimisticCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _optimisticFollowing = null;
          _optimisticCount = null;
        });
      });
    }
  }

  /// Optimistic follow/unfollow toggle (Requirements 9.1–9.5).
  ///
  /// Flips the displayed follow indicator and follower count IMMEDIATELY, then
  /// performs the follow/unfollow request. On success the providers are already
  /// invalidated by [FollowActionsNotifier] and reconciliation clears the
  /// overrides. On failure both values are reverted to their pre-toggle state
  /// and a retry SnackBar is shown.
  ///
  /// The unique follower-following pair (Req 9.5) is guaranteed by the DB
  /// unique constraint plus the notifier's re-entry guard — this method never
  /// inserts directly, so no duplicate follow can be created.
  Future<void> _toggleFollow({
    required bool currentlyFollowing,
    required int currentCount,
  }) async {
    final target = !currentlyFollowing;

    // 1) Flip immediately for instant feedback.
    setState(() {
      _optimisticFollowing = target;
      _optimisticCount =
          (currentCount + (target ? 1 : -1)).clamp(0, 1 << 31).toInt();
    });

    // 2) Perform the request.
    final notifier = ref.read(followActionsProvider.notifier);
    final ok = target
        ? await notifier.follow(_creatorUserId)
        : await notifier.unfollow(_creatorUserId);

    if (!mounted) return;

    if (!ok) {
      // 3a) Revert both to pre-toggle values and prompt retry.
      setState(() {
        _optimisticFollowing = currentlyFollowing;
        _optimisticCount = currentCount;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Couldn't update follow. Try again.")),
        );
    }
    // 3b) On success the notifier has invalidated the follow providers; the
    // optimistic overrides remain until _maybeReconcile clears them once the
    // fresh provider values match, keeping the transition flicker-free.
  }

  /// Copies a **safe** profile link that references the creator handle and
  /// excludes internal user ids (Requirement 8.4).
  ///
  /// Format: `rexo://profile/@{handle}`. When the handle is empty we fall back
  /// to a name-derived slug, and finally to a generic `rexo://profile` link —
  /// never the internal `userId`.
  void _copyProfileLink(CreatorView creator) {
    final link = _buildProfileLink(creator);
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Profile link copied')),
      );
  }

  /// Builds the shareable deep link. Guarantees the internal [CreatorView.userId]
  /// is never included.
  String _buildProfileLink(CreatorView creator) {
    final handle = creator.handle.trim();
    if (handle.isNotEmpty) {
      return 'rexo://profile/@$handle';
    }

    final slug = creator.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isNotEmpty) {
      return 'rexo://profile/$slug';
    }

    return 'rexo://profile';
  }
}
