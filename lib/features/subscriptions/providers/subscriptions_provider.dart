import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/supabase_service.dart';

/// Default subscription plans returned when DB is empty or unavailable
const List<Map<String, dynamic>> _defaultPlans = [
  {
    'id': 'default-free',
    'name': 'Free',
    'price': 0,
    'duration_days': 30,
    'is_active': true,
    'features': ['Basic profile', '5 campaign applications/month', 'Standard support'],
  },
  {
    'id': 'default-pro',
    'name': 'Pro',
    'price': 299,
    'duration_days': 30,
    'is_active': true,
    'features': [
      'Unlimited campaign applications',
      'Priority listing',
      'Advanced analytics',
      'Pro badge',
    ],
  },
  {
    'id': 'default-ultra',
    'name': 'Ultra',
    'price': 599,
    'duration_days': 30,
    'is_active': true,
    'features': [
      'Everything in Pro',
      'Verified badge',
      'Featured placement',
      'Priority support',
    ],
  },
  {
    'id': 'default-premium-max',
    'name': 'Premium Max',
    'price': 999,
    'duration_days': 30,
    'is_active': true,
    'features': [
      'Everything in Ultra',
      'Dedicated account manager',
      'Custom media kit',
      'Priority payouts',
      'Early access to features',
    ],
  },
];

/// Provider for available subscription plans
final subscriptionPlansProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await SupabaseService.client
        .from('subscription_plans')
        .select()
        .eq('is_active', true)
        .order('price', ascending: true);

    final plans = List<Map<String, dynamic>>.from(response);

    // Return hardcoded default plans when DB returns empty
    if (plans.isEmpty) {
      return _defaultPlans;
    }

    return plans;
  } catch (e) {
    debugPrint('Subscriptions error: $e');
    // Return default plans on error (e.g., table doesn't exist or RLS issue)
    return _defaultPlans;
  }
});

/// Provider for user's active subscriptions
final userSubscriptionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    final response = await SupabaseService.client
        .from('user_subscriptions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('Subscriptions error: $e');
    // Return empty list on error
    return [];
  }
});

/// State for subscription actions
class SubscriptionActionState {
  final bool isProcessing;
  final String? error;
  final bool success;

  const SubscriptionActionState({
    this.isProcessing = false,
    this.error,
    this.success = false,
  });

  SubscriptionActionState copyWith({
    bool? isProcessing,
    String? error,
    bool? success,
  }) {
    return SubscriptionActionState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// StateNotifier for subscription actions (subscribe/cancel)
class SubscriptionNotifier extends StateNotifier<SubscriptionActionState> {
  SubscriptionNotifier() : super(const SubscriptionActionState());

  Future<bool> subscribe(String planId, int durationDays) async {
    state = state.copyWith(isProcessing: true, error: null, success: false);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = state.copyWith(
          isProcessing: false,
          error: 'User not authenticated',
        );
        return false;
      }

      const uuid = Uuid();
      final now = DateTime.now();
      final endsAt = now.add(Duration(days: durationDays));

      await SupabaseService.client.from('user_subscriptions').insert({
        'id': uuid.v4(),
        'user_id': user.id,
        'plan_id': planId,
        'status': 'active',
        'starts_at': now.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'created_at': now.toIso8601String(),
      });

      state = state.copyWith(isProcessing: false, success: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> cancelSubscription(String subscriptionId) async {
    state = state.copyWith(isProcessing: true, error: null, success: false);

    try {
      await SupabaseService.client
          .from('user_subscriptions')
          .update({'status': 'cancelled'})
          .eq('id', subscriptionId);

      state = state.copyWith(isProcessing: false, success: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const SubscriptionActionState();
  }
}

/// Provider for the subscription notifier
final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionActionState>((ref) {
  return SubscriptionNotifier();
});
