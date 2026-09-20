import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import '../models/creator_view.dart';

/// Provider that fetches a single creator profile by user_id.
///
/// Returns the raw `creator_profiles` row (joined with the `users` row) or
/// `null` when no creator-profile row exists. Retained for backward
/// compatibility with existing consumers; prefer [creatorViewProvider] for the
/// resilient, normalized [CreatorView] that also falls back to the `users` row.
final creatorProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, creatorUserId) async {
  final response = await SupabaseService.client
      .from('creator_profiles')
      .select('*, users!inner(id, name, profileImage, username, email, isVerified)') // live columns
      .eq('user_id', creatorUserId)
      .maybeSingle();

  return response;
});

/// Resiliently resolves a creator by `user_id` into a normalized [CreatorView].
///
/// Resolution order (see design "Algorithmic Pseudocode > Resilient creator
/// resolution"):
///   1. Query `creator_profiles` (joined with `users`) by `user_id`. If a row
///      exists, return [CreatorView.fromCreatorProfileRow].
///   2. Otherwise query `users` by `id`. If a row exists, return
///      [CreatorView.fromUserRow] (with empty category/bio-default, zero
///      rating, zero completed campaigns).
///   3. Otherwise return `null` — the user id is genuinely unknown.
///
/// This fixes the "creator not found" bug where a creator exists only as a
/// `users` row (the Top Creators fallback path) with no `creator_profiles` row.
Future<CreatorView?> resolveCreator(String creatorUserId) async {
  assert(creatorUserId.isNotEmpty, 'creatorUserId must be non-empty');

  // Primary: creator_profiles joined with users.
  final profileRow = await SupabaseService.client
      .from('creator_profiles')
      .select(
          '*, users!inner(id, name, profileImage, username, isVerified, bio)') // live columns
      .eq('user_id', creatorUserId)
      .maybeSingle();

  if (profileRow != null) {
    return CreatorView.fromCreatorProfileRow(profileRow);
  }

  // Fallback: plain users row (fixes "creator not found").
  // Live identity column is `uid` (text). The callers pass the auth UUID
  // as a string, matching the `uid` column value. `id` uuid also exists
  // but the live RLS filters on uid — .eq('uid', ...) is the safe approach.
  final userRow = await SupabaseService.client
      .from('users')
      .select('id, uid, name, profileImage, username, isVerified, bio') // live columns
      .eq('uid', creatorUserId)
      .maybeSingle();

  if (userRow != null) {
    return CreatorView.fromUserRow(userRow);
  }

  // Genuinely unknown user.
  return null;
}

/// Provider that resolves a normalized [CreatorView] for a creator `user_id`,
/// falling back to the `users` row when no `creator_profiles` row exists.
///
/// Returns `null` only when no `users` row exists for the id, in which case the
/// creator profile screen shows a "creator unavailable" empty state.
final creatorViewProvider =
    FutureProvider.family<CreatorView?, String>((ref, creatorUserId) async {
  return resolveCreator(creatorUserId);
});

/// Provider that checks if the current user follows a given creator
final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, creatorUserId) async {
  final user = SupabaseService.currentUser;
  if (user == null) return false;

  final response = await SupabaseService.client
      .from('follows')
      .select('id')
      .eq('follower_id', user.id)
      .eq('following_id', creatorUserId)
      .maybeSingle();

  return response != null;
});

/// Provider for the follower count of a creator
final followerCountProvider =
    FutureProvider.family<int, String>((ref, creatorUserId) async {
  final response = await SupabaseService.client
      .from('follows')
      .select('id')
      .eq('following_id', creatorUserId);

  return (response as List).length;
});

/// Notifier for follow/unfollow actions
class FollowActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  FollowActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Follow a creator
  Future<bool> follow(String creatorUserId) async {
    // Re-entry guard: prevent duplicate inserts from rapid taps
    if (state.isLoading) return false;

    try {
      state = const AsyncValue.loading();
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = const AsyncValue.data(null);
        return false;
      }

      await SupabaseService.client.from('follows').insert({
        'follower_id': user.id,
        'following_id': creatorUserId,
      });

      // Invalidate related providers to refresh UI
      ref.invalidate(isFollowingProvider(creatorUserId));
      ref.invalidate(followerCountProvider(creatorUserId));

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Unfollow a creator
  Future<bool> unfollow(String creatorUserId) async {
    // Re-entry guard: prevent duplicate calls from rapid taps
    if (state.isLoading) return false;

    try {
      state = const AsyncValue.loading();
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = const AsyncValue.data(null);
        return false;
      }

      await SupabaseService.client
          .from('follows')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', creatorUserId);

      // Invalidate related providers to refresh UI
      ref.invalidate(isFollowingProvider(creatorUserId));
      ref.invalidate(followerCountProvider(creatorUserId));

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for follow actions
final followActionsProvider =
    StateNotifierProvider<FollowActionsNotifier, AsyncValue<void>>((ref) {
  return FollowActionsNotifier(ref);
});
