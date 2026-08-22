import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Provider that fetches a single creator profile by user_id
final creatorProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, creatorUserId) async {
  final response = await SupabaseService.client
      .from('creator_profiles')
      .select('*, users!inner(id, name, avatar_url, handle, email)')
      .eq('user_id', creatorUserId)
      .maybeSingle();

  return response;
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
