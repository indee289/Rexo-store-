import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Fetches the set of user ids that are in a block relationship with the
/// current user — i.e. everyone the current user has blocked AND everyone who
/// has blocked the current user. Used to two-way hide these users across
/// messages, search and discovery.
///
/// RLS on `user_blocks` allows selecting rows where the current user is either
/// the blocker or the blocked party, so this single query is safe.
Future<Set<String>> fetchBlockRelationIds() async {
  final user = SupabaseService.currentUser;
  if (user == null) return <String>{};
  try {
    final rows = await SupabaseService.client
        .from('user_blocks')
        .select('blocker_id, blocked_id')
        .or('blocker_id.eq.${user.id},blocked_id.eq.${user.id}');

    final ids = <String>{};
    for (final row in List<Map<String, dynamic>>.from(rows)) {
      final blocker = (row['blocker_id'] ?? '').toString();
      final blocked = (row['blocked_id'] ?? '').toString();
      // Add whichever side is NOT the current user.
      if (blocker == user.id && blocked.isNotEmpty) ids.add(blocked);
      if (blocked == user.id && blocker.isNotEmpty) ids.add(blocker);
    }
    return ids;
  } catch (_) {
    return <String>{};
  }
}

/// Returns true when there is a block in EITHER direction between the current
/// user and [otherUserId] (used to gate messaging/following).
Future<bool> isBlockRelation(String otherUserId) async {
  final user = SupabaseService.currentUser;
  if (user == null || otherUserId.isEmpty) return false;
  try {
    final rows = await SupabaseService.client
        .from('user_blocks')
        .select('id')
        .or(
          'and(blocker_id.eq.${user.id},blocked_id.eq.$otherUserId),'
          'and(blocker_id.eq.$otherUserId,blocked_id.eq.${user.id})',
        )
        .limit(1);
    return List<Map<String, dynamic>>.from(rows).isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// The set of ids in a block relationship with the current user.
final blockRelationIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  return fetchBlockRelationIds();
});

/// Whether the current user has blocked [targetUserId] specifically
/// (one-directional — drives the Block/Unblock toggle label).
final iBlockedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, targetUserId) async {
  final user = SupabaseService.currentUser;
  if (user == null || targetUserId.isEmpty) return false;
  try {
    final rows = await SupabaseService.client
        .from('user_blocks')
        .select('id')
        .eq('blocker_id', user.id)
        .eq('blocked_id', targetUserId)
        .limit(1);
    return List<Map<String, dynamic>>.from(rows).isNotEmpty;
  } catch (_) {
    return false;
  }
});

/// Block / unblock actions.
class BlockActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  BlockActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Block [targetUserId]. Returns true on success. Prevents self-block.
  Future<bool> block(String targetUserId) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;
    if (targetUserId.isEmpty || targetUserId == user.id) return false;

    try {
      state = const AsyncValue.loading();
      // upsert-style: ignore duplicate (unique pair) errors gracefully.
      await SupabaseService.client.from('user_blocks').insert({
        'blocker_id': user.id,
        'blocked_id': targetUserId,
      });
      _invalidate(targetUserId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      // A duplicate insert (already blocked) is effectively success.
      if (e.toString().toLowerCase().contains('duplicate') ||
          e.toString().contains('user_blocks_unique_pair')) {
        _invalidate(targetUserId);
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Unblock [targetUserId]. Returns true on success.
  Future<bool> unblock(String targetUserId) async {
    final user = SupabaseService.currentUser;
    if (user == null || targetUserId.isEmpty) return false;
    try {
      state = const AsyncValue.loading();
      await SupabaseService.client
          .from('user_blocks')
          .delete()
          .eq('blocker_id', user.id)
          .eq('blocked_id', targetUserId);
      _invalidate(targetUserId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _invalidate(String targetUserId) {
    ref.invalidate(iBlockedProvider(targetUserId));
    ref.invalidate(blockRelationIdsProvider);
  }
}

final blockActionsProvider =
    StateNotifierProvider<BlockActionsNotifier, AsyncValue<void>>(
  (ref) => BlockActionsNotifier(ref),
);

/// The users the current user has blocked, with public profile fields, for the
/// Blocked Accounts management screen.
final myBlockedUsersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];
  try {
    final blocks = await SupabaseService.client
        .from('user_blocks')
        .select('blocked_id, created_at')
        .eq('blocker_id', user.id)
        .order('created_at', ascending: false);

    final blockedIds = List<Map<String, dynamic>>.from(blocks)
        .map((r) => (r['blocked_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
    if (blockedIds.isEmpty) return [];

    // Resolve public profiles (users.uid == the stored id value).
    final users = await SupabaseService.client
        .from('users')
        .select('uid, name, username, profileImage')
        .inFilter('uid', blockedIds);

    final byId = <String, Map<String, dynamic>>{};
    for (final u in List<Map<String, dynamic>>.from(users)) {
      byId[(u['uid'] ?? '').toString()] = u;
    }

    // Preserve block order; include a fallback row when a profile is missing.
    return blockedIds
        .map((id) => byId[id] ?? {'uid': id, 'name': 'User'})
        .toList();
  } catch (_) {
    return [];
  }
});
