import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Seller Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
      ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: logoUrl != null && logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: logoUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _buildDefaultLogo(storeName),
                        )
                      : _buildDefaultLogo(storeName),
                ),
                const SizedBox(height: 12),
                // Store name + verified
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(storeName, style: AppTextStyles.h5),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Iconsax.verify,
                        size: 20,
                        color: Color(0xFF2196F3),
                      ),
                    ],
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat(
                      icon: Iconsax.star_1,
                      value: rating.toStringAsFixed(1),
                      label: 'Rating',
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.divider,
                    ),
                    _buildStat(
                      icon: Iconsax.shopping_bag,
                      value: '$totalSales',
                      label: 'Sales',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StarRatingCompact(rating: rating, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Products section
          Text('Products', style: AppTextStyles.h6),
          const SizedBox(height: 12),
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text(
                    'No products available',
                    style: AppTextStyles.bodySmall,
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
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

  Widget _buildDefaultLogo(String name) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.shop, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Seller not found', style: AppTextStyles.h5),
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

  Widget _buildError(WidgetRef ref, String error) {
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
            Text('Failed to load seller', style: AppTextStyles.h5),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(sellerProfileProvider(sellerId)),
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
