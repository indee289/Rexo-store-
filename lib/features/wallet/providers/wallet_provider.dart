import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/admin_notify.dart';
import '../../../services/supabase_service.dart';

/// Realtime stream provider for the user's wallet data.
/// Subscribes to Supabase Realtime so admin actions (deposit approvals,
/// withdrawal completions) reflect immediately without app restart.
///
/// Also injects a computed `total_earnings` key by summing
/// `payout_per_creator` from approved applications where the current
/// user is the creator — the `wallets` table has no such column.
final walletProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = SupabaseService.currentUser;
  if (user == null) return Stream.value(null);

  return SupabaseService.client
      .from('wallets')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .asyncMap((List<Map<String, dynamic>> rows) async {
        if (rows.isEmpty) return null;
        final walletMap = Map<String, dynamic>.from(rows.first);

        // Compute total earnings from approved applications.
        try {
          final earningsResponse = await SupabaseService.client
              .from('applications')
              .select('payout_per_creator')
              .eq('creatorId', user.id)
              .eq('status', 'approved');
          final totalEarnings =
              List<Map<String, dynamic>>.from(earningsResponse)
                  .fold<double>(
                      0.0,
                      (sum, row) =>
                          sum +
                          ((row['payout_per_creator'] as num?)
                                  ?.toDouble() ??
                              0.0));
          walletMap['total_earnings'] = totalEarnings;
        } catch (_) {
          walletMap['total_earnings'] = 0.0;
        }

        return walletMap;
      });
});

/// Provider for withdrawal transaction history.
/// Deposits were removed from the app; only withdrawals are shown.
final transactionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final withdrawals = await SupabaseService.client
      .from('withdrawals')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(50);

  final List<Map<String, dynamic>> combined = [
    ...List<Map<String, dynamic>>.from(withdrawals).map((w) => {
          ...w,
          'type': 'withdrawal',
        }),
  ];

  combined.sort((a, b) {
    final aDate =
        DateTime.tryParse((a['created_at'] ?? '').toString()) ?? DateTime(1970);
    final bDate =
        DateTime.tryParse((b['created_at'] ?? '').toString()) ?? DateTime(1970);
    return bDate.compareTo(aDate);
  });

  return combined;
});

/// Wallet actions notifier for withdrawals.
class WalletActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  WalletActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Submit a withdrawal request
  Future<bool> submitWithdrawal({
    required double amount,
    required String method,
    required Map<String, dynamic> payoutDetails,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return false;
      }

      await SupabaseService.client.from('withdrawals').insert({
        'user_id': user.id,
        'amount': amount,
        'method': method,
        'payout_details': payoutDetails,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      state = const AsyncValue.data(null);

      await AdminNotify.admins(
        title: 'New withdrawal request',
        message: 'A user requested a withdrawal of ₹${amount.toStringAsFixed(2)} '
            'via $method. Open Admin → Actions → Withdrawal Queue.',
        type: 'withdrawal',
      );

      // Refresh transaction list (realtime handles wallet balance)
      ref.invalidate(transactionsProvider);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Wallet actions provider
final walletActionsProvider =
    StateNotifierProvider<WalletActionsNotifier, AsyncValue<void>>((ref) {
  return WalletActionsNotifier(ref);
});
