import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

// ============================================================
// READ PROVIDERS
// ============================================================

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = SupabaseService.client;

  final usersResponse = await client.from('users').select('id');
  final campaignsResponse =
      await client.from('campaigns').select('id').eq('status', 'active');
  final depositsResponse =
      await client.from('deposits').select('id').eq('status', 'pending');
  final withdrawalsResponse =
      await client.from('withdrawals').select('id').eq('status', 'pending');
  final kycResponse =
      await client.from('kyc_documents').select('id').eq('status', 'pending');

  return {
    'total_users': (usersResponse as List).length,
    'active_campaigns': (campaignsResponse as List).length,
    'pending_deposits': (depositsResponse as List).length,
    'pending_withdrawals': (withdrawalsResponse as List).length,
    'pending_kyc': (kycResponse as List).length,
    'total_earnings': 0,
  };
});

final adminUsersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, search) async {
  final client = SupabaseService.client;
  var query = client.from('users').select();
  if (search.isNotEmpty) {
    query = query.or('name.ilike.%$search%,email.ilike.%$search%');
  }
  final response = await query.order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final adminCampaignsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client
      .from('campaigns')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final adminSubmissionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client
      .from('submissions')
      .select()
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final adminDepositsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client
      .from('deposits')
      .select()
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Pending subscription payments awaiting admin review. Joins the user's name
/// and email for display. Falls back to the raw row if the join is unavailable.
final adminSubscriptionPaymentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client
      .from('subscription_payments')
      .select('*, users(name, email)')
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final adminWithdrawalsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client
      .from('withdrawals')
      .select()
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final adminDisputesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client
      .from('disputes')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final adminKycProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client
      .from('kyc_documents')
      .select()
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final adminWalletsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client.from('wallets').select();
  return List<Map<String, dynamic>>.from(response);
});

final adminAuditLogsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client
      .from('audit_logs')
      .select()
      .order('created_at', ascending: false)
      .limit(100);
  return List<Map<String, dynamic>>.from(response);
});

final adminOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client
      .from('orders')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final adminProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client
      .from('products')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Product categories loaded from the DB (`product_categories`). This keeps the
