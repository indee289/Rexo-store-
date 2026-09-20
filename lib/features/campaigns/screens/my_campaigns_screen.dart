import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../services/supabase_service.dart';
import '../providers/campaigns_provider.dart';
import 'campaign_applicants_screen.dart';

/// Provider for user's own campaigns (brand role)
final myCampaignsListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final response = await SupabaseService.client
      .from('campaigns')
      .select('*, applications(id)')
      .eq('brand_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Provider for current user's role
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  final profile = await SupabaseService.getUserProfile(user.id);
  return profile?['role'] as String?;
});

class MyCampaignsScreen extends ConsumerWidget {
  const MyCampaignsScreen({super.key});

  PreferredSizeWidget _appBar(BuildContext context, String title) {
    return PremiumAppBar(title: title);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        final isBrand = role == 'brand';
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _appBar(context, isBrand ? 'My Campaigns' : 'My Applications'),
          body: isBrand
              ? const _BrandCampaignsList()
              : const _CreatorApplicationsList(),
        );
      },
      loading: () => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _appBar(context, 'My Campaigns'),
        body: _buildListSkeleton(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _appBar(context, 'My Campaigns'),
        body: const EmptyState(
          icon: Iconsax.warning_2,
          title: 'Failed to load',
          subtitle: 'Please try again in a moment.',
        ),
      ),
    );
  }
}

/// Shimmer skeleton list shared by the brand/creator list loading states.
Widget _buildListSkeleton() {
  return ListView.builder(
    padding: const EdgeInsets.all(AppSpacing.lg),
    itemCount: 4,
    itemBuilder: (_, __) => const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: ShimmerCard(height: 100),
    ),
  );
}

class _BrandCampaignsList extends ConsumerWidget {
  const _BrandCampaignsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(myCampaignsListProvider);

    return campaignsAsync.when(
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return const EmptyState(
            icon: Iconsax.volume_high,
            title: 'No campaigns yet',
            subtitle: 'Create your first campaign to find creators',
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(myCampaignsListProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              return _BrandCampaignCard(campaign: campaigns[index]);
            },
          ),
        );
      },
      loading: _buildListSkeleton,
      error: (e, _) => const EmptyState(
        icon: Iconsax.warning_2,
        title: 'Failed to load campaigns',
        subtitle: 'Pull to refresh or try again shortly.',
      ),
    );
  }
}

class _CreatorApplicationsList extends ConsumerWidget {
  const _CreatorApplicationsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return applicationsAsync.when(
      data: (applications) {
        if (applications.isEmpty) {
          return const EmptyState(
            icon: Iconsax.document,
            title: 'No applications yet',
            subtitle: 'Apply to campaigns to start collaborating with brands',
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(myApplicationsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              return _ApplicationCard(application: applications[index]);
            },
          ),
        );
      },
      loading: _buildListSkeleton,
      error: (e, _) => const EmptyState(
        icon: Iconsax.warning_2,
        title: 'Failed to load applications',
        subtitle: 'Pull to refresh or try again shortly.',
      ),
    );
  }
}

/// Maps a campaign/application status string to its semantic token color.
Color _statusColor(String status) {
  switch (status) {
    case 'active':
    case 'approved':
      return AppColors.success;
    case 'rejected':
      return AppColors.error;
    case 'completed':
      return AppColors.roleBrand;
    case 'paused':
      return AppColors.warning;
    case 'withdrawn':
      return AppColors.textSecondary;
    default:
      return AppColors.warning;
  }
}

class _BrandCampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;

  const _BrandCampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (campaign['title'] ?? 'Untitled Campaign').toString();
    final status = (campaign['status'] ?? 'draft').toString();
    final createdAt = DateTime.tryParse(campaign['created_at'] ?? '');
    final dateStr =
        createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '';
    final applications = campaign['applications'] as List? ?? [];
    final totalSlots = campaign['slots'] ?? 0;
    final filledSlots = applications.length;
    final statusColor = status == 'draft'
        ? AppColors.textSecondary
        : _statusColor(status);

    return InkWell(
      borderRadius: AppRadius.allLg,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CampaignApplicantsScreen(
              campaignId: campaign['id'] as String,
              campaignTitle: title,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusPill(label: status, color: statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Iconsax.people,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$filledSlots applicant${filledSlots == 1 ? '' : 's'} · $totalSlots slots',
                  style: AppTextStyles.bodySmall,
                ),
                const Spacer(),
                Icon(Iconsax.calendar,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: AppSpacing.xs),
                Text(dateStr,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  'View applicants',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Iconsax.arrow_right_3,
                    size: 14, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final campaign = application['campaigns'] as Map<String, dynamic>? ?? {};
    final campaignTitle = (campaign['title'] ?? 'Unknown Campaign').toString();
    final status = (application['status'] ?? 'pending').toString();
    final pitch = (application['pitch'] ?? '').toString();
    final createdAt = DateTime.tryParse(application['created_at'] ?? '');
    final dateStr =
        createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  campaignTitle,
                  style: AppTextStyles.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusPill(label: status, color: _statusColor(status)),
            ],
          ),
          if (pitch.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              pitch,
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Iconsax.calendar,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: AppSpacing.xs),
              Text('Applied $dateStr',
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small status pill used on the brand campaign / application cards.
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.allSm,
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1).toLowerCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
