import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../reviews/widgets/star_rating_widget.dart';
import '../../shop/widgets/product_card.dart';
import '../providers/sellers_provider.dart';

class SellerProfileScreen extends ConsumerWidget {
  final String sellerId;

  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(sellerProfileProvider(sellerId));
    final productsAsync = ref.watch(sellerProductsProvider(sellerId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Seller Profile', showBack: true),
      body: sellerAsync.when(
        data: (seller) {
          if (seller == null) return _buildNotFound(context);
          return _buildContent(context, seller, productsAsync);
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => _buildError(ref, ErrorUtils.sanitize(error)),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> seller,
    AsyncValue<List<Map<String, dynamic>>> productsAsync,
  ) {
    final storeName = seller['store_name'] as String? ?? 'Store';
    final description = seller['description'] as String? ?? '';
    final logoUrl = seller['logo_url'] as String?;
    final rating = (seller['rating'] as num?)?.toDouble() ?? 0.0;
    final totalSales = seller['total_sales'] as int? ?? 0;
    final isVerified = seller['is_verified'] as bool? ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller header
          PremiumCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                // Logo
                PremiumAvatar(
                  imageUrl: logoUrl,
                  name: storeName,
                  size: 80,
                  isVerified: isVerified,
                ),
                const SizedBox(height: AppSpacing.md),
                // Store name + verified
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        storeName,
                        style: AppTextStyles.h5,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: AppSpacing.xs + 2),
                      const Icon(
                        Iconsax.verify,
                        size: 20,
                        color: AppColors.verified,
                      ),
                    ],
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatPill(
                      icon: Iconsax.star_1,
                      value: rating.toStringAsFixed(1),
                      label: 'Rating',
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Theme.of(context).dividerColor,
                    ),
                    StatPill(
                      icon: Iconsax.shopping_bag,
                      value: '$totalSales',
                      label: 'Sales',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                StarRatingCompact(rating: rating, size: 20),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Products section
          Text('Products', style: AppTextStyles.h6),
          const SizedBox(height: AppSpacing.md),
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: EmptyState(
                    icon: Iconsax.shopping_bag,
                    title: 'No products available',
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.7,
                ),
                itemCount: products.length > 6 ? 6 : products.length,
                itemBuilder: (context, index) =>
                    ProductCard(product: products[index]),
              );
            },
            loading: () => const ShimmerCard(height: 200),
            error: (_, __) => Text(
              'Failed to load products',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return EmptyState(
      icon: Iconsax.shop,
      title: 'Seller not found',
      ctaLabel: 'Go Back',
      onCta: () => context.pop(),
    );
  }

  Widget _buildError(WidgetRef ref, String error) {
    return EmptyState(
      icon: Iconsax.warning_2,
      title: 'Failed to load seller',
      subtitle: error,
      ctaLabel: 'Retry',
      ctaIcon: Iconsax.refresh,
      onCta: () => ref.invalidate(sellerProfileProvider(sellerId)),
    );
  }
}
