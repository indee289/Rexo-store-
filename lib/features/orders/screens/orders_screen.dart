import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PremiumAppBar(
        title: 'Orders',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Iconsax.bag_2,
              title: 'No orders yet',
              subtitle: 'Your orders will appear here once you make a purchase',
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(userOrdersProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: orders.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return _buildOrderCard(context, orders[index]);
              },
            ),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => EmptyState(
          icon: Iconsax.warning_2,
          title: 'Failed to load orders',
          subtitle: ErrorUtils.sanitize(error),
          ctaLabel: 'Retry',
          ctaIcon: Iconsax.refresh,
          onCta: () => ref.invalidate(userOrdersProvider),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final total =
        (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = order['created_at'] as String?;
    final orderId = order['id'] as String? ?? '';
    final productName =
        order['product_name'] as String? ?? 'Product';

    String formattedDate = '';
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        formattedDate =
            DateFormat('dd MMM yyyy').format(date);
      }
    }

    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: () => context.push('/orders/$orderId'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: AppRadius.allSm,
              ),
              child: const Icon(Iconsax.bag_2,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#${orderId.substring(0, 8).toUpperCase()} • $formattedDate',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right side: status + amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    OrderStatus.getLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'shipped':
      case 'out_for_delivery':
        return AppColors.accentPurple;
      case 'confirmed':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}
