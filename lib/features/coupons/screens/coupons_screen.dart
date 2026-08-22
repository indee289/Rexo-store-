import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
        appBar: AppBar(
          title: Text(
            'Coupons & Rewards',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          centerTitle: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            labelStyle: GoogleFonts.poppins(
              fontSize: 14,
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
          padding: const EdgeInsets.all(16),
          itemCount: coupons.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildCouponCard(coupons[index]),
        );
      },
      loading: () => const ShimmerLoading(),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 48, color: AppColors.error.withOpacity(0.7)),
            const SizedBox(height: 12),
            Text('Failed to load coupons', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(availableCouponsProvider),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final code = coupon['code'] as String? ?? '';
    final discountType = coupon['discount_type'] as String? ?? 'fixed';
    final discountValue = (coupon['discount_value'] as num?)?.toDouble() ?? 0;
    final minOrder = (coupon['min_order'] as num?)?.toDouble() ?? 0;
    final expiresAt = coupon['expires_at'] as String?;

    String discountLabel;
    if (discountType == 'percentage') {
      discountLabel = '${discountValue.toInt()}% OFF';
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Discount badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Iconsax.ticket_discount,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.ticket_discount,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No coupons available',
            style: AppTextStyles.h5.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new offers',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Points balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Iconsax.medal_star,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$points',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Reward Points',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Redeem section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Redeem Points', style: AppTextStyles.h6),
                    const SizedBox(height: 8),
                    Text(
                      'Use your reward points for discounts on your next purchase. 100 points = \u20B910 off.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 16),
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          points >= 100 ? 'Redeem Now' : 'Need 100+ points',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: points >= 100
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 48, color: AppColors.error.withOpacity(0.7)),
            const SizedBox(height: 12),
            Text('Failed to load rewards', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(userRewardPointsProvider),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
