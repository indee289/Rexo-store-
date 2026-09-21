import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/role_badge.dart';
import '../models/creator_view.dart';

/// Instagram-style public creator profile header (Layer-3 composite).
///
/// Composes only Component_Library primitives ([PremiumAvatar],
/// [PremiumButton], [PremiumIconButton], [StatPill]) and Theme_System tokens —
/// no raw color literals or inline font construction. See design
/// "Components and Interfaces > CreatorProfileHeader".
///
/// Layout (top → bottom):
///   * large ringed [PremiumAvatar] with an optional verified overlay,
///   * name + verification indicator + `@handle` (+ tonal category pill),
///   * bio (when present),
///   * a horizontal stats row (Followers · Campaigns · Rating) via [StatPill],
///   * an action row: Follow/Following ([PremiumButton], gradient when not yet
///     following), Message ([PremiumButton] glass), and a Copy-link
///     [PremiumIconButton].
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
    final colorScheme = Theme.of(context).colorScheme;
    final name = creator.name.isEmpty ? 'Creator' : creator.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar with story-style ring + verified overlay.
        PremiumAvatar(
          imageUrl: creator.avatarUrl,
          name: name,
          size: PremiumAvatar.sizeXl,
          showRing: true,
          isVerified: creator.isVerified,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Name + verification indicator.
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
                style: AppTextStyles.h4.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (creator.isVerified) ...[
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Iconsax.verify,
                size: 20,
                color: AppColors.verified,
              ),
            ],
          ],
        ),

        // Handle.
        if (creator.handle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '@${creator.handle}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],

        // Category pill (tonal, brand-tinted).
        if (creator.category.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: AppRadius.pillAll,
            ),
            child: Text(
              creator.category,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        // Bio.
        if (creator.bio.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            creator.bio,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // Horizontal stats row: Followers · Campaigns · Rating.
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppRadius.allLg,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatPill(
                icon: Iconsax.people,
                value: _formatCount(followerCount),
                label: 'Followers',
              ),
              _statDivider(context),
              StatPill(
                icon: Iconsax.medal_star,
                value: creator.campaignsCompleted.toString(),
                label: 'Campaigns',
              ),
              _statDivider(context),
              StatPill(
                icon: Iconsax.star_1,
                value: creator.rating.toStringAsFixed(1),
                label: 'Rating',
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Action row: Follow/Following · Message · Copy link.
        Row(
          children: [
            Expanded(
              child: PremiumButton(
                label: isFollowing ? 'Following' : 'Follow',
                icon: isFollowing ? Iconsax.user_tick : Iconsax.user_add,
                onPressed: onToggleFollow,
                variant: isFollowing
                    ? PremiumButtonVariant.outline
                    : PremiumButtonVariant.filled,
                gradient: !isFollowing,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PremiumButton(
                label: 'Message',
                icon: Iconsax.message,
                onPressed: onMessage,
                variant: PremiumButtonVariant.glass,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            PremiumIconButton(
              icon: Iconsax.link,
              onPressed: onCopyLink,
              background: true,
              tooltip: 'Copy profile link',
            ),
          ],
        ),
      ],
    );
  }

  Widget _statDivider(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: Theme.of(context).dividerColor,
      );

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
