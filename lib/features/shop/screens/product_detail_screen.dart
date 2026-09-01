import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../reviews/widgets/star_rating_widget.dart';
import '../providers/shop_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Product',
        showBack: true,
        onBack: () => context.pop(),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final cartCount = ref.watch(cartItemCountProvider);
              return _CartAction(count: cartCount);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) return _buildNotFound(context);
          return _buildContent(context, product);
        },
        loading: () => _buildLoading(),
        error: (error, _) => _buildError(ErrorUtils.sanitize(error)),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> product) {
    final title = product['title'] ?? 'Untitled Product';
    final description = product['description'] ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final originalPrice = (product['original_price'] as num?)?.toDouble();
    final category = product['category'] ?? '';
    final stock = product['stock'] as int? ?? 0;
    final images = product['images'] as List<dynamic>? ?? [];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image carousel
                _buildImageCarousel(context, images),
                const SizedBox(height: AppSpacing.lg),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(title, style: AppTextStyles.h4),
                      const SizedBox(height: AppSpacing.md),

                      // Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\u20B9${price.toStringAsFixed(0)}',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (originalPrice != null &&
                              originalPrice > price) ...[
                            const SizedBox(width: AppSpacing.sm + 2),
                            Text(
                              '\u20B9${originalPrice.toStringAsFixed(0)}',
                              style: AppTextStyles.bodyLarge.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: AppRadius.allSm,
                              ),
                              child: Text(
                                '${((originalPrice - price) / originalPrice * 100).toInt()}% OFF',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Category chip
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.08),
                            borderRadius: AppRadius.pillAll,
                          ),
                          child: Text(
                            category,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),

                      // Stock indicator
                      _buildStockIndicator(stock),
                      const SizedBox(height: AppSpacing.xl - 4),

                      // Description
                      if (description.isNotEmpty) ...[
                        Text('Description', style: AppTextStyles.h6),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Quantity selector
                      Text('Quantity', style: AppTextStyles.h6),
                      const SizedBox(height: AppSpacing.sm),
                      _buildQuantitySelector(context, stock),
                      const SizedBox(height: AppSpacing.xl),

                      // Seller section
                      _buildSellerSection(context),
                      const SizedBox(height: AppSpacing.lg),

                      // Reviews section
                      _buildReviewsSection(context, product),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom action buttons
        _buildBottomActions(context, product, stock),
      ],
    );
  }

  Widget _buildImageCarousel(BuildContext context, List<dynamic> images) {
    if (images.isEmpty) {
      return const SizedBox(
        height: 280,
        width: double.infinity,
        child: CachedImage(imageUrl: null, height: 280),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              final imageUrl = images[index] as String;
              return CachedImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 280,
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == _currentImageIndex ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentImageIndex
                      ? AppColors.primary
                      : Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockIndicator(int stock) {
    String label;
    Color color;
    IconData icon;

    if (stock <= 0) {
      label = 'Out of Stock';
      color = AppColors.error;
      icon = Iconsax.close_circle;
    } else if (stock <= 5) {
      label = 'Low Stock ($stock left)';
      color = AppColors.warning;
      icon = Iconsax.warning_2;
    } else {
      label = 'In Stock';
      color = AppColors.success;
      icon = Iconsax.tick_circle;
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(BuildContext context, int stock) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: AppRadius.allMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PremiumIconButton(
            icon: Iconsax.minus,
            iconSize: 20,
            onPressed:
                _quantity > 1 ? () => setState(() => _quantity--) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('$_quantity', style: AppTextStyles.h6),
          ),
          PremiumIconButton(
            icon: Iconsax.add,
            iconSize: 20,
            onPressed:
                _quantity < stock ? () => setState(() => _quantity++) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
      BuildContext context, Map<String, dynamic> product, int stock) {
    final isOutOfStock = stock <= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Add to Cart button
            Expanded(
              child: PremiumButton(
                label: 'Add to Cart',
                onPressed: isOutOfStock
                    ? null
                    : () {
                        ref
                            .read(cartProvider.notifier)
                            .addToCart(product, quantity: _quantity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Added to cart!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.allSm,
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Buy Now button
            Expanded(
              child: PremiumButton(
                label: 'Buy Now',
                variant: PremiumButtonVariant.outline,
                onPressed: isOutOfStock
                    ? null
                    : () {
                        ref
                            .read(cartProvider.notifier)
                            .addToCart(product, quantity: _quantity);
                        context.push('/checkout');
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: AppRadius.allSm,
            ),
            child: const Center(
              child: Icon(
                Iconsax.shop,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sold by', style: AppTextStyles.caption),
                Text(
                  'Rexo Marketplace',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Iconsax.verify,
            size: 20,
            color: AppColors.verified,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(
      BuildContext context, Map<String, dynamic> product) {
    final productId = product['id'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        context.push('/reviews/$productId?targetType=product');
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            const StarRatingCompact(rating: 4.0, size: 18),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Text(
                'See all reviews',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return EmptyState(
      icon: Iconsax.box_1,
      title: 'Product not found',
      subtitle: 'This product may no longer be available.',
      cta: PremiumButton(
        label: 'Go Back',
        expand: false,
        icon: Iconsax.arrow_left,
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerCard(height: 280),
          SizedBox(height: AppSpacing.lg),
          ShimmerLine(width: 200, height: 24),
          SizedBox(height: AppSpacing.md),
          ShimmerLine(width: 120, height: 20),
          SizedBox(height: AppSpacing.lg),
          ShimmerLine(height: 14),
          SizedBox(height: AppSpacing.sm),
          ShimmerLine(height: 14),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return EmptyState(
      icon: Iconsax.warning_2,
      title: 'Failed to load product',
      subtitle: error,
      cta: PremiumButton(
        label: 'Retry',
        expand: false,
        icon: Iconsax.refresh,
        onPressed: () {
          ref.invalidate(productDetailProvider(widget.productId));
        },
      ),
    );
  }
}

/// Cart action button with an unread-style count badge.
class _CartAction extends StatelessWidget {
  final int count;

  const _CartAction({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PremiumIconButton(
          icon: Iconsax.shopping_cart,
          onPressed: () => context.push('/cart'),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$count',
                style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
