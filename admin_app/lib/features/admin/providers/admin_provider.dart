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
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
      await SupabaseService.client.from('submissions').update(
          {'status': 'paid', 'payout_amount': amount}).eq('id', submissionId);
      ref.invalidate(adminSubmissionsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> approveDeposit(String depositId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('deposits')
          .update({'status': 'approved'}).eq('id', depositId);
      ref.invalidate(adminDepositsProvider);
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

  Future<void> approveWithdrawal(String withdrawalId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('withdrawals')
          .update({'status': 'approved'}).eq('id', withdrawalId);
      ref.invalidate(adminWithdrawalsProvider);
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

  Future<void> creditWallet(String walletId, double amount) async {
    state = const AsyncValue.loading();
    try {
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
      await SupabaseService.client
          .from('wallets')
          .update({'status': 'frozen'}).eq('id', walletId);
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

  Future<void> sendBroadcast(String title, String message) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.from('notifications').insert({
        'title': title,
        'message': message,
        'type': 'broadcast',
        'created_at': DateTime.now().toIso8601String(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

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

  Future<void> createProduct(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.from('products').insert(data);
      ref.invalidate(adminProductsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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

  Future<void> deleteProduct(String productId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .from('products')
          .delete()
          .eq('id', productId);
      ref.invalidate(adminProductsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
