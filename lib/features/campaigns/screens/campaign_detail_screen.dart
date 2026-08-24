import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/campaign_cover_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/campaigns_provider.dart';
import '../widgets/slots_indicator.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final String campaignId;

  const CampaignDetailScreen({
    super.key,
    required this.campaignId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final campaignAsync = ref.watch(campaignDetailProvider(campaignId));
    final hasApplied = ref.watch(hasAppliedProvider(campaignId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) {
            return _buildNotFound(context);
          }
          return _buildContent(context, ref, campaign, hasApplied, theme);
        },
        loading: () => _buildLoading(),
        error: (error, _) =>
            _buildError(context, ref, ErrorUtils.sanitize(error)),
      ),
      bottomNavigationBar: campaignAsync.whenOrNull(
        data: (campaign) {
          if (campaign == null) return null;
          return CampaignDetailBottomBar(campaignId: campaignId);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> campaign,
    AsyncValue<bool> hasApplied,
    ThemeData theme,
  ) {
    final title = (campaign['title'] ?? 'Untitled Campaign').toString();
    final coverImageUrl = (campaign['cover_image_url'] ?? '').toString();
    final description = (campaign['description'] ?? '').toString();
    final budget = campaign['budget'];
    final perCreatorPayout = campaign['per_creator_payout'];
    final platform = (campaign['platform'] ?? '').toString();
    final category = (campaign['category'] ?? '').toString();
    final deadline = campaign['deadline'] as String?;
    final guidelines = (campaign['guidelines'] ?? '').toString();
    final minFollowers = campaign['min_followers'];
    final filledSlots = campaign['filled_slots'] ?? 0;
    final totalSlots = campaign['total_slots'] ?? 0;
    final brandInfo = campaign['users'] as Map<String, dynamic>?;
    final brandName = (brandInfo?['name'] ?? 'Unknown Brand').toString();
    final brandAvatar = brandInfo?['avatar_url'] as String?;

    return CustomScrollView(
      slivers: [
        // Hero section — cover render site #3 (the ONLY detail cover),
        // rendered through the shared CampaignCoverHeader so it caches,
        // shows a placeholder, and falls back to the brand gradient exactly
        // like the home card and the campaign list card.
        SliverAppBar(
          expandedHeight: 210,
          pinned: true,
          backgroundColor: AppColors.primary,
          leadingWidth: 60,
          leading: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: PremiumIconButton(
              icon: Iconsax.arrow_left,
              background: true,
              color: Colors.white,
              tooltip: 'Back',
              onPressed: () => context.pop(),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: CampaignCoverHeader(
              coverImageUrl: coverImageUrl,
              height: 210,
              overlay: [
                // Bottom-up scrim so the title/platform stay legible over
                // any cover image.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.xl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.h3.copyWith(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (platform.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: AppRadius.allMd,
                          ),
                          child: Text(
                            platform,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Body content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Application-status banner (shown once the user has applied).
                if (hasApplied.valueOrNull == true) ...[
                  _buildAppliedBanner(),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Brand info row
                _buildBrandRow(brandName, brandAvatar, theme),
                const SizedBox(height: AppSpacing.xl),

                // Stats row
                _buildStatsRow(budget, perCreatorPayout, deadline, theme),
                const SizedBox(height: AppSpacing.sm),

                // Description
                if (description.isNotEmpty) ...[
                  const SectionHeader(title: 'Description'),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Guidelines
                if (guidelines.isNotEmpty) ...[
                  const SectionHeader(title: 'Requirements & Guidelines'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.allMd,
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(
                      guidelines,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Platform and Category badges
                if (platform.isNotEmpty || category.isNotEmpty) ...[
                  Row(
                    children: [
                      if (platform.isNotEmpty)
                        _buildBadge(platform, AppColors.primary),
                      if (platform.isNotEmpty && category.isNotEmpty)
                        const SizedBox(width: AppSpacing.sm),
                      if (category.isNotEmpty)
                        _buildBadge(category, AppColors.secondary),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Slots progress
                const SectionHeader(title: 'Slots'),
                SlotsIndicator(
                  filledSlots: filledSlots is int ? filledSlots : 0,
                  totalSlots: totalSlots is int ? totalSlots : 0,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Min followers
                if (minFollowers != null && minFollowers > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: AppRadius.allSm,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.people,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Minimum ${NumberFormat.compact().format(minFollowers)} followers required',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Bottom padding for the sticky CTA bar.
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Banner shown at the top of the body once the signed-in user has applied
  /// to this campaign (driven by [hasAppliedProvider]).
  Widget _buildAppliedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.tick_circle, size: 20, color: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You've applied to this campaign",
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Track the status in your applications.",
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandRow(String brandName, String? brandAvatar, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          PremiumAvatar(
            imageUrl: brandAvatar,
            name: brandName,
            size: 44,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brandName,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Brand', style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(
            Iconsax.verify,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
      dynamic budget, dynamic perCreatorPayout, String? deadline, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Budget',
            budget != null
                ? '\u20B9${NumberFormat.compact().format(budget)}'
                : 'N/A',
            Iconsax.wallet_2,
            theme,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            'Per Creator',
            perCreatorPayout != null
                ? '\u20B9${NumberFormat.compact().format(perCreatorPayout)}'
                : 'N/A',
            Iconsax.money_recive,
            theme,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            'Deadline',
            deadline != null ? _formatShortDeadline(deadline) : 'N/A',
            Iconsax.calendar_1,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: PremiumIconButton(
                icon: Iconsax.arrow_left,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
            ),
          ),
          EmptyState(
            icon: Iconsax.document,
            title: 'Campaign not found',
            subtitle: 'This campaign may have been removed or is unavailable.',
            cta: PremiumButton(
              label: 'Go Back',
              icon: Iconsax.arrow_left,
              expand: false,
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerCard(height: 180),
            SizedBox(height: AppSpacing.lg),
            ShimmerLine(width: 200, height: 20),
            SizedBox(height: AppSpacing.md),
            ShimmerLine(height: 14),
            SizedBox(height: AppSpacing.sm),
            ShimmerLine(width: 150, height: 14),
            SizedBox(height: AppSpacing.xl),
            ShimmerCard(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: PremiumIconButton(
                icon: Iconsax.arrow_left,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
            ),
          ),
          EmptyState(
            icon: Iconsax.warning_2,
            title: 'Failed to load campaign',
            subtitle: error,
            cta: PremiumButton(
              label: 'Retry',
              icon: Iconsax.refresh,
              variant: PremiumButtonVariant.tonal,
              expand: false,
              onPressed: () => ref.invalidate(campaignDetailProvider(campaignId)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDeadline(String deadline) {
    try {
      final date = DateTime.parse(deadline);
      return DateFormat('MMM dd').format(date);
    } catch (_) {
      return deadline;
    }
  }
}

/// Sticky bottom bar for campaign detail that shows the premium Apply CTA.
class CampaignDetailBottomBar extends ConsumerWidget {
  final String campaignId;

  const CampaignDetailBottomBar({
    super.key,
    required this.campaignId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasApplied = ref.watch(hasAppliedProvider(campaignId));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: hasApplied.when(
          data: (applied) {
            if (applied) {
              return const PremiumButton(
                label: 'Already Applied',
                icon: Iconsax.tick_circle,
                variant: PremiumButtonVariant.tonal,
                onPressed: null,
              );
            }
            return PremiumButton(
              label: 'Apply Now',
              icon: Iconsax.send_2,
              gradient: true,
              onPressed: () => context.push('/campaigns/$campaignId/apply'),
            );
          },
          loading: () => const PremiumButton(
            label: 'Apply Now',
            gradient: true,
            loading: true,
            onPressed: null,
          ),
          error: (_, __) => PremiumButton(
            label: 'Apply Now',
            icon: Iconsax.send_2,
            gradient: true,
            onPressed: () => context.push('/campaigns/$campaignId/apply'),
          ),
        ),
      ),
    );
  }
}
