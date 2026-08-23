import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Default subscription plans returned when DB is empty or unavailable
const List<Map<String, dynamic>> _defaultPlans = [
  {
    'id': 'a1b2c3d4-0001-4000-8000-000000000001',
    'name': 'Free',
    'price': 0,
    'duration_days': 30,
    'is_active': true,
    'features': ['Basic profile', '5 campaign applications/month', 'Standard support'],
  },
  {
    'id': 'a1b2c3d4-0002-4000-8000-000000000002',
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
    'id': 'a1b2c3d4-0003-4000-8000-000000000003',
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
    'id': 'a1b2c3d4-0004-4000-8000-000000000004',
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

/// De-duplicate a list of row maps by a unique key, preserving order and
/// keeping the FIRST occurrence of each key. Rows without a usable key are
/// kept as-is (they can't collide meaningfully).
List<Map<String, dynamic>> _dedupById(
  List<Map<String, dynamic>> rows, {
  String key = 'id',
}) {
  final seen = <String>{};
  final result = <Map<String, dynamic>>[];
  for (final row in rows) {
    final value = row[key];
    if (value == null) {
      result.add(row);
      continue;
    }
    final id = value.toString();
    if (seen.add(id)) {
      result.add(row);
    }
  }
  return result;
}

/// De-duplicate plan rows by a normalized (lowercased, trimmed) 'name',
/// keeping the FIRST occurrence and preserving order. This collapses duplicate
/// tiers that share a name but were stored with different ids.
List<Map<String, dynamic>> _dedupByName(List<Map<String, dynamic>> rows) {
  final seen = <String>{};
  final result = <Map<String, dynamic>>[];
  for (final row in rows) {
    final rawName = row['name'];
    if (rawName == null) {
      result.add(row);
      continue;
    }
    final name = rawName.toString().trim().toLowerCase();
    if (name.isEmpty || seen.add(name)) {
      result.add(row);
    }
  }
  return result;
}

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
      return _dedupByName(_dedupById(_defaultPlans));
    }

    // De-duplicate first by unique 'id', then collapse same-tier rows by
    // normalized 'name'. The DB can contain duplicate plans that share a name
    // but have DIFFERENT ids (e.g. seeded more than once with new UUIDs), so
    // an id-only de-dup is not enough — a tier like "Free"/"Pro" would still
    // render twice. Rows are ordered by price asc, so the first occurrence of
    // each name is kept.
    return _dedupByName(_dedupById(plans));
  } catch (e) {
    debugPrint('Subscriptions error: $e');
    // Return default plans on error (e.g., table doesn't exist or RLS issue)
    return _dedupByName(_dedupById(_defaultPlans));
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

    final subs = List<Map<String, dynamic>>.from(response);

    // De-duplicate defensively: first by row 'id', then collapse duplicate
    // rows for the same 'plan_id'. Rows are ordered newest-first, so keeping
    // the first occurrence keeps the most recent subscription per plan and
    // prevents the same active plan card from rendering twice.
    final byId = _dedupById(subs);
    return _dedupById(byId, key: 'plan_id');
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

/// Provider for the user's own submitted subscription payments (any status).
/// Lets the Subscriptions screen show a "pending admin approval" state after
/// the user submits a manual payment.
final userSubscriptionPaymentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    final response = await SupabaseService.client
        .from('subscription_payments')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('Subscription payments error: $e');
    return [];
  }
});

/// StateNotifier for subscription actions.
///
/// IMPORTANT: subscribing no longer instantly activates a subscription.
/// [submitSubscriptionPayment] records a manual payment (mirroring the wallet
/// deposit flow) with status 'pending'. A subscription only becomes 'active'
/// after an admin approves the payment proof (see
/// AdminActionsNotifier.approveSubscriptionPayment).
class SubscriptionNotifier extends StateNotifier<SubscriptionActionState> {
  SubscriptionNotifier() : super(const SubscriptionActionState());

  /// Submit a manual subscription payment for admin review.
  ///
  /// Inserts a row into `subscription_payments` with status 'pending'. Does NOT
  /// touch `user_subscriptions` — activation happens on admin approval.
  /// Returns true only when the row was actually persisted.
  Future<bool> submitSubscriptionPayment({
    required String planId,
    required int durationDays,
    required double amount,
    required String paymentMethod,
    required String transactionRef,
    String? planName,
    String? proofUrl,
  }) async {
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

      await SupabaseService.client.from('subscription_payments').insert({
        'user_id': user.id,
        'plan_id': planId,
        'plan_name': planName,
        'amount': amount,
        'duration_days': durationDays,
        'payment_method': paymentMethod,
        'transaction_ref': transactionRef,
        'proof_url': proofUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
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
