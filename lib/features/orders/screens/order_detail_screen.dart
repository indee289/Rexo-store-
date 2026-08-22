import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Order Details',
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
      body: orderAsync.when(
        data: (order) {
          if (order == null) return _buildNotFound(context);
          return _buildContent(context, order);
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => _buildError(ref, error.toString()),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Info Card
          _buildInfoCard(formattedDate, paymentMethod),
          const SizedBox(height: 20),

          // Order Timeline
          Text('Order Status', style: AppTextStyles.h6),
          const SizedBox(height: 16),
          _buildTimeline(status),
          const SizedBox(height: 24),

          // Order Items
          Text('Items', style: AppTextStyles.h6),
          const SizedBox(height: 12),
          _buildItemsList(items),
          const SizedBox(height: 20),

          // Shipping Address
          if (shippingAddress != null) ...[
            Text('Shipping Address', style: AppTextStyles.h6),
            const SizedBox(height: 12),
            _buildAddressCard(shippingAddress),
            const SizedBox(height: 20),
          ],

          // Total
          _buildTotalCard(total),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String date, String paymentMethod) {
    return Container(
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
        children: [
          _buildInfoRow('Order ID', '#${orderId.substring(0, 8).toUpperCase()}'),
          const Divider(color: AppColors.divider, height: 20),
          _buildInfoRow('Date', date),
          const Divider(color: AppColors.divider, height: 20),
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

  Widget _buildTimeline(String currentStatus) {
    final currentIndex = OrderStatus.getIndex(currentStatus);

    return Container(
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
        children: List.generate(OrderStatus.progression.length, (index) {
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;
          final isLast = index == OrderStatus.progression.length - 1;

          return _buildTimelineStep(
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

  Widget _buildTimelineStep({
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
      dotColor = AppColors.border;
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
                  ? const Icon(Icons.check, size: 12, color: AppColors.success)
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
                color: isCompleted ? AppColors.success : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Label
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              color: isCompleted
                  ? AppColors.textPrimary
                  : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No items found',
          style: AppTextStyles.bodySmall,
        ),
      );
    }

    return Container(
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Iconsax.box_1,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                const Divider(color: AppColors.divider, height: 20),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final name = address['name'] as String? ?? '';
    final line1 = address['address_line_1'] as String? ?? '';
    final line2 = address['address_line_2'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final state = address['state'] as String? ?? '';
    final pincode = address['pincode'] as String? ?? '';
    final phone = address['phone'] as String? ?? '';

    return Container(
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
            children: [
              const Icon(Iconsax.location, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(name, style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [line1, line2, '$city, $state - $pincode']
                .where((s) => s.isNotEmpty)
                .join('\n'),
            style: AppTextStyles.bodySmall,
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Phone: $phone', style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalCard(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.bag_2, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Order not found', style: AppTextStyles.h5),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(WidgetRef ref, String error) {
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
            Text('Failed to load order', style: AppTextStyles.h5),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
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
