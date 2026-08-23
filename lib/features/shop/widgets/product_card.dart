import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/overlay_badge.dart';
import '../../../core/widgets/premium_card.dart';

/// Product card for grid display in the shop.
///
/// Routes its container through [PremiumCard] and reuses the shared
/// [OverlayBadge] so its surface, border, shadow and badges match the campaign
/// cards in both light and dark themes.
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final title = product['title'] ?? 'Untitled Product';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final originalPrice = (product['original_price'] as num?)?.toDouble();
    final category = product['category'] ?? '';
    final stock = product['stock'] as int? ?? 0;
    final images = product['images'] as List<dynamic>?;
    final imageUrl = (images != null && images.isNotEmpty)
        ? images[0] as String
        : null;

    return PremiumCard(
      onTap: () {
        context.push('/shop/${product['id']}');
      },
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(context, imageUrl),
                // Stock indicator dot
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildStockDot(stock),
                ),
                // Category badge (on-media variant — sits on the image).
                if (category.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: OverlayBadge.onMedia(label: category),
                  ),
              ],
            ),
          ),

          // Product info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\u20B9${price.toStringAsFixed(0)}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (originalPrice != null && originalPrice > price) ...[
                      const SizedBox(width: 6),
                      Text(
                        '\u20B9${originalPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.caption.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Theme.of(context).dividerColor,
          child: Center(
            child: Icon(
              Iconsax.image,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              size: 32,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).dividerColor,
          child: Center(
            child: Icon(
              Iconsax.image,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              size: 32,
            ),
          ),
        ),
      );
    }

    return Container(
      color: Theme.of(context).dividerColor,
      child: Center(
        child: Icon(
          Iconsax.image,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildStockDot(int stock) {
    Color dotColor;
    if (stock <= 0) {
      dotColor = AppColors.error;
    } else if (stock <= 5) {
      dotColor = AppColors.warning;
    } else {
      dotColor = AppColors.success;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
