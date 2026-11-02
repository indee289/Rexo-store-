import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../profile/providers/profile_provider.dart';

/// Media kit — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over a brand-gradient `Container` holding a
/// letter-initial circle and two rows of stats split by 1px white dividers,
/// then a `PremiumCard` of explanatory text with the share button buried at
/// the bottom of it.
///
/// New layout: collapsing large title; the kit itself as a brand-filled card
/// that looks like something you would actually send a brand (real avatar, not
/// an initial, and a 2x2 stat grid instead of divider-split rows); the share
/// action promoted to a primary button directly under the card; and the
/// explanation demoted to a quiet section below it.
///
/// `currentUserProfileProvider` and the share text are unchanged.
class MediaKitScreen extends ConsumerWidget {
  const MediaKitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          const GlassLargeTitleHeader(title: 'Media kit', showBack: true),
          profileAsync.when(
            data: (profileState) =>
                SliverToBoxAdapter(child: _Body(profileState: profileState)),
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: GlassLoader(),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: GlassErrorState(
                title: 'Failed to load profile',
                onRetry: () => ref.invalidate(currentUserProfileProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.profileState});

  final ProfileState profileState;

  @override
  Widget build(BuildContext context) {
    final profile = profileState.profile;
    final roleProfile = profileState.roleProfile;
    final name = profile?['name'] as String? ?? 'Creator';
    final handle = profile?['username'] as String? ?? ''; // live: username
    final avatarUrl = profile?['profileImage'] as String?;
    final isVerified = profile?['isVerified'] == true;
    final completedCampaigns = roleProfile?['completed_campaigns'] as int? ?? 0;
    final rating = (roleProfile?['rating'] as num?)?.toDouble() ?? 0.0;
    final followers = roleProfile?['followers'] as int? ?? 0;
    final engagementRate =
        (roleProfile?['engagement_rate'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The kit itself.
          GlassSurface(
            level: GlassLevel.card,
            borderRadius: AppRadius.allXl,
            gradient: AppColors.primaryGradient,
            bordered: false,
            shadow: AppElevation.brand(false),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                PremiumAvatar(
                  imageUrl: avatarUrl,
                  name: name,
                  size: PremiumAvatar.sizeLg,
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
                        style: AppTextStyles.title1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        AppIcons.verify,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
                if (handle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$handle',
                    style: AppTextStyles.subheadline.copyWith(
                      color: Colors.white.withOpacity(0.78),
                    ),
                  ),
                ],
                AppSpacing.gapXl,
                // 2x2 grid instead of two divider-split rows.
                Row(
                  children: [
                    Expanded(
                      child: _KitStat(
                        value: _formatNumber(followers),
                        label: 'Followers',
                      ),
                    ),
                    Expanded(
                      child: _KitStat(
                        value: '${engagementRate.toStringAsFixed(1)}%',
                        label: 'Engagement',
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapLg,
                Row(
                  children: [
                    Expanded(
                      child: _KitStat(
                        value: '$completedCampaigns',
                        label: 'Campaigns',
                      ),
                    ),
                    Expanded(
                      child: _KitStat(
                        value: rating.toStringAsFixed(1),
                        label: 'Rating',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          AppSpacing.gapLg,
          GlassButton(
            label: 'Share media kit',
            icon: AppIcons.export_1,
            size: GlassButtonSize.large,
            onPressed: () {
              final shareHandle = handle.isNotEmpty ? '@$handle' : name;
              Share.share('Check out my Campster Media Kit: $shareHandle');
            },
          ),

          AppSpacing.gapXl,
          GlassCard(
            borderRadius: AppRadius.allLg,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlassIconBubble(
                  icon: AppIcons.info_circle,
                  size: 34,
                  iconSize: 17,
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Text(
                    'Share this media kit with brands to showcase your stats, '
                    'engagement, and campaign history. This summary helps '
                    'brands understand your reach and value as a creator.',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return '$num';
  }
}

/// A single stat inside the brand-filled kit card.
class _KitStat extends StatelessWidget {
  const _KitStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: AppTextStyles.title1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption1.copyWith(
            color: Colors.white.withOpacity(0.76),
          ),
        ),
      ],
    );
  }
}
