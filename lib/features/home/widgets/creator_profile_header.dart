import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/role_badge.dart';
import '../models/creator_view.dart';

/// Public creator profile header — liquid glass.
///
/// Layout (top to bottom):
///   * large ringed [PremiumAvatar] with an optional verified overlay,
///   * name + verification indicator + `@handle` (+ a brand-tinted category
///     chip),
///   * bio (when present),
///   * a stats row (Followers / Campaigns / Rating) on a glass pane,
///   * actions: Follow/Following, Message, and a copy-link icon button.
///
/// Was composed from the old `Premium*` primitives with an opaque stats
/// container and `colorScheme` opacities for text. Now uses [GlassCard],
/// [GlassChip], [GlassButton] and [GlassIconButton] with the colour tokens, so
/// the greys are consistent and the stats pane refracts the page behind it.
class CreatorProfileHeader extends StatelessWidget {
  /// Normalized creator to render.
  final CreatorView creator;

  /// Whether the current user currently follows [creator].
  final bool isFollowing;

  /// Follower count shown in the stats row.
  final int followerCount;

  /// Invoked when the follow/unfollow action is tapped.
  final VoidCallback onToggleFollow;

  /// Invoked when the message action is tapped.
  final VoidCallback onMessage;

  /// Invoked when the copy-profile-link action is tapped.
  final VoidCallback onCopyLink;

  const CreatorProfileHeader({
    super.key,
    required this.creator,
    required this.isFollowing,
    required this.followerCount,
    required this.onToggleFollow,
    required this.onMessage,
    required this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    final name = creator.name.isEmpty ? 'Creator' : creator.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PremiumAvatar(
          imageUrl: creator.avatarUrl,
          name: name,
          size: PremiumAvatar.sizeXl,
          showRing: true,
          isVerified: creator.isVerified,
        ),
        AppSpacing.gapLg,

        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title2
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
            if (creator.isVerified) ...[
              const SizedBox(width: AppSpacing.xs),
              const Icon(AppIcons.verify, size: 20, color: AppColors.verified),
            ],
          ],
        ),

        if (creator.handle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '@${creator.handle}',
            style: AppTextStyles.subheadline
                .copyWith(color: AppColors.textSecondary),
          ),
        ],

        if (creator.category.isNotEmpty) ...[
          AppSpacing.gapSm,
          GlassChip.status(
            label: creator.category,
            color: AppColors.primary,
          ),
        ],

        if (creator.bio.isNotEmpty) ...[
          AppSpacing.gapLg,
          Text(
            creator.bio,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],

        AppSpacing.gapXl,

        GlassCard(
          borderRadius: AppRadius.allLg,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatPill(
                icon: AppIcons.people,
                value: _formatCount(followerCount),
                label: 'Followers',
              ),
              const _StatDivider(),
              StatPill(
                icon: AppIcons.medal_star,
                value: creator.campaignsCompleted.toString(),
                label: 'Campaigns',
              ),
              const _StatDivider(),
              StatPill(
                icon: AppIcons.star_1,
                value: creator.rating.toStringAsFixed(1),
                label: 'Rating',
              ),
            ],
          ),
        ),

        AppSpacing.gapXl,

        Row(
          children: [
            Expanded(
              child: GlassButton(
                label: isFollowing ? 'Following' : 'Follow',
                icon: isFollowing ? AppIcons.user_tick : AppIcons.user_add,
                onPressed: onToggleFollow,
                variant: isFollowing
                    ? GlassButtonVariant.outline
                    : GlassButtonVariant.filled,
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: GlassButton.glass(
                label: 'Message',
                icon: AppIcons.message,
                onPressed: onMessage,
              ),
            ),
            AppSpacing.gapMd,
            GlassIconButton(
              icon: AppIcons.link,
              onTap: onCopyLink,
              tooltip: 'Copy profile link',
              size: 50,
            ),
          ],
        ),
      ],
    );
  }

  /// Formats a follower count into a compact form (1.2K / 3.4M).
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Hairline rule between stats.
class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.border);
  }
}
