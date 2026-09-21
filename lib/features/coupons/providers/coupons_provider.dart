import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_utils.dart';
import '../../../services/supabase_service.dart';

/// Provider for available coupons (active and not expired)
final availableCouponsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final now = DateTime.now().toIso8601String();

  final response = await SupabaseService.client
      .from('coupons')
      .select()
      .eq('is_active', true)
      .gt('expires_at', now)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Provider for user's reward points
final userRewardPointsProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  final response = await SupabaseService.client
      .from('reward_points')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();

  return response;
});

/// State for coupon application
class CouponState {
  final bool isApplying;
  final String? error;
  final Map<String, dynamic>? appliedCoupon;
  final double discountAmount;

  const CouponState({
    this.isApplying = false,
    this.error,
    this.appliedCoupon,
    this.discountAmount = 0.0,
  });

  CouponState copyWith({
    bool? isApplying,
    String? error,
    Map<String, dynamic>? appliedCoupon,
    double? discountAmount,
  }) {
    return CouponState(
      isApplying: isApplying ?? this.isApplying,
      error: error,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}

/// StateNotifier for applying coupons
class CouponNotifier extends StateNotifier<CouponState> {
  CouponNotifier() : super(const CouponState());

  Future<bool> applyCoupon(String code, double orderTotal) async {
    state = state.copyWith(isApplying: true, error: null);

    try {
      final response = await SupabaseService.client
          .from('coupons')
          .select()
          .eq('code', code.trim().toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        state = state.copyWith(
          isApplying: false,
          error: 'Invalid coupon code',
        );
        return false;
      }

      final minOrder = (response['min_order'] as num?)?.toDouble() ?? 0.0;
      if (orderTotal < minOrder) {
        state = state.copyWith(
          isApplying: false,
          error: 'Minimum order amount is \u20B9${minOrder.toStringAsFixed(0)}',
        );
        return false;
      }

      final maxUses = response['max_uses'] as int? ?? 0;
      final usedCount = response['used_count'] as int? ?? 0;
      if (maxUses > 0 && usedCount >= maxUses) {
        state = state.copyWith(
          isApplying: false,
          error: 'Coupon usage limit reached',
        );
        return false;
      }

      final expiresAt = response['expires_at'] as String?;
      if (expiresAt != null) {
        final expiryDate = DateTime.tryParse(expiresAt);
        if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
          state = state.copyWith(
            isApplying: false,
            error: 'Coupon has expired',
          );
          return false;
        }
      }

      // Calculate discount
      final discountType = response['discount_type'] as String? ?? 'fixed';
      final discountValue =
          (response['discount_value'] as num?)?.toDouble() ?? 0.0;

      double discount;
      if (discountType == 'percentage') {
        discount = orderTotal * (discountValue / 100);
      } else {
        discount = discountValue;
      }

      // Ensure discount does not exceed order total
      if (discount > orderTotal) {
        discount = orderTotal;
      }

      state = CouponState(
        isApplying: false,
        appliedCoupon: response,
        discountAmount: discount,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isApplying: false,
        error: ErrorUtils.sanitize(e),
      );
      return false;
    }
  }

  void removeCoupon() {
    state = const CouponState();
  }
}

/// Provider for the coupon notifier
final couponNotifierProvider =
    StateNotifierProvider<CouponNotifier, CouponState>((ref) {
  return CouponNotifier();
});
