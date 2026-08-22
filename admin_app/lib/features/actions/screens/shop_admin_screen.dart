import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../admin/providers/admin_provider.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shop Admin'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showCreateProductDialog(context),
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

  void _showCreateProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\u20B9 ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (nameController.text.isNotEmpty && price != null) {
                ref.read(adminActionsProvider.notifier).createProduct({
                  'name': nameController.text,
                  'price': price,
                  'description': descController.text,
                  'created_at': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _ProductsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(adminProductsProvider);

    return products.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Text('No products',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final product = list[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.box, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'Product',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
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
                      icon: const Icon(Iconsax.trash, color: AppColors.error, size: 20),
                      onPressed: () => ref
                          .read(adminActionsProvider.notifier)
                          .deleteProduct(product['id']),
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
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminOrdersProvider);

    return orders.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Text('No orders',
                style: TextStyle(color: AppColors.textSecondary)),
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
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
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}
