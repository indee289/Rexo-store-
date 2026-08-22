import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import '../../profile/providers/profile_provider.dart';

/// Provider that checks if the current user is an admin
final isAdminProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.whenOrNull(data: (state) => state.isAdmin) ?? false;
});

/// Admin dashboard stats
final adminStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final client = SupabaseService.client;

  final usersResponse = await client.from('users').select('id');
  final totalUsers = (usersResponse as List).length;

  final campaignsResponse = await client
      .from('campaigns')
      .select('id')
      .eq('status', 'active');
  final activeCampaigns = (campaignsResponse as List).length;

  final depositsResponse = await client
      .from('deposits')
      .select('id')
      .eq('status', 'pending');
  final pendingDeposits = (depositsResponse as List).length;

  final withdrawalsResponse = await client
      .from('withdrawals')
      .select('id')
      .eq('status', 'pending');
  final pendingWithdrawals = (withdrawalsResponse as List).length;

  final kycResponse = await client
      .from('kyc_documents')
      .select('id')
      .eq('status', 'pending');
  final pendingKyc = (kycResponse as List).length;

  final walletsResponse = await client.from('wallets').select('available_balance');
  double totalEarnings = 0;
  for (final w in walletsResponse as List) {
    totalEarnings += (w['available_balance'] as num?)?.toDouble() ?? 0;
  }

  return {
    'total_users': totalUsers,
    'active_campaigns': activeCampaigns,
    'pending_deposits': pendingDeposits,
    'pending_withdrawals': pendingWithdrawals,
    'pending_kyc': pendingKyc,
    'total_earnings': totalEarnings,
  };
});

/// All users with optional search
final adminUsersSearchProvider = StateProvider<String>((ref) => '');

final adminUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final search = ref.watch(adminUsersSearchProvider);
  final client = SupabaseService.client;

  var query = client.from('users').select();
  if (search.isNotEmpty) {
    query = query.or('name.ilike.%$search%,email.ilike.%$search%');
  }

  final response = await query.order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// All campaigns (any status)
final adminCampaignsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('campaigns')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Pending submissions with campaign & creator info
final adminSubmissionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('submissions')
      .select('*, campaigns(title), users(name)')
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Pending deposits
final adminDepositsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('deposits')
      .select('*, users(name, email)')
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Pending withdrawals
final adminWithdrawalsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('withdrawals')
      .select('*, users(name, email)')
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// All disputes
final adminDisputesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('disputes')
      .select('*, users(name)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Pending KYC documents
final adminKycProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('kyc_documents')
      .select('*, users(name, email)')
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// All wallets with user info
final adminWalletsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('wallets')
      .select('*, users(name, email)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Audit logs ordered by created_at desc
final adminAuditLogsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('audit_logs')
      .select()
      .order('created_at', ascending: false)
      .limit(100);
  return List<Map<String, dynamic>>.from(response);
});

/// All orders
final adminOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('orders')
      .select('*, users(name, email)')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// All products
final adminProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('products')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Platform settings
final adminPlatformSettingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('platform_settings')
      .select()
      .order('key');
  return List<Map<String, dynamic>>.from(response);
});

/// Admin actions state
class AdminActionsState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AdminActionsState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AdminActionsState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AdminActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Admin actions notifier for all admin CRUD operations
class AdminActionsNotifier extends StateNotifier<AdminActionsState> {
  final Ref ref;

  AdminActionsNotifier(this.ref) : super(const AdminActionsState());

