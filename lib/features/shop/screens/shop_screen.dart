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
    final products = ref.watch(productsProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: Colors.white,
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
            // Category filter
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
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Iconsax.shop,
                      title: 'No products available',
                      subtitle: 'Check back later for new arrivals',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          ProductCard(product: data[index])
                              .staggeredEntrance(index),
                      childCount: data.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const ShimmerCard(height: 220),
                    childCount: 6,
                  ),
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Iconsax.warning_2,
                  title: 'Failed to load products',
                  subtitle: ErrorUtils.sanitize(error),
                  cta: PremiumButton(
                    label: 'Retry',
                    expand: false,
                    icon: Iconsax.refresh,
                    onPressed: () => ref.invalidate(productsProvider),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
          content:
              Text('Product management is available in the Admin app.'),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Add Products',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          content: const Text(
            'You need to be approved for the Rexo Program to sell products. '
            'Go to your Profile page and apply.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }
  }
}

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
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
