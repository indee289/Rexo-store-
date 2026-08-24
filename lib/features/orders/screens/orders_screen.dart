import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Orders', style: AppTextStyles.h5),
        centerTitle: false,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: PremiumIconButton(
            icon: Iconsax.arrow_left,
            onPressed: () => context.pop(),
          ),
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: orders.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return _buildOrderCard(context, orders[index], theme);
              },
            ),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => _buildErrorState(ref, ErrorUtils.sanitize(error)),
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, Map<String, dynamic> order, ThemeData theme) {
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

    return PremiumCard(
      onTap: () => context.push('/orders/$orderId'),
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            formattedDate,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: \u20B9${total.toStringAsFixed(0)}',
                style: AppTextStyles.h6.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ],
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
        chipColor = AppColors.roleBrand;
        break;
      case 'confirmed':
        chipColor = AppColors.warning;
        break;
      case 'cancelled':
        chipColor = AppColors.error;
        break;
      default:
        chipColor = AppColors.warning;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: AppRadius.pillAll,
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
    return const EmptyState(
      icon: Iconsax.bag_2,
      title: 'No orders yet',
      subtitle: 'Your orders will appear here once you make a purchase',
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error) {
    return EmptyState(
      icon: Iconsax.warning_2,
      title: 'Failed to load orders',
      subtitle: error,
      ctaLabel: 'Retry',
      ctaIcon: Iconsax.refresh,
      onCta: () => ref.invalidate(userOrdersProvider),
    );
  }
}
