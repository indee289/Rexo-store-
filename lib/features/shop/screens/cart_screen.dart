import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../providers/shop_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cartItems = ref.watch(cartProvider);
    final totalAmount = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Cart',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                // Cart items list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return _buildCartItem(
                              context, ref, cartItems[index], theme)
                          .staggeredEntrance(index);
                    },
                  ),
                ),

                // Order summary and checkout button
                _buildOrderSummary(
                    context, totalAmount, cartItems.length, theme),
              ],
            ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    CartItem item,
    ThemeData theme,
  ) {
    final product = item.product;
    final title = product['title'] ?? 'Untitled';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final images = product['images'] as List<dynamic>?;
    final imageUrl =
        (images != null && images.isNotEmpty) ? images[0] as String : null;
    final productId = product['id'] as String;

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Product image
          CachedImage(
            imageUrl: imageUrl,
            width: 72,
            height: 72,
            borderRadius: AppRadius.allSm,
          ),
          const SizedBox(width: AppSpacing.md),

          // Product info
          Expanded(
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
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '\u20B9${price.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Quantity controls
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Iconsax.minus,
                      onPressed: () {
                        ref
                            .read(cartProvider.notifier)
                            .updateQuantity(productId, item.quantity - 1);
                      },
                      theme: theme,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: Text(
                        '${item.quantity}',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Iconsax.add,
                      onPressed: () {
                        ref
                            .read(cartProvider.notifier)
                            .updateQuantity(productId, item.quantity + 1);
                      },
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Remove button
          PremiumIconButton(
            icon: Iconsax.trash,
            iconSize: 20,
            color: AppColors.error,
            onPressed: () {
              ref.read(cartProvider.notifier).removeFromCart(productId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(AppRadius.sm - 2),
        ),
        child: Icon(icon, size: 16, color: theme.colorScheme.onSurface),
      ),
    );
  }

  Widget _buildOrderSummary(
    BuildContext context,
    double totalAmount,
    int itemCount,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal ($itemCount items)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  '\u20B9${totalAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTextStyles.h6),
                Text(
                  '\u20B9${totalAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.h5.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              label: 'Proceed to Checkout',
              icon: Iconsax.shopping_bag,
              onPressed: () => context.push('/checkout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return EmptyState(
      icon: Iconsax.shopping_cart,
      title: 'Your cart is empty',
      subtitle: 'Add some products to get started',
      cta: PremiumButton(
        label: 'Continue Shopping',
        expand: false,
        icon: Iconsax.shop,
        onPressed: () => context.pop(),
      ),
    );
  }
}
