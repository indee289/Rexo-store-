import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../profile/providers/profile_provider.dart';

class MediaKitScreen extends ConsumerWidget {
  const MediaKitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Media Kit', showBack: true),
      body: profileAsync.when(
        data: (profileState) => _buildContent(context, profileState),
        loading: () => const ShimmerLoading(),
        error: (error, _) => EmptyState(
          icon: Iconsax.warning_2,
          title: 'Failed to load profile',
          ctaLabel: 'Retry',
          ctaIcon: Iconsax.refresh,
          onCta: () => ref.invalidate(currentUserProfileProvider),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProfileState profileState) {
    final profile = profileState.profile;
    final roleProfile = profileState.roleProfile;
    final name = profile?['name'] as String? ?? 'Creator';
    final handle = profile?['handle'] as String? ?? '';
    final isVerified = (profile?['is_verified'] == true);
    final completedCampaigns =
        roleProfile?['completed_campaigns'] as int? ?? 0;
    final rating = (roleProfile?['rating'] as num?)?.toDouble() ?? 0.0;
    final followers = roleProfile?['followers'] as int? ?? 0;
    final engagementRate =
        (roleProfile?['engagement_rate'] as num?)?.toDouble() ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Media Kit Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.allXl,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (isVerified)
                        const VerifiedBadge(size: 20, color: Colors.white),
                    ],
                  ),
                  if (handle.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '@$handle',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  // Stats grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        value: _formatNumber(followers),
                        label: 'Followers',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        value: '${engagementRate.toStringAsFixed(1)}%',
                        label: 'Engagement',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        value: '$completedCampaigns',
                        label: 'Campaigns',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        value: rating.toStringAsFixed(1),
                        label: 'Rating',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Info section
          PremiumCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About Your Media Kit', style: AppTextStyles.h6),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Share this media kit with brands to showcase your stats, engagement, and campaign history. This summary helps brands understand your reach and value as a creator.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                PremiumButton(
                  label: 'Share Media Kit',
                  variant: PremiumButtonVariant.outline,
                  icon: Iconsax.export_1,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h5.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption
              .copyWith(color: Colors.white.withOpacity(0.7)),
        ),
      ],
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
