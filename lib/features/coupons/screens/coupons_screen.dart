import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/coupons_provider.dart';

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PremiumAppBar(
          title: 'Coupons & rewards',
          showBack: true,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            labelStyle: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Coupons'),
              Tab(text: 'Rewards'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CouponsTab(),
            _RewardsTab(),
          ],
        ),
      ),
    );
  }
}

class _CouponsTab extends ConsumerWidget {
  const _CouponsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(availableCouponsProvider);

    return couponsAsync.when(
      data: (coupons) {
        if (coupons.isEmpty) {
          return _buildEmpty();
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: coupons.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) =>
              _buildCouponCard(context, coupons[index]),
        );
      },
      loading: () => const ShimmerLoading(),
      error: (error, _) => EmptyState(
        icon: Iconsax.warning_2,
        title: 'Failed to load coupons',
        ctaLabel: 'Retry',
        ctaIcon: Iconsax.refresh,
        onCta: () => ref.invalidate(availableCouponsProvider),
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, Map<String, dynamic> coupon) {
    final code = coupon['code'] as String? ?? '';
    final discountType = coupon['discount_type'] as String? ?? 'fixed';
    final discountValue = (coupon['discount_value'] as num?)?.toDouble() ?? 0;
    final minOrder = (coupon['min_order'] as num?)?.toDouble() ?? 0;
    final expiresAt = coupon['expires_at'] as String?;

    String discountLabel;
    if (discountType == 'percentage') {
      discountLabel = '${discountValue.toInt()}% off';
    } else {
      discountLabel = '\u20B9${discountValue.toStringAsFixed(0)} OFF';
    }

    String expiryLabel = '';
    if (expiresAt != null) {
      final date = DateTime.tryParse(expiresAt);
      if (date != null) {
        expiryLabel = 'Expires: ${DateFormat('dd MMM yyyy').format(date)}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Discount badge
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: AppRadius.allSm,
            ),
            child: const Icon(
              Iconsax.ticket_discount,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  discountLabel,
                  style: AppTextStyles.h6.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Code: $code',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Min. order: \u20B9${minOrder.toStringAsFixed(0)}',
                  style: AppTextStyles.caption,
                ),
                if (expiryLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    expiryLabel,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const EmptyState(
      icon: Iconsax.ticket_discount,
      title: 'No coupons available',
      subtitle: 'Check back later for new offers',
    );
  }
}

class _RewardsTab extends ConsumerWidget {
  const _RewardsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(userRewardPointsProvider);

    return rewardsAsync.when(
      data: (rewards) {
        final points = (rewards?['points'] as int?) ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Points balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppRadius.allLg,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Iconsax.medal_star,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '$points',
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Reward Points',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Redeem section
              PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Redeem points', style: AppTextStyles.h6),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Use your reward points for discounts on your next purchase. 100 points = \u20B910 off.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: points >= 100 ? () {} : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: points >= 100
                                ? AppColors.primary
                                : Theme.of(context).dividerColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.allSm,
                          ),
                        ),
                        child: Text(
                          points >= 100 ? 'Redeem now' : 'Need 100+ points',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: points >= 100
                                ? AppColors.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const ShimmerLoading(),
      error: (error, _) => EmptyState(
        icon: Iconsax.warning_2,
        title: 'Failed to load rewards',
        ctaLabel: 'Retry',
        ctaIcon: Iconsax.refresh,
        onCta: () => ref.invalidate(userRewardPointsProvider),
      ),
    );
  }
}
