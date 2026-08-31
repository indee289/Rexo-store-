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
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Order Details',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) return _buildNotFound(context);
          return _buildContent(context, order);
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => _buildError(ref, ErrorUtils.sanitize(error)),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final total = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = order['created_at'] as String?;
    final paymentMethod = order['payment_method'] as String? ?? 'N/A';
    final shippingAddress = order['shipping_address'] as Map<String, dynamic>?;
    final items = order['items'] as List<Map<String, dynamic>>? ?? [];

    String formattedDate = '';
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Info Card
          _buildInfoCard(context, formattedDate, paymentMethod),
          const SizedBox(height: AppSpacing.xl),

          // Order Timeline
          Text('Order Status', style: AppTextStyles.h6),
          const SizedBox(height: AppSpacing.lg),
          _buildTimeline(context, status),
          const SizedBox(height: AppSpacing.xl),

          // Order Items
          Text('Items', style: AppTextStyles.h6),
          const SizedBox(height: AppSpacing.md),
          _buildItemsList(context, items),
          const SizedBox(height: AppSpacing.xl),

          // Shipping Address
          if (shippingAddress != null) ...[
            Text('Shipping Address', style: AppTextStyles.h6),
            const SizedBox(height: AppSpacing.md),
            _buildAddressCard(context, shippingAddress),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Total
          _buildTotalCard(total),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String date, String paymentMethod) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _buildInfoRow(
              'Order ID', '#${orderId.substring(0, 8).toUpperCase()}'),
          Divider(color: Theme.of(context).dividerColor, height: 20),
          _buildInfoRow('Date', date),
          Divider(color: Theme.of(context).dividerColor, height: 20),
          _buildInfoRow('Payment', paymentMethod),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context, String currentStatus) {
    final currentIndex = OrderStatus.getIndex(currentStatus);

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: List.generate(OrderStatus.progression.length, (index) {
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;
          final isLast = index == OrderStatus.progression.length - 1;

          return _buildTimelineStep(
            context,
            label: OrderStatus.labels[OrderStatus.progression[index]] ??
                OrderStatus.progression[index],
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: isLast,
          );
        }),
      ),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required String label,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color dotColor;
    if (isCompleted && !isCurrent) {
      dotColor = AppColors.success;
    } else if (isCurrent) {
      dotColor = AppColors.warning;
    } else {
      dotColor = Theme.of(context).dividerColor;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot and line
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: dotColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: dotColor, width: 2),
              ),
              child: isCompleted && !isCurrent
                  ? const Icon(Iconsax.tick_circle,
                      size: 12, color: AppColors.success)
                  : isCurrent
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted
                    ? AppColors.success
                    : Theme.of(context).dividerColor,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        // Label
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              color: isCompleted
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(
      BuildContext context, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No items found',
          style: AppTextStyles.bodySmall,
        ),
      );
    }

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
          final quantity = item['quantity'] as int? ?? 1;
          final productId = item['product_id'] as String? ?? '';

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: AppRadius.allSm,
                    ),
                    child: const Center(
                      child: Icon(
                        Iconsax.box_1,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product ${productId.substring(0, 8)}',
                          style: AppTextStyles.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Qty: $quantity',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\u20B9${(price * quantity).toStringAsFixed(0)}',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (index < items.length - 1)
                Divider(color: Theme.of(context).dividerColor, height: 20),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Map<String, dynamic> address) {
    final name = address['name'] as String? ?? '';
    final line1 = address['address_line_1'] as String? ?? '';
    final line2 = address['address_line_2'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final state = address['state'] as String? ?? '';
    final pincode = address['pincode'] as String? ?? '';
    final phone = address['phone'] as String? ?? '';

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.location, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(name, style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            [line1, line2, '$city, $state - $pincode']
                .where((s) => s.isNotEmpty)
                .join('\n'),
            style: AppTextStyles.bodySmall,
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Phone: $phone', style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalCard(double total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Order Total', style: AppTextStyles.h6),
          Text(
            '\u20B9${total.toStringAsFixed(0)}',
            style: AppTextStyles.h4.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return EmptyState(
      icon: Iconsax.bag_2,
      title: 'Order not found',
      ctaLabel: 'Go Back',
      onCta: () => context.pop(),
    );
  }

  Widget _buildError(WidgetRef ref, String error) {
    return EmptyState(
      icon: Iconsax.warning_2,
      title: 'Failed to load order',
      subtitle: error,
      ctaLabel: 'Retry',
      ctaIcon: Iconsax.refresh,
      onCta: () => ref.invalidate(orderDetailProvider(orderId)),
    );
  }
}
