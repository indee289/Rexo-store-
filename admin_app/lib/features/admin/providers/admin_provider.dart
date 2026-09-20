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

/// All users, optionally filtered by search term.
/// Live users table uses camelCase "createdAt" for the timestamp column.
final adminUsersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, search) async {
  final client = SupabaseService.client;
  var query = client.from('users').select();
  if (search.isNotEmpty) {
    query = query.or('name.ilike.%$search%,email.ilike.%$search%');
  }
  // Live column is "createdAt" (camelCase), not created_at.
  final response = await query.order('createdAt', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final adminCampaignsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response =
      await client.from('campaigns').select().order('created_at', ascending: false);
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
  final response =
      await client.from('disputes').select().order('created_at', ascending: false);
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
  final response =
      await client.from('orders').select().order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final adminProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.client;
  final response =
      await client.from('products').select().order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Product categories loaded from the DB (`product_categories`). Falls back to
/// a sensible default list if the table is empty or unreachable.
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

  // ── Users ──────────────────────────────────────────────────────────────────

  /// Ban or unban a user. Live column: `isBanned` (boolean).
  /// Identity column: `uid` (text) — NOT `id` (uuid).
  /// There is no `account_status` column in the live users schema.
  Future<void> updateUserBanStatus(String userUid, bool banned) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('users')
          .update({'isBanned': banned}).eq('uid', userUid);
      ref.invalidate(adminUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Verify a user. Live column: `isVerified` (camelCase boolean).
  /// Identity column: `uid` (text) — NOT `id` (uuid).
  Future<void> verifyUser(String userUid) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('users')
          .update({'isVerified': true}).eq('uid', userUid);
      ref.invalidate(adminUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Change a user's role. Identity column: `uid` (text) — NOT `id` (uuid).
  Future<void> updateUserRole(String userUid, String role) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('users')
          .update({'role': role}).eq('uid', userUid);
      ref.invalidate(adminUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── Campaigns ──────────────────────────────────────────────────────────────

  Future<void> updateCampaignStatus(String campaignId, String status) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('campaigns')
          .update({'status': status}).eq('id', campaignId);
      ref.invalidate(adminCampaignsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── Submissions ────────────────────────────────────────────────────────────

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
      await SupabaseService.client.from('submissions').update({
        'status': 'paid',
        'payout_amount': amount,
      }).eq('id', submissionId);
      ref.invalidate(adminSubmissionsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── Deposits ───────────────────────────────────────────────────────────────

  Future<void> approveDeposit(String depositId) async {
    state = const AsyncValue.loading();
    try {
      final deposit = await SupabaseService.client
          .from('deposits')
          .select('user_id, amount')
          .eq('id', depositId)
          .single();

      final userId = deposit['user_id'] as String;
      final amount = (deposit['amount'] as num).toDouble();

      await SupabaseService.client
          .from('deposits')
          .update({'status': 'approved'}).eq('id', depositId);

      // Credit the user's wallet using atomic RPC (no race condition).
      await SupabaseService.client.rpc('credit_wallet', params: {
        'p_user_id': userId,
        'p_amount': amount,
      });

      ref.invalidate(adminDepositsProvider);
      ref.invalidate(adminWalletsProvider);
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
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── Withdrawals ────────────────────────────────────────────────────────────

  Future<void> approveWithdrawal(String withdrawalId) async {
    state = const AsyncValue.loading();
    try {
      final withdrawal = await SupabaseService.client
          .from('withdrawals')
          .select('user_id, amount')
          .eq('id', withdrawalId)
          .single();

      final userId = withdrawal['user_id'] as String;
      final amount = (withdrawal['amount'] as num).toDouble();

      // Status must be 'completed' — the live CHECK constraint is:
      // pending | processing | completed | rejected
      // 'approved' is NOT a valid status and will be rejected by Postgres.
      await SupabaseService.client
          .from('withdrawals')
          .update({'status': 'completed'}).eq('id', withdrawalId);

      // Debit the user's wallet using atomic RPC (no race condition).
      await SupabaseService.client.rpc('debit_wallet', params: {
        'p_user_id': userId,
        'p_amount': amount,
      });

      ref.invalidate(adminWithdrawalsProvider);
      ref.invalidate(adminWalletsProvider);
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
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── KYC ────────────────────────────────────────────────────────────────────

  Future<void> approveKyc(String kycId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('kyc_documents')
          .update({'status': 'approved'}).eq('id', kycId);
      ref.invalidate(adminKycProvider);
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
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── Wallets ────────────────────────────────────────────────────────────────

  /// Credit a wallet by wallet row `id`.
  /// Resolves to `user_id`, then uses the atomic `credit_wallet` RPC.
  /// This avoids the race-prone read-then-write pattern.
  Future<void> creditWallet(String walletId, double amount) async {
    state = const AsyncValue.loading();
    try {
      final wallet = await SupabaseService.client
          .from('wallets')
          .select('user_id')
          .eq('id', walletId)
          .single();
      final userId = wallet['user_id'] as String;

      await SupabaseService.client.rpc('credit_wallet', params: {
        'p_user_id': userId,
        'p_amount': amount,
      });

      ref.invalidate(adminWalletsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Debit a wallet by wallet row `id`.
  /// Resolves to `user_id`, then uses the atomic `debit_wallet` RPC.
  /// Server enforces the balance >= 0 floor.
  Future<void> debitWallet(String walletId, double amount) async {
    state = const AsyncValue.loading();
    try {
      final wallet = await SupabaseService.client
          .from('wallets')
          .select('user_id')
          .eq('id', walletId)
          .single();
      final userId = wallet['user_id'] as String;

      await SupabaseService.client.rpc('debit_wallet', params: {
        'p_user_id': userId,
        'p_amount': amount,
      });

      ref.invalidate(adminWalletsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Freeze a wallet. Live column: `is_frozen` (boolean).
  /// There is no `status` column on wallets — the previous
  /// {'status': 'frozen'} update always errored silently.
  Future<void> freezeWallet(String walletId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('wallets')
          .update({'is_frozen': true}).eq('id', walletId);
      ref.invalidate(adminWalletsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Unfreeze a wallet.
  Future<void> unfreezeWallet(String walletId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('wallets')
          .update({'is_frozen': false}).eq('id', walletId);
      ref.invalidate(adminWalletsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── Platform settings ──────────────────────────────────────────────────────

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

  // ── Broadcast ──────────────────────────────────────────────────────────────

  /// Send an admin broadcast to ALL users via the `send-broadcast` Edge Function.
  ///
  /// The Edge Function inserts one in-app notification row per user (using
  /// the live column names: "userId", message, "createdAt") AND delivers FCM
  /// pushes server-side. Inserting rows here directly would:
  ///   1. Duplicate rows the function already inserts.
  ///   2. Fail the NOT NULL constraint on "userId" (no single userId for broadcast).
  ///   3. Bypass FCM delivery entirely.
  ///
  /// The old direct INSERT approach (using 'created_at', no 'userId') was wrong
  /// against the live schema and has been removed.
  Future<void> sendBroadcast(String title, String message) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseService.client.functions.invoke(
        'send-broadcast',
        body: {'title': title, 'message': message},
      );

      final status = response.status;
      if (status < 200 || status >= 300) {
        final data = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : null;
        final err = data?['error']?.toString() ?? 'status $status';
        throw Exception('Broadcast failed: $err');
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── Misc ───────────────────────────────────────────────────────────────────

  Future<void> createAuditLog(String action, String details) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.from('audit_logs').insert({
        'action': action,
        'details': details,
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
