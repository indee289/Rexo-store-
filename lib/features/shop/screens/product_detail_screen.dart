import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () => context.push('/cart'),
                icon: const Icon(
                  Iconsax.shopping_cart,
                  color: AppColors.textPrimary,
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final cartCount = ref.watch(cartItemCountProvider);
                  if (cartCount == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) return _buildNotFound();
          return _buildContent(product);
        },
        loading: () => _buildLoading(),
        error: (error, _) => _buildError(error.toString()),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> product) {
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
                _buildImageCarousel(images),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(title, style: AppTextStyles.h4),
                      const SizedBox(height: 12),

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
                            const SizedBox(width: 10),
                            Text(
                              '\u20B9${originalPrice.toStringAsFixed(0)}',
                              style: AppTextStyles.bodyLarge.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textHint,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
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
                      const SizedBox(height: 16),

                      // Category chip
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Stock indicator
                      _buildStockIndicator(stock),
                      const SizedBox(height: 20),

                      // Description
                      if (description.isNotEmpty) ...[
                        Text('Description', style: AppTextStyles.h6),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Quantity selector
                      Text('Quantity', style: AppTextStyles.h6),
                      const SizedBox(height: 8),
                      _buildQuantitySelector(stock),
                      const SizedBox(height: 24),

                      // Seller section
                      _buildSellerSection(),
                      const SizedBox(height: 16),

                      // Reviews section
                      _buildReviewsSection(product),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom action buttons
        _buildBottomActions(product, stock),
      ],
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    if (images.isEmpty) {
      return Container(
        height: 280,
        width: double.infinity,
        color: AppColors.border,
        child: const Center(
          child: Icon(
            Iconsax.image,
            size: 64,
            color: AppColors.textHint,
          ),
        ),
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
              return CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.border,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.border,
                  child: const Center(
                    child: Icon(
                      Iconsax.image,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
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
                      : AppColors.border,
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
        const SizedBox(width: 6),
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

  Widget _buildQuantitySelector(int stock) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _quantity > 1
                ? () => setState(() => _quantity--)
                : null,
            icon: const Icon(Icons.remove, size: 20),
            color: AppColors.textPrimary,
            disabledColor: AppColors.textHint,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_quantity',
              style: AppTextStyles.h6,
            ),
          ),
          IconButton(
            onPressed: _quantity < stock
                ? () => setState(() => _quantity++)
                : null,
            icon: const Icon(Icons.add, size: 20),
            color: AppColors.textPrimary,
            disabledColor: AppColors.textHint,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Map<String, dynamic> product, int stock) {
    final isOutOfStock = stock <= 0;

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
        child: Row(
          children: [
            // Add to Cart button
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add to Cart',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Buy Now button
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: isOutOfStock
                      ? null
                      : () {
                          ref
                              .read(cartProvider.notifier)
                              .addToCart(product, quantity: _quantity);
                          context.push('/checkout');
                        },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isOutOfStock ? AppColors.border : AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Buy Now',
                    style: AppTextStyles.button.copyWith(
                      color: isOutOfStock
                          ? AppColors.textHint
                          : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Iconsax.shop,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sold by',
                  style: AppTextStyles.caption,
                ),
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
            color: Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(Map<String, dynamic> product) {
    final productId = product['id'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        context.push('/reviews/$productId?targetType=product');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const StarRatingCompact(rating: 4.0, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'See all reviews',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.box_1,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text('Product not found', style: AppTextStyles.h5),
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
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerCard(height: 280),
          SizedBox(height: 16),
          ShimmerLine(width: 200, height: 24),
          SizedBox(height: 12),
          ShimmerLine(width: 120, height: 20),
          SizedBox(height: 16),
          ShimmerLine(height: 14),
          SizedBox(height: 8),
          ShimmerLine(height: 14),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
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
            Text('Failed to load product', style: AppTextStyles.h5),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(productDetailProvider(widget.productId));
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
}