  Future<bool> updateUserStatus(String userId, String status) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('users')
          .update({'account_status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
      await createAuditLog(
        actionType: 'update_user_status',
        targetId: userId,
        targetType: 'user',
        reason: 'Status changed to $status',
      );
      state = AdminActionsState(successMessage: 'User status updated to $status');
      ref.invalidate(adminUsersProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, String role) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('users')
          .update({'role': role, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
      await createAuditLog(
        actionType: 'update_user_role',
        targetId: userId,
        targetType: 'user',
        reason: 'Role changed to $role',
      );
      state = AdminActionsState(successMessage: 'User role updated to $role');
      ref.invalidate(adminUsersProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> updateCampaignStatus(String campaignId, String status) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('campaigns')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', campaignId);
      await createAuditLog(
        actionType: 'update_campaign_status',
        targetId: campaignId,
        targetType: 'campaign',
        reason: 'Status changed to $status',
      );
      state = AdminActionsState(successMessage: 'Campaign status updated to $status');
      ref.invalidate(adminCampaignsProvider);
      ref.invalidate(adminStatsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> approveSubmission(String submissionId) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('submissions')
          .update({'status': 'approved', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', submissionId);
      await createAuditLog(
        actionType: 'approve_submission',
        targetId: submissionId,
        targetType: 'submission',
        reason: 'Submission approved',
      );
      state = const AdminActionsState(successMessage: 'Submission approved');
      ref.invalidate(adminSubmissionsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> rejectSubmission(String submissionId, String notes) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('submissions')
          .update({
            'status': 'rejected',
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', submissionId);
      await createAuditLog(
        actionType: 'reject_submission',
        targetId: submissionId,
        targetType: 'submission',
        reason: notes,
      );
      state = const AdminActionsState(successMessage: 'Submission rejected');
      ref.invalidate(adminSubmissionsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> disburseSubmissionPayout(
    String submissionId,
    String creatorId,
    double amount,
  ) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('submissions')
          .update({
            'paid_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', submissionId);
      await creditWallet(creatorId, amount, reason: 'Payout for submission $submissionId');
      state = const AdminActionsState(successMessage: 'Payout disbursed');
      ref.invalidate(adminSubmissionsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> approveDeposit(String depositId, String userId, double amount) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('deposits')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', depositId);
      await creditWallet(userId, amount, reason: 'Deposit approved: $depositId');
      state = const AdminActionsState(successMessage: 'Deposit approved');
      ref.invalidate(adminDepositsProvider);
      ref.invalidate(adminStatsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> rejectDeposit(String depositId, String reason) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('deposits')
          .update({
            'status': 'rejected',
            'reject_reason': reason,
          })
          .eq('id', depositId);
      await createAuditLog(
        actionType: 'reject_deposit',
        targetId: depositId,
        targetType: 'deposit',
        reason: reason,
      );
      state = const AdminActionsState(successMessage: 'Deposit rejected');
      ref.invalidate(adminDepositsProvider);
      ref.invalidate(adminStatsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> approveWithdrawal(String withdrawalId, String userId, double amount) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('withdrawals')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', withdrawalId);
      await debitWallet(userId, amount, reason: 'Withdrawal completed: $withdrawalId');
      state = const AdminActionsState(successMessage: 'Withdrawal approved');
      ref.invalidate(adminWithdrawalsProvider);
      ref.invalidate(adminStatsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> rejectWithdrawal(String withdrawalId, String reason) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('withdrawals')
          .update({
            'status': 'rejected',
            'reject_reason': reason,
          })
          .eq('id', withdrawalId);
      await createAuditLog(
        actionType: 'reject_withdrawal',
        targetId: withdrawalId,
        targetType: 'withdrawal',
        reason: reason,
      );
      state = const AdminActionsState(successMessage: 'Withdrawal rejected');
      ref.invalidate(adminWithdrawalsProvider);
      ref.invalidate(adminStatsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> approveKyc(String kycId) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('kyc_documents')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', kycId);
      await createAuditLog(
        actionType: 'approve_kyc',
        targetId: kycId,
        targetType: 'kyc_document',
        reason: 'KYC approved',
      );
      state = const AdminActionsState(successMessage: 'KYC approved');
      ref.invalidate(adminKycProvider);
      ref.invalidate(adminStatsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> rejectKyc(String kycId, String notes) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('kyc_documents')
          .update({
            'status': 'rejected',
            'reject_reason': notes,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', kycId);
      await createAuditLog(
        actionType: 'reject_kyc',
        targetId: kycId,
        targetType: 'kyc_document',
        reason: notes,
      );
      state = const AdminActionsState(successMessage: 'KYC rejected');
      ref.invalidate(adminKycProvider);
      ref.invalidate(adminStatsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> creditWallet(String userId, double amount, {String reason = ''}) async {
    try {
      final wallet = await SupabaseService.client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (wallet != null) {
        final currentBalance = (wallet['available_balance'] as num?)?.toDouble() ?? 0;
        await SupabaseService.client
            .from('wallets')
            .update({
              'available_balance': currentBalance + amount,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        await SupabaseService.client.from('wallets').insert({
          'user_id': userId,
          'available_balance': amount,
          'escrow_balance': 0,
          'is_frozen': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await createAuditLog(
        actionType: 'credit_wallet',
        targetId: userId,
        targetType: 'wallet',
        reason: 'Credited $amount. $reason',
      );
      ref.invalidate(adminWalletsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> debitWallet(String userId, double amount, {String reason = ''}) async {
    try {
      final wallet = await SupabaseService.client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (wallet == null) {
        state = const AdminActionsState(error: 'Wallet not found');
        return false;
      }

      final currentBalance = (wallet['available_balance'] as num?)?.toDouble() ?? 0;
      if (currentBalance < amount) {
        state = const AdminActionsState(error: 'Insufficient balance');
        return false;
      }

      await SupabaseService.client
          .from('wallets')
          .update({
            'available_balance': currentBalance - amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      await createAuditLog(
        actionType: 'debit_wallet',
        targetId: userId,
        targetType: 'wallet',
        reason: 'Debited $amount. $reason',
      );
      ref.invalidate(adminWalletsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> freezeWallet(String userId, bool freeze) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('wallets')
          .update({
            'is_frozen': freeze,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      await createAuditLog(
        actionType: freeze ? 'freeze_wallet' : 'unfreeze_wallet',
        targetId: userId,
        targetType: 'wallet',
        reason: freeze ? 'Wallet frozen' : 'Wallet unfrozen',
      );
      state = AdminActionsState(
        successMessage: freeze ? 'Wallet frozen' : 'Wallet unfrozen',
      );
      ref.invalidate(adminWalletsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> updatePlatformSetting(String key, String value) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('platform_settings')
          .upsert({
            'key': key,
            'value': value,
            'updated_at': DateTime.now().toIso8601String(),
          });
      await createAuditLog(
        actionType: 'update_platform_setting',
        targetId: key,
        targetType: 'platform_setting',
        reason: 'Updated $key to $value',
      );
      state = const AdminActionsState(successMessage: 'Setting updated');
      ref.invalidate(adminPlatformSettingsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> sendBroadcast({
    required String title,
    required String body,
    required String audience,
  }) async {
    state = const AdminActionsState(isLoading: true);
    try {
      // Get target users
      var query = SupabaseService.client.from('users').select('id');
      if (audience == 'creators') {
        query = query.eq('role', 'creator');
      } else if (audience == 'brands') {
        query = query.eq('role', 'brand');
      }
      final users = await query;

      // Insert notifications for each user
      final notifications = (users as List).map((user) => {
        'user_id': user['id'],
        'title': title,
        'body': body,
        'type': 'broadcast',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();

      if (notifications.isNotEmpty) {
        await SupabaseService.client.from('notifications').insert(notifications);
      }

      await createAuditLog(
        actionType: 'send_broadcast',
        targetId: audience,
        targetType: 'broadcast',
        reason: 'Broadcast: $title to ${users.length} users',
      );
      state = AdminActionsState(
        successMessage: 'Broadcast sent to ${users.length} users',
      );
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> createAuditLog({
    required String actionType,
    required String targetId,
    required String targetType,
    String reason = '',
  }) async {
    try {
      final adminId = SupabaseService.currentUser?.id;
      if (adminId == null) return false;

      await SupabaseService.client.from('audit_logs').insert({
        'admin_id': adminId,
        'action_type': actionType,
        'target_id': targetId,
        'target_type': targetType,
        'reason': reason,
        'metadata': {},
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resolveDispute(String disputeId, String resolution) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('disputes')
          .update({
            'status': 'resolved',
            'resolution': resolution,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', disputeId);
      await createAuditLog(
        actionType: 'resolve_dispute',
        targetId: disputeId,
        targetType: 'dispute',
        reason: resolution,
      );
      state = const AdminActionsState(successMessage: 'Dispute resolved');
      ref.invalidate(adminDisputesProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    state = const AdminActionsState(isLoading: true);
    try {
      data['created_at'] = DateTime.now().toIso8601String();
      data['is_active'] = true;
      await SupabaseService.client.from('products').insert(data);
      await createAuditLog(
        actionType: 'create_product',
        targetId: data['title'] ?? '',
        targetType: 'product',
        reason: 'Product created',
      );
      state = const AdminActionsState(successMessage: 'Product created');
      ref.invalidate(adminProductsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct(String productId, Map<String, dynamic> data) async {
    state = const AdminActionsState(isLoading: true);
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      await SupabaseService.client.from('products').update(data).eq('id', productId);
      await createAuditLog(
        actionType: 'update_product',
        targetId: productId,
        targetType: 'product',
        reason: 'Product updated',
      );
      state = const AdminActionsState(successMessage: 'Product updated');
      ref.invalidate(adminProductsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client.from('products').delete().eq('id', productId);
      await createAuditLog(
        actionType: 'delete_product',
        targetId: productId,
        targetType: 'product',
        reason: 'Product deleted',
      );
      state = const AdminActionsState(successMessage: 'Product deleted');
      ref.invalidate(adminProductsProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    state = const AdminActionsState(isLoading: true);
    try {
      await SupabaseService.client
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      await createAuditLog(
        actionType: 'update_order_status',
        targetId: orderId,
        targetType: 'order',
        reason: 'Order status changed to $status',
      );
      state = AdminActionsState(successMessage: 'Order status updated to $status');
      ref.invalidate(adminOrdersProvider);
      return true;
    } catch (e) {
      state = AdminActionsState(error: e.toString());
      return false;
    }
  }
}

/// Admin actions provider
final adminActionsProvider =
    StateNotifierProvider<AdminActionsNotifier, AdminActionsState>((ref) {
  return AdminActionsNotifier(ref);
});
