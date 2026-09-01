import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../core/widgets/section_header.dart';
import '../../coupons/providers/coupons_provider.dart';
import '../providers/shop_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _couponController = TextEditingController();

  String _selectedPaymentMethod = 'UPI';
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  bool get _hasPhysicalProducts {
    final items = ref.read(cartProvider);
    return items.any(
      (item) =>
          item.product['category']?.toString().toLowerCase() == 'physical',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final totalAmount = ref.watch(cartTotalProvider);

    if (cartItems.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PremiumAppBar(
          title: 'Checkout',
          showBack: true,
          onBack: () => context.pop(),
        ),
        body: EmptyState(
          icon: Iconsax.shopping_cart,
          title: 'Your cart is empty',
          cta: PremiumButton(
            label: 'Go to Shop',
            expand: false,
            icon: Iconsax.shop,
            onPressed: () => context.go('/shop'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Checkout',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Apply Coupon section
                    _buildCouponSection(context, totalAmount),
                    const SizedBox(height: AppSpacing.lg),

                    // Order items summary
                    _buildOrderItemsSummary(context, cartItems),
                    const SizedBox(height: AppSpacing.xl),

                    // Shipping address (only for physical products)
                    if (_hasPhysicalProducts) ...[
                      const SectionHeader(title: 'Shipping Address'),
                      const SizedBox(height: AppSpacing.md),
                      _buildShippingForm(context),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Payment method
                    const SectionHeader(title: 'Payment Method'),
                    const SizedBox(height: AppSpacing.md),
                    _buildPaymentSelection(context),
                    const SizedBox(height: AppSpacing.xl),

                    // Order total
                    _buildOrderTotal(context, totalAmount),
                  ],
                ),
              ),
            ),
          ),

          // Place order button
          _buildPlaceOrderButton(context, cartItems, totalAmount),
        ],
      ),
    );
  }

  Widget _buildCouponSection(BuildContext context, double totalAmount) {
    final couponState = ref.watch(couponNotifierProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apply Coupon',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (couponState.appliedCoupon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.05),
                borderRadius: AppRadius.allSm,
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.tick_circle,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coupon applied: ${couponState.appliedCoupon!['code']}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Discount: -\u20B9${couponState.discountAmount.toStringAsFixed(0)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PremiumIconButton(
                    icon: Iconsax.close_circle,
                    iconSize: 18,
                    onPressed: () {
                      ref
                          .read(couponNotifierProvider.notifier)
                          .removeCoupon();
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    controller: _couponController,
                    hint: 'Enter coupon code',
                    prefixIcon: Iconsax.ticket_discount,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                PremiumButton(
                  label: 'Apply',
                  expand: false,
                  loading: couponState.isApplying,
                  onPressed: couponState.isApplying
                      ? null
                      : () {
                          if (_couponController.text.trim().isNotEmpty) {
                            ref
                                .read(couponNotifierProvider.notifier)
                                .applyCoupon(
                                  _couponController.text.trim(),
                                  totalAmount,
                                );
                          }
                        },
                ),
              ],
            ),
            if (couponState.error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                couponState.error!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItemsSummary(BuildContext context, List<CartItem> items) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary (${items.length} items)',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product['title']}',
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '\u20B9${item.subtotal.toStringAsFixed(0)}',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildShippingForm(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          PremiumTextField(
            controller: _nameController,
            label: 'Full Name',
            prefixIcon: Iconsax.user,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          PremiumTextField(
            controller: _address1Controller,
            label: 'Address Line 1',
            prefixIcon: Iconsax.location,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Address is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          PremiumTextField(
            controller: _address2Controller,
            label: 'Address Line 2 (Optional)',
            prefixIcon: Iconsax.building,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PremiumTextField(
                  controller: _cityController,
                  label: 'City',
                  prefixIcon: Iconsax.buildings,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PremiumTextField(
                  controller: _stateController,
                  label: 'State',
                  prefixIcon: Iconsax.map,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PremiumTextField(
                  controller: _pincodeController,
                  label: 'Pincode',
                  prefixIcon: Iconsax.hashtag,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length != 6) return 'Invalid pincode';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PremiumTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  prefixIcon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 10) return 'Invalid phone';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelection(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _buildPaymentOption(context, 'UPI', Iconsax.mobile),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _buildPaymentOption(context, 'Wallet Balance', Iconsax.wallet_2),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      BuildContext context, String method, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;

    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMethod = method);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                method,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTotal(BuildContext context, double totalAmount) {
    final couponState = ref.watch(couponNotifierProvider);
    final discount = couponState.discountAmount;
    final finalTotal = totalAmount - discount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: AppTextStyles.bodyMedium),
              Text(
                '\u20B9${totalAmount.toStringAsFixed(0)}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coupon Discount',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
                Text(
                  '-\u20B9${discount.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            Divider(color: Theme.of(context).dividerColor, height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order Total', style: AppTextStyles.h6),
              Text(
                '\u20B9${finalTotal.toStringAsFixed(0)}',
                style: AppTextStyles.h4.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(
      BuildContext context, List<CartItem> items, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: PremiumButton(
          label: 'Place Order',
          gradient: true,
          loading: _isPlacingOrder,
          onPressed: _isPlacingOrder
              ? null
              : () => _handlePlaceOrder(items, totalAmount),
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder(
    List<CartItem> items,
    double totalAmount,
  ) async {
    // Validate form if physical products exist
    if (_hasPhysicalProducts && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isPlacingOrder = true);

    Map<String, dynamic>? shippingAddress;
    if (_hasPhysicalProducts) {
      shippingAddress = {
        'name': _nameController.text.trim(),
        'address_line_1': _address1Controller.text.trim(),
        'address_line_2': _address2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
    }

    final success = await placeOrder(
      items: items,
      totalAmount: totalAmount,
      shippingAddress: shippingAddress,
      paymentMethod: _selectedPaymentMethod,
    );

    if (!mounted) return;

    setState(() => _isPlacingOrder = false);

    if (success) {
      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      // Show success dialog and navigate
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Iconsax.tick_circle, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Text('Order Placed!', style: AppTextStyles.h6),
            ],
          ),
          content: Text(
            'Your order has been placed successfully. You will receive a confirmation shortly.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/shop');
              },
              child: Text(
                'Continue Shopping',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to place order. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.allSm,
          ),
        ),
      );
    }
  }
}
