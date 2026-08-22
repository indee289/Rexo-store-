import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/avatar_widget.dart';
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
    final campaignAsync = ref.watch(campaignDetailProvider(campaignId));
    final hasApplied = ref.watch(hasAppliedProvider(campaignId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) {
            return _buildNotFound(context);
          }
          return _buildContent(context, ref, campaign, hasApplied);
        },
        loading: () => _buildLoading(),
        error: (error, _) => _buildError(context, ref, ErrorUtils.sanitize(error)),
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
    final title = campaign['title'] ?? 'Untitled Campaign';
    final description = campaign['description'] ?? '';
    final budget = campaign['budget'];
    final perCreatorPayout = campaign['per_creator_payout'];
    final platform = campaign['platform'] ?? '';
    final category = campaign['category'] ?? '';
    final deadline = campaign['deadline'];
    final guidelines = campaign['guidelines'] ?? '';
    final minFollowers = campaign['min_followers'];
    final filledSlots = campaign['filled_slots'] ?? 0;
    final totalSlots = campaign['total_slots'] ?? 0;
    final brandInfo = campaign['users'] as Map<String, dynamic>?;
    final brandName = brandInfo?['name'] ?? 'Unknown Brand';
    final brandAvatar = brandInfo?['avatar_url'] as String?;

    return CustomScrollView(
      slivers: [
        // Hero section
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (platform.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
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
              ),
            ),
          ),
        ),

        // Body content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand info row
                _buildBrandRow(brandName, brandAvatar),
                const SizedBox(height: 20),

                // Stats row
                _buildStatsRow(budget, perCreatorPayout, deadline),
                const SizedBox(height: 20),

                // Description
                if (description.isNotEmpty) ...[
                  _buildSectionTitle('Description'),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Guidelines
                if (guidelines.isNotEmpty) ...[
                  _buildSectionTitle('Requirements & Guidelines'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      guidelines,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Platform and Category badges
                Row(
                  children: [
                    if (platform.isNotEmpty) _buildBadge(platform, AppColors.primary),
                    if (platform.isNotEmpty && category.isNotEmpty)
                      const SizedBox(width: 8),
                    if (category.isNotEmpty)
                      _buildBadge(category, AppColors.secondary),
                  ],
                ),
                const SizedBox(height: 20),

                // Slots progress
                _buildSectionTitle('Slots'),
                const SizedBox(height: 8),
                SlotsIndicator(
                  filledSlots: filledSlots is int ? filledSlots : 0,
                  totalSlots: totalSlots is int ? totalSlots : 0,
                ),
                const SizedBox(height: 16),

                // Min followers
                if (minFollowers != null && minFollowers > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.people,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Minimum ${NumberFormat.compact().format(minFollowers)} followers required',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Bottom padding for button
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandRow(String brandName, String? brandAvatar) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AvatarWidget(
            url: brandAvatar,
            name: brandName,
            size: 44,
          ),
          const SizedBox(width: 12),
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
                Text(
                  'Brand',
                  style: AppTextStyles.caption,
                ),
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

  Widget _buildStatsRow(dynamic budget, dynamic perCreatorPayout, String? deadline) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Budget',
            budget != null
                ? '\u20B9${NumberFormat.compact().format(budget)}'
                : 'N/A',
            Iconsax.wallet_2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Per Creator',
            perCreatorPayout != null
                ? '\u20B9${NumberFormat.compact().format(perCreatorPayout)}'
                : 'N/A',
            Iconsax.money_recive,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Deadline',
            deadline != null ? _formatShortDeadline(deadline) : 'N/A',
            Iconsax.calendar_1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 6),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.h6,
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.document,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'Campaign not found',
            style: AppTextStyles.h5,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerCard(height: 180),
            SizedBox(height: 16),
            ShimmerLine(width: 200, height: 20),
            SizedBox(height: 12),
            ShimmerLine(height: 14),
            SizedBox(height: 8),
            ShimmerLine(width: 150, height: 14),
            SizedBox(height: 24),
            ShimmerCard(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load campaign',
              style: AppTextStyles.h5,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(campaignDetailProvider(campaignId));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
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

/// Bottom bar for campaign detail that shows Apply button
class CampaignDetailBottomBar extends ConsumerWidget {
  final String campaignId;

  const CampaignDetailBottomBar({
    super.key,
    required this.campaignId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasApplied = ref.watch(hasAppliedProvider(campaignId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: hasApplied.when(
          data: (applied) {
            if (applied) {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Already Applied',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/campaigns/$campaignId/apply');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply Now',
                  style: AppTextStyles.button,
                ),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 52,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                context.push('/campaigns/$campaignId/apply');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply Now',
                style: AppTextStyles.button,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
