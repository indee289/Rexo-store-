import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../reviews/widgets/star_rating_widget.dart';
import '../providers/sellers_provider.dart';

/// Seller profile — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over one tall `PremiumCard` holding everything —
/// logo, name, description, two `StatPill`s split by a 1px `Container`, and a
/// star row — with a generic full-page shimmer as the loading state.
///
/// New layout: collapsing large title, an identity hero card, and the stats as
/// separate glass pills so each metric is its own surface instead of sharing
/// one card divided by a rule.
///
/// `sellerProfileProvider` is unchanged.
class SellerProfileScreen extends ConsumerWidget {
  final String sellerId;

  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(sellerProfileProvider(sellerId));

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          const GlassLargeTitleHeader(title: 'Seller profile', showBack: true),
          sellerAsync.when(
            data: (seller) {
              if (seller == null) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassEmptyState(
                    icon: AppIcons.shop,
                    title: 'Seller not found',
                    message: 'This store is no longer available.',
                    actionLabel: 'Go back',
                    onAction: () => context.pop(),
                  ),
                );
              }
              return SliverToBoxAdapter(child: _Body(seller: seller));
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: GlassLoader(),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: GlassErrorState(
                title: 'Failed to load seller',
                message: ErrorUtils.sanitize(error),
                onRetry: () =>
                    ref.invalidate(sellerProfileProvider(sellerId)),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.seller});

  final Map<String, dynamic> seller;

  @override
  Widget build(BuildContext context) {
    final storeName = seller['store_name'] as String? ?? 'Store';
    final description = seller['description'] as String? ?? '';
    final logoUrl = seller['logo_url'] as String?;
    final rating = (seller['rating'] as num?)?.toDouble() ?? 0.0;
    final totalSales = seller['total_sales'] as int? ?? 0;
    final isVerified = seller['is_verified'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            borderRadius: AppRadius.allXl,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                PremiumAvatar(
                  imageUrl: logoUrl,
                  name: storeName,
                  size: PremiumAvatar.sizeLg + 8,
                  isVerified: isVerified,
                ),
                AppSpacing.gapLg,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        storeName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        AppIcons.verify,
                        size: 20,
                        color: AppColors.verified,
                      ),
                    ],
                  ],
                ),
                AppSpacing.gapSm,
                StarRatingCompact(rating: rating, size: 18),
                if (description.isNotEmpty) ...[
                  AppSpacing.gapLg,
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: GlassStatPill(
                  icon: AppIcons.star_1,
                  value: rating.toStringAsFixed(1),
                  label: 'Rating',
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: GlassStatPill(
                  icon: AppIcons.bag_2,
                  value: '$totalSales',
                  label: 'Sales',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
