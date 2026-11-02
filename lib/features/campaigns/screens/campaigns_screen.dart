import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/campaign_card.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/campaigns_provider.dart';

/// My campaigns — liquid glass, rebuilt layout.
///
/// Was a `Scaffold` + `PremiumAppBar` (centred title over a hairline divider)
/// wrapping three separate full-screen bodies: a flat `ListView`, a
/// `ListView` of opaque shimmer blocks, and an `EmptyState` holding a
/// `PremiumButton`.
///
/// Now one `CustomScrollView` under a collapsing large-title header that also
/// reports the application count, with glass skeletons shaped like the real
/// card and the shared `GlassEmptyState` / `GlassErrorState`.
///
/// `appliedCampaignsProvider`, the pull-to-refresh behaviour, the
/// application-status pass-through and the `/campaigns/{id}` route are
/// unchanged. No filtering or sorting was added.
class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applied = ref.watch(appliedCampaignsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        // Without this the spinner would appear under the pinned header.
        edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
        onRefresh: () async {
          ref.invalidate(appliedCampaignsProvider);
          await ref.read(appliedCampaignsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            GlassLargeTitleHeader(
              title: 'My campaigns',
              subtitle: applied.maybeWhen(
                data: (rows) => rows.isEmpty
                    ? null
                    : '${rows.length} application'
                        '${rows.length == 1 ? '' : 's'}',
                orElse: () => null,
              ),
              automaticallyImplyLeading: false,
            ),
            applied.when(
              data: (campaigns) => _CampaignSliver(campaigns: campaigns),
              loading: () => const _LoadingSliver(),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: GlassErrorState(
                  message: ErrorUtils.sanitize(error),
                  onRetry: () => ref.invalidate(appliedCampaignsProvider),
                ),
              ),
            ),
            // Clear the floating nav dock.
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}

class _CampaignSliver extends StatelessWidget {
  const _CampaignSliver({required this.campaigns});

  final List<Map<String, dynamic>> campaigns;

  @override
  Widget build(BuildContext context) {
    if (campaigns.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: GlassEmptyState(
          icon: AppIcons.document,
          title: "You haven't applied yet",
          message: 'Campaigns you apply to will show up here.',
          actionLabel: 'Browse campaigns',
          onAction: () => context.go(AppRoutes.home),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      sliver: SliverList.separated(
        itemCount: campaigns.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          final id = campaign['id']?.toString();
          // RepaintBoundary per row: each card is a glass pane, so isolating
          // them stops one from repainting the whole visible list on scroll.
          return RepaintBoundary(
            child: CampaignCard(
              campaign: campaign,
              layout: CampaignCardLayout.compact,
              applicationStatus: campaign['application_status']?.toString(),
              onTap: id == null ? null : () => context.push('/campaigns/$id'),
            ),
          );
        },
      ),
    );
  }
}

/// Glass skeletons shaped like the compact campaign card.
class _LoadingSliver extends StatelessWidget {
  const _LoadingSliver();

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
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => const RepaintBoundary(child: _CardSkeleton()),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const GlassSkeleton(width: 56, height: 56),
          AppSpacing.gapMd,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassSkeleton(height: 15),
                SizedBox(height: 8),
                GlassSkeleton(width: 150, height: 11),
                SizedBox(height: 10),
                GlassSkeleton(width: 90, height: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
