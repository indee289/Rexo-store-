import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../categories/widgets/category_filter_widget.dart';
import '../../rexo_program/providers/rexo_program_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/product_card.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final products = ref.watch(productsProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: PremiumAppBar(
        title: 'Shop',
        actions: [
          PremiumIconButton(
            icon: Iconsax.add_circle,
            onPressed: () => _handleAddProduct(context, ref),
          ),
          _CartAction(count: cartCount),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(productsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Category tabs
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: CategoryFilterWidget(),
              ),
            ),

            // Product grid
            products.when(
              data: (data) {
                if (data.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Iconsax.shop,
                      title: 'No products available',
                      subtitle: 'Check back later for new arrivals',
                    ),
                  );
                }
                return SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(product: data[index])
                          .staggeredEntrance(index),
                      childCount: data.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    _shimmerBuilder,
                    childCount: 6,
                  ),
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(ref, ErrorUtils.sanitize(error)),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  static Widget _shimmerBuilder(BuildContext context, int index) =>
      const ShimmerCard(height: 220);

  Widget _buildErrorState(WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Failed to load products',
              style: AppTextStyles.h5,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              label: 'Retry',
              expand: false,
              icon: Iconsax.refresh,
              onPressed: () => ref.invalidate(productsProvider),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddProduct(BuildContext context, WidgetRef ref) async {
    final canAdd = await ref.read(canAddProductsProvider.future);
    if (!context.mounted) return;

    if (canAdd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product management is available in the Admin app.'),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Cannot Add Products', style: AppTextStyles.h6),
          content: Text(
            'You need to be approved for the Rexo Program to sell products. Go to your Profile page and apply for the Rexo Program.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'OK',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }
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
