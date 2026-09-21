import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_card.dart';
import '../../admin/providers/admin_provider.dart';
import 'add_product_screen.dart';

class ShopAdminScreen extends ConsumerStatefulWidget {
  const ShopAdminScreen({super.key});

  @override
  ConsumerState<ShopAdminScreen> createState() => _ShopAdminScreenState();
}

class _ShopAdminScreenState extends ConsumerState<ShopAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Shop Admin'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openAddProduct,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProductsTab(),
          _OrdersTab(),
        ],
      ),
    );
  }

  /// Opens the full-screen Add Product page. The page performs the real
  /// Supabase insert itself and returns `true` on success, at which point we
  /// refresh the product list so the new item appears immediately.
  Future<void> _openAddProduct() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (created == true) {
      ref.invalidate(adminProductsProvider);
    }
  }
}

class _ProductsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(adminProductsProvider);

    return products.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text('No products',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final product = list[index];
            final imageUrl = product['image_url'] as String?;
            final isDigital = product['product_type'] == 'digital';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: AppColors.primary.withOpacity(0.1),
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Iconsax.box,
                                    color: AppColors.primary),
                              )
                            : const Icon(Iconsax.box, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  product['title'] ?? 'Product',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDigital
                                          ? AppColors.secondary
                                          : AppColors.primary)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isDigital ? 'Digital' : 'E-com',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDigital
                                        ? AppColors.secondary
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\u20B9${product['price'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.trash,
                          color: AppColors.error, size: 20),
                      onPressed: () => _confirmDelete(context, ref, product),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) => Center(child: Text(ErrorUtils.sanitize(error))),
    );
  }

  /// Confirms then performs a REAL Supabase delete (admin-authorized via the
  /// products DELETE RLS policy). Shows a success/error snackbar based on the
  /// actual result; the list refreshes through the provider's invalidate.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> product,
  ) async {
    final productId = product['id'] as String?;
    if (productId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Are you sure you want to delete "${product['title'] ?? 'this product'}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok =
        await ref.read(adminActionsProvider.notifier).deleteProduct(productId);
    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final state = ref.read(adminActionsProvider);
      final message = state.hasError
          ? ErrorUtils.sanitize(state.error)
          : 'Could not delete the product. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }
}

class _OrdersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminOrdersProvider);

    return orders.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text('No orders',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final order = list[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order['id']?.toString().substring(0, 8) ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Status: ${order['status'] ?? 'pending'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (status) => ref
                          .read(adminActionsProvider.notifier)
                          .updateOrderStatus(order['id'], status),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'processing', child: Text('Processing')),
                        const PopupMenuItem(
                            value: 'shipped', child: Text('Shipped')),
                        const PopupMenuItem(
                            value: 'delivered', child: Text('Delivered')),
                        const PopupMenuItem(
                            value: 'cancelled', child: Text('Cancelled')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) => Center(child: Text(ErrorUtils.sanitize(error))),
    );
  }
}