/// Add Product category dropdown in sync with the storefront category filter.
/// Falls back to a sensible default list if the table is empty or unreachable.
final adminCategoriesProvider = FutureProvider<List<String>>((ref) async {
  const fallback = <String>[
    'Electronics',
    'Fashion',
    'Beauty',
    'Home & Kitchen',
    'Sports',
    'Books',
    'Toys',
    'Digital Goods',
    'Other',
  ];
  try {
    final response = await SupabaseService.client
        .from('product_categories')
        .select('name')
        .order('sort_order', ascending: true);
    final names = List<Map<String, dynamic>>.from(response)
        .map((row) => (row['name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    return names.isEmpty ? fallback : names;
  } catch (_) {
    return fallback;
  }
});

final adminPlatformSettingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response = await client.from('platform_settings').select();
  return List<Map<String, dynamic>>.from(response);
});

// ============================================================
// ACTIONS NOTIFIER
// ============================================================

class AdminActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  AdminActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> updateUserStatus(String userId, String status) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('users')
          .update({'account_status': status}).eq('id', userId);
      ref.invalidate(adminUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> verifyUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('users')
          .update({'is_verified': true}).eq('id', userId);
      ref.invalidate(adminUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('users')
          .update({'role': role}).eq('id', userId);
      ref.invalidate(adminUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCampaignStatus(String campaignId, String status) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('campaigns')
          .update({'status': status}).eq('id', campaignId);
      ref.invalidate(adminCampaignsProvider);
      ref.invalidate(adminStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Hard-delete a campaign. Authorized by the admin DELETE RLS policy in
  /// supabase/add_campaign_delete_rls.sql (is_admin()). Returns `true` when the
  /// delete completed without error, mirroring [deleteProduct]/[createProduct].
  Future<bool> deleteCampaign(String campaignId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('campaigns')
          .delete()
          .eq('id', campaignId);
      ref.invalidate(adminCampaignsProvider);
      ref.invalidate(adminStatsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> approveSubmission(String submissionId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('submissions')
          .update({'status': 'approved'}).eq('id', submissionId);
      ref.invalidate(adminSubmissionsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectSubmission(String submissionId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('submissions')
          .update({'status': 'rejected'}).eq('id', submissionId);
      ref.invalidate(adminSubmissionsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> disburseSubmissionPayout(
      String submissionId, double amount) async {
    state = const AsyncValue.loading();
    try {
      // Fetch the creator so we can credit their wallet.
      final submission = await SupabaseService.client
          .from('submissions')
          .select('creator_id')
          .eq('id', submissionId)
          .single();
      final creatorId = submission['creator_id'] as String;

      // Mark the submission paid. NOTE: 'paid' is NOT a valid status (the
      // CHECK allows pending/approved/rejected/revision_requested), and there
      // is no payout_amount column — the schema records payment via paid_at.
      await SupabaseService.client.from('submissions').update({
        'status': 'approved',
        'paid_at': DateTime.now().toIso8601String(),
      }).eq('id', submissionId);

      // Actually pay the creator via the atomic wallet RPC.
      await SupabaseService.client.rpc('credit_wallet', params: {
        'p_user_id': creatorId,
        'p_amount': amount,
      });

      ref.invalidate(adminSubmissionsProvider);
      ref.invalidate(adminWalletsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> approveDeposit(String depositId) async {
    state = const AsyncValue.loading();
    try {
      // Fetch the deposit to get user_id and amount
      final deposit = await SupabaseService.client
          .from('deposits')
          .select('user_id, amount')
          .eq('id', depositId)
          .single();

      final userId = deposit['user_id'] as String;
      final amount = (deposit['amount'] as num).toDouble();

      // Update deposit status to approved
      await SupabaseService.client
          .from('deposits')
          .update({'status': 'approved'}).eq('id', depositId);

      // Credit the user's wallet using atomic RPC function
      await SupabaseService.client.rpc('credit_wallet', params: {
        'p_user_id': userId,
        'p_amount': amount,
      });

      ref.invalidate(adminDepositsProvider);
      ref.invalidate(adminWalletsProvider);
      ref.invalidate(adminStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectDeposit(String depositId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('deposits')
          .update({'status': 'rejected'}).eq('id', depositId);
      ref.invalidate(adminDepositsProvider);
      ref.invalidate(adminStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Approve a pending subscription payment.
  ///
  /// Marks the payment 'approved' (with processed_at) and then activates the
  /// subscription by inserting a row into user_subscriptions (status 'active',
  /// starts_at now, ends_at now + duration_days) — mirroring the shape of the
  /// old client-side subscribe() insert. This is the ONLY place a subscription
  /// becomes active.
  Future<void> approveSubscriptionPayment(String paymentId) async {
    state = const AsyncValue.loading();
    try {
      // Fetch the payment details needed to activate the subscription.
      final payment = await SupabaseService.client
          .from('subscription_payments')
          .select('user_id, plan_id, duration_days')
          .eq('id', paymentId)
          .single();

      final userId = payment['user_id'] as String;
      final planId = payment['plan_id'] as String;
      final durationDays = (payment['duration_days'] as num?)?.toInt() ?? 30;

      final now = DateTime.now();
      final endsAt = now.add(Duration(days: durationDays));

      // 1) Mark payment approved.
      await SupabaseService.client.from('subscription_payments').update({
        'status': 'approved',
        'processed_at': now.toIso8601String(),
      }).eq('id', paymentId);

      // 2) Activate the subscription.
      await SupabaseService.client.from('user_subscriptions').insert({
        'user_id': userId,
        'plan_id': planId,
        'status': 'active',
        'starts_at': now.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'created_at': now.toIso8601String(),
      });

      ref.invalidate(adminSubscriptionPaymentsProvider);
      ref.invalidate(adminStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reject a pending subscription payment. Does NOT activate any subscription.
  Future<void> rejectSubscriptionPayment(String paymentId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.from('subscription_payments').update({
        'status': 'rejected',
        'processed_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);
      ref.invalidate(adminSubscriptionPaymentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> approveWithdrawal(String withdrawalId) async {
    state = const AsyncValue.loading();
    try {
      // Fetch the withdrawal to get user_id and amount
      final withdrawal = await SupabaseService.client
          .from('withdrawals')
          .select('user_id, amount')
          .eq('id', withdrawalId)
          .single();

      final userId = withdrawal['user_id'] as String;
      final amount = (withdrawal['amount'] as num).toDouble();

      // Update withdrawal status to approved
      await SupabaseService.client
          .from('withdrawals')
          .update({'status': 'approved'}).eq('id', withdrawalId);

      // Debit the user's wallet using atomic RPC function
      await SupabaseService.client.rpc('debit_wallet', params: {
        'p_user_id': userId,
        'p_amount': amount,
      });

      ref.invalidate(adminWithdrawalsProvider);
      ref.invalidate(adminWalletsProvider);
      ref.invalidate(adminStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectWithdrawal(String withdrawalId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('withdrawals')
          .update({'status': 'rejected'}).eq('id', withdrawalId);
      ref.invalidate(adminWithdrawalsProvider);
      ref.invalidate(adminStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> approveKyc(String kycId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('kyc_documents')
          .update({'status': 'approved'}).eq('id', kycId);
      ref.invalidate(adminKycProvider);
      ref.invalidate(adminStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rejectKyc(String kycId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('kyc_documents')
          .update({'status': 'rejected'}).eq('id', kycId);
      ref.invalidate(adminKycProvider);
      ref.invalidate(adminStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> creditWallet(String walletId, double amount) async {
    state = const AsyncValue.loading();
    try {
      // RACE CONDITION NOTE: Same read-then-write limitation as approveDeposit.
      // See supabase/wallet_balance_rpc.sql for the atomic RPC alternative.
      final wallet = await SupabaseService.client
          .from('wallets')
          .select('available_balance')
          .eq('id', walletId)
          .single();
      final currentBalance = (wallet['available_balance'] as num).toDouble();
      await SupabaseService.client.from('wallets').update(
          {'available_balance': currentBalance + amount}).eq('id', walletId);
      ref.invalidate(adminWalletsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> debitWallet(String walletId, double amount) async {
    state = const AsyncValue.loading();
    try {
      // RACE CONDITION NOTE: Same read-then-write limitation as approveWithdrawal.
      // See supabase/wallet_balance_rpc.sql for the atomic RPC alternative.
      final wallet = await SupabaseService.client
          .from('wallets')
          .select('available_balance')
          .eq('id', walletId)
          .single();
      final currentBalance = (wallet['available_balance'] as num).toDouble();
      if (currentBalance - amount < 0) {
        throw Exception('Insufficient balance for this debit.');
      }
      await SupabaseService.client.from('wallets').update(
          {'available_balance': currentBalance - amount}).eq('id', walletId);
      ref.invalidate(adminWalletsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> freezeWallet(String walletId) async {
    state = const AsyncValue.loading();
    try {
      // The wallets table uses an `is_frozen` boolean — there is no `status`
      // column, so the previous {'status':'frozen'} update always errored.
      await SupabaseService.client
          .from('wallets')
          .update({'is_frozen': true}).eq('id', walletId);
      ref.invalidate(adminWalletsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePlatformSetting(String key, dynamic value) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('platform_settings')
          .update({'value': value}).eq('key', key);
      ref.invalidate(adminPlatformSettingsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Send an admin broadcast to ALL users.
  ///
  /// Delegates to the `send-broadcast` Supabase Edge Function, which is the
  /// authoritative path: it inserts one in-app notification row per user AND
  /// delivers a real FCM push (HTTP v1) to their devices, using the
  /// service-account key server-side. The client intentionally does NOT insert
  /// notification rows here — that would duplicate what the function inserts.
  ///
  /// The old client-side FCM code (`_getFirebaseAccessToken`/`_sendFcmBroadcast`)
  /// was removed: it built an UNSIGNED JWT assertion that Google always
  /// rejected, and shipping the RSA private key in the app is insecure.
  ///
  /// Best-effort: a failed invocation surfaces a sanitized error via [state]
  /// but never crashes the app.
  /// Sends a broadcast via the send-broadcast Edge Function and returns the
  /// function's result ({ok, inserted, pushed, failed, pushError}) so the UI
  /// can show exactly how many in-app rows were inserted vs FCM pushes
  /// delivered — invaluable for diagnosing "in-app works but push doesn't".
  Future<Map<String, dynamic>?> sendBroadcast(
      String title, String message) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseService.client.functions.invoke(
        'send-broadcast',
        body: {'title': title, 'message': message},
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : null;

      // Treat non-2xx responses from the Edge Function as failures.
      final status = response.status;
      if (status < 200 || status >= 300) {
        final err = data?['error']?.toString() ?? 'status $status';
        throw Exception('Broadcast failed: $err');
      }

      state = const AsyncValue.data(null);
      return data;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> createAuditLog(String action, String details) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.from('audit_logs').insert({
        'action_type': action,
        'reason': details,
        'admin_id': SupabaseService.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });
      ref.invalidate(adminAuditLogsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resolveDispute(String disputeId, String resolution) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.from('disputes').update({
        'status': 'resolved',
        'resolution': resolution,
      }).eq('id', disputeId);
      ref.invalidate(adminDisputesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Insert a product into Supabase.
  ///
  /// Returns `true` only when the row was actually persisted (the insert
  /// completed without throwing). Returns `false` on any error, and stores the
  /// error in [state] so callers can surface a sanitized message. This lets the
  /// Add Product screen show success ONLY after the real DB write succeeds.
  Future<bool> createProduct(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.from('products').insert(data);
      ref.invalidate(adminProductsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> updateProduct(
      String productId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('products')
          .update(data)
          .eq('id', productId);
      ref.invalidate(adminProductsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Hard-delete a product. The admin DELETE RLS policy in
  /// supabase/fix_admin_rls.sql (is_admin()) authorizes this. Returns `true`
  /// when the delete completed without error.
  Future<bool> deleteProduct(String productId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('products')
          .delete()
          .eq('id', productId);
      ref.invalidate(adminProductsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('orders')
          .update({'status': status}).eq('id', orderId);
      ref.invalidate(adminOrdersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminActionsProvider =
    StateNotifierProvider<AdminActionsNotifier, AsyncValue<void>>((ref) {
  return AdminActionsNotifier(ref);
});
