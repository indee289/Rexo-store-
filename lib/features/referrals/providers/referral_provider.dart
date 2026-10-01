import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import '../../profile/providers/profile_provider.dart';

/// A user's referral code is their username (unique on the live users table).
final myReferralCodeProvider = FutureProvider<String?>((ref) async {
  final profileState = await ref.watch(currentUserProfileProvider.future);
  final username = profileState.profile?['username']?.toString();
  if (username != null && username.isNotEmpty) return username;
  return null;
});

/// Referral stats for the current user: how many people they referred and the
/// total reward points on their account.
class ReferralStats {
  final int referredCount;
  final int rewardPoints;
  const ReferralStats({this.referredCount = 0, this.rewardPoints = 0});
}

final referralStatsProvider = FutureProvider<ReferralStats>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return const ReferralStats();

  int count = 0;
  int points = 0;
  try {
    final rows = await SupabaseService.client
        .from('referrals')
        .select('id')
        .eq('referrer_uid', user.id);
    count = List<Map<String, dynamic>>.from(rows).length;
  } catch (_) {/* table may not exist yet */}

  try {
    final rp = await SupabaseService.client
        .from('reward_points')
        .select('points')
        .eq('user_id', user.id)
        .maybeSingle();
    points = (rp?['points'] as num?)?.toInt() ?? 0;
  } catch (_) {/* ignore */}

  return ReferralStats(referredCount: count, rewardPoints: points);
});

/// Whether the current user has already redeemed a referral code.
final hasRedeemedReferralProvider = FutureProvider<bool>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return true;
  try {
    final row = await SupabaseService.client
        .from('referrals')
        .select('id')
        .eq('referred_uid', user.id)
        .maybeSingle();
    return row != null;
  } catch (_) {
    return false;
  }
});

class RedeemResult {
  final bool ok;
  final String message;
  const RedeemResult(this.ok, this.message);
}

/// Redeems a friend's referral code via the secure RPC.
class ReferralActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  ReferralActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<RedeemResult> redeem(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return const RedeemResult(false, 'Enter a referral code.');
    }
    try {
      state = const AsyncValue.loading();
      await SupabaseService.client
          .rpc('redeem_referral', params: {'p_code': trimmed});
      ref.invalidate(referralStatsProvider);
      ref.invalidate(hasRedeemedReferralProvider);
      state = const AsyncValue.data(null);
      return const RedeemResult(true, 'Referral applied! Reward points added.');
    } catch (e) {
      state = const AsyncValue.data(null);
      return RedeemResult(false, _friendlyError(e.toString()));
    }
  }

  String _friendlyError(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('already_referred')) return 'You already used a referral code.';
    if (r.contains('self_referral')) return "You can't use your own code.";
    if (r.contains('invalid_code')) return 'That referral code was not found.';
    if (r.contains('empty_code')) return 'Enter a referral code.';
    if (r.contains('not_authenticated')) return 'Please sign in first.';
    return 'Could not apply referral. Try again.';
  }
}

final referralActionsProvider =
    StateNotifierProvider<ReferralActionsNotifier, AsyncValue<void>>((ref) {
  return ReferralActionsNotifier(ref);
});
