import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

class AdminShopScreen extends ConsumerStatefulWidget {
  const AdminShopScreen({super.key});

  @override
  ConsumerState<AdminShopScreen> createState() => _AdminShopScreenState();
}

class _AdminShopScreenState extends ConsumerState<AdminShopScreen>
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
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return _buildAccessDenied();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Shop Admin',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildOrdersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductsTab() {
    final productsAsync = ref.watch(adminProductsProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.shop, size: 48, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No products yet', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      },
      loading: () => const ShimmerLoading(height: 400),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Failed to load products', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => ref.invalidate(adminProductsProvider),
              child: Text('Retry', style: GoogleFonts.poppins(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final title = product['title'] ?? 'Untitled';
    final price = product['price']?.toString() ?? '0';
    final stock = product['stock']?.toString() ?? '0';
    final isActive = product['is_active'] == true;
    final productId = product['id'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u20B9$price | Stock: $stock',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isActive ? AppColors.success : AppColors.error).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive ? AppColors.success : AppColors.error,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showProductForm(context, product: product);
                } else if (value == 'delete') {
                  _confirmDelete(productId, title);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit', style: GoogleFonts.poppins(fontSize: 14)),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.bag_2, size: 48, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No orders yet', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
      loading: () => const ShimmerLoading(height: 400),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Failed to load orders', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => ref.invalidate(adminOrdersProvider),
              child: Text('Retry', style: GoogleFonts.poppins(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final userName = order['users']?['name'] ?? 'Unknown';
    final status = order['status'] ?? 'pending';
    final total = order['total']?.toString() ?? '0';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${orderId.substring(0, 8)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$userName | \u20B9$total',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _buildOrderStatusChip(status),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (newStatus) {
                ref.read(adminActionsProvider.notifier).updateOrderStatus(orderId, newStatus);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order status updated to $newStatus')),
                );
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'pending', child: Text('Pending', style: GoogleFonts.poppins(fontSize: 14))),
                PopupMenuItem(value: 'confirmed', child: Text('Confirmed', style: GoogleFonts.poppins(fontSize: 14))),
                PopupMenuItem(value: 'shipped', child: Text('Shipped', style: GoogleFonts.poppins(fontSize: 14))),
                PopupMenuItem(value: 'delivered', child: Text('Delivered', style: GoogleFonts.poppins(fontSize: 14))),
                PopupMenuItem(value: 'cancelled', child: Text('Cancelled', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.error))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = const Color(0xFF2196F3);
        break;
      case 'shipped':
        color = AppColors.warning;
        break;
      case 'delivered':
        color = AppColors.success;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showProductForm(BuildContext context, {Map<String, dynamic>? product}) {
    final titleController = TextEditingController(text: product?['title'] ?? '');
    final descController = TextEditingController(text: product?['description'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final stockController = TextEditingController(text: product?['stock']?.toString() ?? '');
    final categoryController = TextEditingController(text: product?['category'] ?? '');
    final imageUrlController = TextEditingController(text: product?['image_url'] ?? '');
    final isEdit = product != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Product' : 'Add Product',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildTextField(titleController, 'Title'),
              const SizedBox(height: 12),
              _buildTextField(descController, 'Description', maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(priceController, 'Price', inputType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(stockController, 'Stock', inputType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(categoryController, 'Category'),
              const SizedBox(height: 12),
              _buildTextField(imageUrlController, 'Image URL'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final data = {
                      'title': titleController.text,
                      'description': descController.text,
                      'price': double.tryParse(priceController.text) ?? 0,
                      'stock': int.tryParse(stockController.text) ?? 0,
                      'category': categoryController.text,
                      'image_url': imageUrlController.text,
                    };
                    Navigator.pop(ctx);
                    bool success;
                    if (isEdit) {
                      success = await ref.read(adminActionsProvider.notifier).updateProduct(product['id'], data);
                    } else {
                      success = await ref.read(adminActionsProvider.notifier).createProduct(data);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? (isEdit ? 'Product updated' : 'Product created') : 'Action failed'),
                          backgroundColor: success ? AppColors.success : AppColors.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEdit ? 'Update Product' : 'Create Product',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: inputType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  void _confirmDelete(String productId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Product', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete \'$title\'?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(adminActionsProvider.notifier).deleteProduct(productId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Product deleted' : 'Delete failed'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Shop Admin', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.lock, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Access Denied', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
