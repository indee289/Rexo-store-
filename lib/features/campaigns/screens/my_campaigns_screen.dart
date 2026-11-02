import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../services/supabase_service.dart';
import '../providers/campaigns_provider.dart';
import 'campaign_applicants_screen.dart';

/// Provider for user's own campaigns (brand role)
final myCampaignsListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  // The campaigns table has historically stored the owner under BOTH
  // `brandId` (camelCase) and `brand_id` (snake_case), so union both and
  // dedupe by id. Sort client-side so a missing order column never breaks it.
  final byId = <String, Map<String, dynamic>>{};
  for (final col in ['brandId', 'brand_id']) {
    try {
      final r = await SupabaseService.client
          .from('campaigns')
          .select('*, applications(id)')
          .eq(col, user.id);
      for (final row in List<Map<String, dynamic>>.from(r)) {
        final id = (row['id'] ?? '').toString();
        if (id.isNotEmpty) byId[id] = row;
      }
    } catch (_) {}
  }

  final list = byId.values.toList();
  list.sort((a, b) {
    final ad = DateTime.tryParse(
            (a['createdAt'] ?? a['created_at'] ?? '').toString()) ??
        DateTime(1970);
    final bd = DateTime.tryParse(
            (b['createdAt'] ?? b['created_at'] ?? '').toString()) ??
        DateTime(1970);
    return bd.compareTo(ad);
  });
  return list;
});

/// Provider for current user's role
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  final profile = await SupabaseService.getUserProfile(user.id);
  // Lowercase so the brand/creator branch is case-insensitive (the DB may
  // hold 'CREATOR'/'Brand' etc.).
  return (profile?['role'] as String?)?.trim().toLowerCase();
});

/// My campaigns / My applications — rebuilt layout.
///
/// Old layout: three near-identical `Scaffold`s (one per async state) each
/// rebuilding a `PremiumAppBar`, with lists of hand-built `Container` cards and
/// a local `_StatusPill`, plus a `FloatingActionButton.extended` for brands.
///
/// New layout: one scaffold with a collapsing large title whose text follows
/// the role, cards that lead with the campaign status, and the brand's create
/// action as a labelled pill pinned above the safe area rather than a floating
/// button that covers the last card.
///
/// `myCampaignsListProvider` (consumed by the profile screen too),
/// `userRoleProvider`, `myApplicationsProvider`, the applicants push and the
/// `/create-campaign` route are unchanged.
class MyCampaignsScreen extends ConsumerWidget {
  const MyCampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);
    final isBrand = roleAsync.maybeWhen(
      data: (role) => role == 'brand',
      orElse: () => false,
    );

    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: [
              GlassLargeTitleHeader(
                title: isBrand ? 'My campaigns' : 'My applications',
                automaticallyImplyLeading: false,
              ),
              roleAsync.when(
                data: (role) => role == 'brand'
                    ? const _BrandCampaignsSliver()
                    : const _CreatorApplicationsSliver(),
                loading: () => const _ListSkeleton(),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassErrorState(
                    title: 'Failed to load',
                    message: 'Please try again in a moment.',
                    onRetry: () => ref.invalidate(userRoleProvider),
                  ),
                ),
              ),
            ],
          ),
          if (isBrand)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              child: GlassButton(
                label: 'New campaign',
                icon: AppIcons.add,
                onPressed: () => context.push('/create-campaign'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Skeletons shared by the role and list loading states.
class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      sliver: SliverList.separated(
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => const GlassSkeleton(
          height: 104,
          borderRadius: AppRadius.allLg,
        ),
      ),
    );
  }
}

class _BrandCampaignsSliver extends ConsumerWidget {
  const _BrandCampaignsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(myCampaignsListProvider);

