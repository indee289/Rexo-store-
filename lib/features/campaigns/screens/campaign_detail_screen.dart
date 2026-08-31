import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
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
    final campaignAsync =
        ref.watch(campaignDetailProvider(campaignId));
    final hasApplied = ref.watch(hasAppliedProvider(campaignId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) return _buildNotFound(context);
          return _buildContent(context, ref, campaign, hasApplied);
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
  ) {
    final title =
        (campaign['title'] ?? 'Untitled Campaign').toString();
    final coverImageUrl =
        (campaign['cover_image_url'] ?? '').toString();
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
    final brandName =
        (brandInfo?['name'] ?? 'Unknown Brand').toString();
    final brandAvatar = brandInfo?['avatar_url'] as String?;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return CustomScrollView(
      slivers: [
        // ── Cover image + transparent back button ──────────────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: cs.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leadingWidth: 60,
          leading: Padding(
            padding:
                const EdgeInsets.only(left: AppSpacing.sm),
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
              height: 200,
              overlay: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Applied banner
                if (hasApplied.valueOrNull == true) ...[
                  _buildAppliedBanner(),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Brand row
                _buildBrandRow(context, brandName, brandAvatar),
                const SizedBox(height: AppSpacing.lg),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 12),

                // Chips row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (budget != null)
                      _chip(
                          '₹${NumberFormat.compact().format(budget)}',
                          AppColors.primary),
                    if (deadline != null)
                      _chip(
                          'Due ${_formatShortDeadline(deadline)}',
                          AppColors.textSecondary),
                    if (category.isNotEmpty)
                      _chip(category, AppColors.accentPurple),
                    if (platform.isNotEmpty)
                      _chip(platform, AppColors.accentTeal),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats row
                _buildStatsRow(context, budget, perCreatorPayout, deadline),

                const SizedBox(height: 20),

                // Divider
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 16),

                // Description
                if (description.isNotEmpty) ...[
                  const SectionHeader(title: 'About Campaign'),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Guidelines
                if (guidelines.isNotEmpty) ...[
                  const SectionHeader(title: 'Requirements'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: surfaceAlt,
                      borderRadius: AppRadius.allMd,
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      guidelines,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Slots
                const SectionHeader(title: 'Slots'),
                SlotsIndicator(
                  filledSlots: filledSlots is int ? filledSlots : 0,
                  totalSlots: totalSlots is int ? totalSlots : 0,
                ),
                const SizedBox(height: 16),

                // Min followers
                if (minFollowers != null && minFollowers > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.08),
                      borderRadius: AppRadius.allSm,
                      border: Border.all(
                          color: AppColors.warning.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.people,
                            size: 18, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Minimum ${NumberFormat.compact().format(minFollowers)} followers required',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppliedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: AppRadius.allMd,
        border: Border.all(
            color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: const [
          Icon(Iconsax.tick_circle,
              size: 20, color: AppColors.success),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "You've applied to this campaign",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandRow(
      BuildContext context, String brandName, String? brandAvatar) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        PremiumAvatar(
          imageUrl: brandAvatar,
          name: brandName,
          size: 40,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                brandName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              Text(
                'Brand',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Icon(Iconsax.verify,
            color: AppColors.primary, size: 18),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, dynamic budget,
      dynamic perCreatorPayout, String? deadline) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            'Budget',
            budget != null
                ? '₹${NumberFormat.compact().format(budget)}'
                : 'N/A',
            Iconsax.wallet_2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context,
            'Per Creator',
            perCreatorPayout != null
                ? '₹${NumberFormat.compact().format(perCreatorPayout)}'
                : 'N/A',
            Iconsax.money_recive,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context,
            'Deadline',
            deadline != null
                ? _formatShortDeadline(deadline)
                : 'N/A',
            Iconsax.calendar_1,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
      BuildContext context, String label, String value, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.14 : 0.08),
        borderRadius: AppRadius.allMd,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
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
            subtitle: 'This campaign may have been removed.',
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
            ShimmerCard(height: 200),
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

  Widget _buildError(
      BuildContext context, WidgetRef ref, String error) {
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
              onPressed: () => ref
                  .invalidate(campaignDetailProvider(campaignId)),
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

/// Sticky bottom apply bar — white bg, 1px top border.
class CampaignDetailBottomBar extends ConsumerWidget {
  final String campaignId;

  const CampaignDetailBottomBar({
    super.key,
    required this.campaignId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasApplied = ref.watch(hasAppliedProvider(campaignId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        border: Border(
          top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1),
        ),
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
              onPressed: () =>
                  context.push('/campaigns/$campaignId/apply'),
            );
          },
          loading: () => const PremiumButton(
            label: 'Apply Now',
            loading: true,
            onPressed: null,
          ),
          error: (_, __) => PremiumButton(
            label: 'Apply Now',
            icon: Iconsax.send_2,
            onPressed: () =>
                context.push('/campaigns/$campaignId/apply'),
          ),
        ),
      ),
    );
  }
}
