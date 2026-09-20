import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/campaign_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/campaigns_provider.dart';

class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applied = ref.watch(appliedCampaignsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'My campaigns',
        actions: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Iconsax.search_normal,
                size: 16, color: AppColors.primary),
            label: const Text(
              'Browse',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(appliedCampaignsProvider);
          await ref.read(appliedCampaignsProvider.future);
        },
        child: applied.when(
          data: (campaigns) => _buildList(context, campaigns),
          loading: () => _buildLoading(),
          error: (error, _) =>
              _buildError(context, ref, ErrorUtils.sanitize(error)),
        ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<Map<String, dynamic>> campaigns) {
    if (campaigns.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Iconsax.document,
              title: "You haven't applied yet",
              subtitle:
                  'Campaigns you apply to will show up here.',
              cta: PremiumButton(
                label: 'Browse campaigns',
                icon: Iconsax.search_normal,
                expand: false,
                onPressed: () => context.go(AppRoutes.home),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: campaigns.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final campaign = campaigns[index];
        final id = campaign['id']?.toString();
        return CampaignCard(
          campaign: campaign,
          layout: CampaignCardLayout.compact,
          applicationStatus:
              campaign['application_status']?.toString(),
          onTap: id == null
              ? null
              : () => context.push('/campaigns/$id'),
        ).staggeredEntrance(index);
      },
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: 5,
      itemBuilder: (context, index) =>
          const ShimmerCampaignCardCompact(),
    );
  }

  Widget _buildError(
      BuildContext context, WidgetRef ref, String message) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Iconsax.warning_2,
            title: 'Something went wrong',
            subtitle: message,
            cta: PremiumButton(
              label: 'Retry',
              icon: Iconsax.refresh,
              variant: PremiumButtonVariant.tonal,
              expand: false,
              onPressed: () =>
                  ref.invalidate(appliedCampaignsProvider),
            ),
          ),
        ),
      ],
    );
  }
}
