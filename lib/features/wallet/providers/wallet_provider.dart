import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Realtime stream provider for the user's wallet data.
/// Subscribes to Supabase Realtime so admin actions (deposit approvals,
/// withdrawal completions) reflect immediately without app restart.
final walletProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = SupabaseService.currentUser;
  if (user == null) return Stream.value(null);

  return SupabaseService.client
      .from('wallets')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((List<Map<String, dynamic>> rows) {
        if (rows.isEmpty) return null;
        return rows.first;
      });
});

/// Provider for combined transaction history (deposits + withdrawals).
/// Kept as FutureProvider since transaction lists are less critical for
/// real-time updates and can be refreshed via invalidation.
final transactionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final deposits = await SupabaseService.client
      .from('deposits')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(50);

  final withdrawals = await SupabaseService.client
      .from('withdrawals')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(50);

  final List<Map<String, dynamic>> combined = [
    ...List<Map<String, dynamic>>.from(deposits).map((d) => {
          ...d,
          'type': 'deposit',
        }),
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

/// Wallet actions notifier for deposits and withdrawals
class WalletActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  WalletActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Submit a deposit request
  Future<bool> submitDeposit({
    required double amount,
    required String paymentMethod,
    required String transactionRef,
    String? proofUrl,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return false;
      }

      await SupabaseService.client.from('deposits').insert({
        'user_id': user.id,
        'amount': amount,
        'payment_method': paymentMethod,
        'transaction_ref': transactionRef,
        'proof_url': proofUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      state = const AsyncValue.data(null);

      // Refresh transaction list (realtime handles wallet balance)
      ref.invalidate(transactionsProvider);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

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
