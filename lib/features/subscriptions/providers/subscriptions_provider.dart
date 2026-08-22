import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/supabase_service.dart';

/// Provider for available subscription plans
final subscriptionPlansProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await SupabaseService.client
        .from('subscription_plans')
        .select()
        .eq('is_active', true)
        .order('price', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    // Return empty list on error (e.g., table doesn't exist or RLS issue)
    return [];
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