    return campaignsAsync.when(
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: GlassEmptyState(
              icon: AppIcons.volume_high,
              title: 'No campaigns yet',
              message: 'Create your first campaign to find creators.',
              actionLabel: 'New campaign',
              onAction: () => context.push('/create-campaign'),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            110,
          ),
          sliver: SliverList.separated(
            itemCount: campaigns.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => RepaintBoundary(
              child: _BrandCampaignCard(campaign: campaigns[index]),
            ),
          ),
        );
      },
      loading: () => const _ListSkeleton(),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: GlassErrorState(
          title: 'Failed to load campaigns',
          message: 'Pull to refresh or try again shortly.',
          onRetry: () => ref.invalidate(myCampaignsListProvider),
        ),
      ),
    );
  }
}

class _CreatorApplicationsSliver extends ConsumerWidget {
  const _CreatorApplicationsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return applicationsAsync.when(
      data: (applications) {
        if (applications.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: GlassEmptyState(
              icon: AppIcons.document,
              title: 'No applications yet',
              message:
                  'Apply to campaigns to start collaborating with brands.',
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          sliver: SliverList.separated(
            itemCount: applications.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => RepaintBoundary(
              child: _ApplicationCard(application: applications[index]),
            ),
          ),
        );
      },
      loading: () => const _ListSkeleton(),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: GlassErrorState(
          title: 'Failed to load applications',
          message: 'Pull to refresh or try again shortly.',
          onRetry: () => ref.invalidate(myApplicationsProvider),
        ),
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

String _capitalize(String v) =>
    v.isEmpty ? v : v[0].toUpperCase() + v.substring(1).toLowerCase();

class _BrandCampaignCard extends StatelessWidget {
  const _BrandCampaignCard({required this.campaign});

  final Map<String, dynamic> campaign;

  @override
  Widget build(BuildContext context) {
    final title = (campaign['title'] ?? 'Untitled Campaign').toString();
    final status = (campaign['status'] ?? 'draft').toString();
    final createdAt = DateTime.tryParse(
        (campaign['createdAt'] ?? campaign['created_at'] ?? '').toString());
    final dateStr =
        createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '';
    final applications = campaign['applications'] as List? ?? [];
    final totalSlots = campaign['slots'] ?? 0;
    final filledSlots = applications.length;
    final statusColor =
        status == 'draft' ? AppColors.textSecondary : _statusColor(status);

    return GlassCard(
      borderRadius: AppRadius.allLg,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.gapSm,
              GlassChip.status(
                label: _capitalize(status),
                color: statusColor,
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              const Icon(
                AppIcons.people,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                '$filledSlots applicant${filledSlots == 1 ? '' : 's'}'
                '  ·  $totalSlots slots',
                style: AppTextStyles.footnote
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (dateStr.isNotEmpty)
                Text(
                  dateStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textHint),
                ),
            ],
          ),
          AppSpacing.gapSm,
          Row(
            children: [
              Text(
                'View applicants',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                AppIcons.arrow_right_3,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final Map<String, dynamic> application;

  @override
  Widget build(BuildContext context) {
    final campaign = application['campaigns'] as Map<String, dynamic>? ?? {};
    final campaignTitle = (campaign['title'] ?? 'Unknown Campaign').toString();
    final status = (application['status'] ?? 'pending').toString();
    final pitch = (application['pitch'] ?? '').toString();
    final createdAt = DateTime.tryParse(
        (application['created_at'] ?? application['createdAt'] ?? '')
            .toString());
    final dateStr =
        createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '';

    return GlassCard(
      borderRadius: AppRadius.allLg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  campaignTitle,
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.gapSm,
              GlassChip.status(
                label: _capitalize(status),
                color: _statusColor(status),
              ),
            ],
          ),
          if (pitch.isNotEmpty) ...[
            AppSpacing.gapSm,
            Text(
              pitch,
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (dateStr.isNotEmpty) ...[
            AppSpacing.gapSm,
            Row(
              children: [
                const Icon(
                  AppIcons.calendar,
                  size: 13,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 5),
                Text(
                  'Applied $dateStr',
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
