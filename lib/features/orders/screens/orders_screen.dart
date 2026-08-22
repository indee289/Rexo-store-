import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Orders',
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
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(userOrdersProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildOrderCard(context, orders[index]);
              },
            ),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => _buildErrorState(ref, ErrorUtils.sanitize(error)),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final total = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = order['created_at'] as String?;
    final orderId = order['id'] as String? ?? '';

    String formattedDate = '';
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
      }
    }

    return GestureDetector(
      onTap: () => context.push('/orders/$orderId'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${orderId.substring(0, 8).toUpperCase()}',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \u20B9${total.toStringAsFixed(0)}',
                  style: AppTextStyles.h6.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'delivered':
        chipColor = AppColors.success;
        break;
      case 'shipped':
      case 'out_for_delivery':
        chipColor = const Color(0xFF2196F3);
        break;
      case 'confirmed':
        chipColor = AppColors.warning;
        break;
      case 'cancelled':
        chipColor = AppColors.error;
        break;
      default:
        chipColor = AppColors.textHint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        OrderStatus.getLabel(status),
        style: AppTextStyles.caption.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.bag_2,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Your orders will appear here once you make a purchase',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error) {
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
            Text('Failed to load orders', style: AppTextStyles.h5),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(userOrdersProvider),
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
