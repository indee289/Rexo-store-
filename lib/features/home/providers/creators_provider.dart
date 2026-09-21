import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import '../models/creator_view.dart';

/// Live `users` columns needed to render a creator profile and drive the
/// follow toggle. The tables `creator_profiles` and `follows` do NOT exist in
/// the live Supabase DB, so every creator lookup and follow relationship is
/// resolved from the `users` table instead.
const _creatorColumns =
    'id, uid, name, profileImage, username, isVerified, bio, '
    'followersCount, followingCount, followers, following';

/// Coerces a Supabase jsonb array of user-id strings into a `List<String>`.
///
/// Returns an empty list for null / non-list input so callers never throw on a
/// missing or malformed `followers` / `following` column.
List<String> _idList(dynamic value) {
  if (value is List) {
    return value
        .where((e) => e != null)
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return <String>[];
}

/// Provider that fetches a single creator's raw `users` row by `uid`.
///
/// Retained for backward compatibility with existing consumers; prefer
/// [creatorViewProvider] for the normalized [CreatorView]. Reads only from the
/// live `users` table (the `creator_profiles` table does not exist) and
/// degrades to `null` on any failure so a missing row or query error never
/// crashes the caller.
final creatorProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, creatorUserId) async {
  try {
    return await SupabaseService.client
        .from('users')
        .select(_creatorColumns)
        .eq('uid', creatorUserId)
        .maybeSingle();
  } catch (_) {
    return null;
  }
});

/// Resiliently resolves a creator by `uid` into a normalized [CreatorView].
///
/// Reads from the live `users` table only (the `creator_profiles` table does
/// not exist in production). Returns `null` when no matching `users` row exists
/// or when the query fails — the profile screen then shows a "creator
/// unavailable" empty state rather than surfacing a raw backend error.
Future<CreatorView?> resolveCreator(String creatorUserId) async {
  if (creatorUserId.isEmpty) return null;

  try {
    final userRow = await SupabaseService.client
        .from('users')
        .select(_creatorColumns)
        .eq('uid', creatorUserId)
        .maybeSingle();

    if (userRow != null) {
      return CreatorView.fromUserRow(userRow);
    }
  } catch (_) {
    // Missing table / RLS / network — degrade gracefully.
    return null;
  }

  // Genuinely unknown user.
  return null;
}

/// Provider that resolves a normalized [CreatorView] for a creator `uid`.
///
/// Returns `null` when no `users` row exists (or the lookup fails), in which
/// case the creator profile screen shows a "creator unavailable" empty state.
final creatorViewProvider =
    FutureProvider.family<CreatorView?, String>((ref, creatorUserId) async {
  return resolveCreator(creatorUserId);
});

/// Provider that checks whether the current user follows a given creator.
///
/// Follow relationships live in the target user's `users.followers` jsonb
/// array (a list of follower user-id strings). `isFollowing` is true when that
/// array contains the current user's id. Any failure degrades to `false`.
final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, creatorUserId) async {
  final user = SupabaseService.currentUser;
  if (user == null) return false;

  try {
    final row = await SupabaseService.client
        .from('users')
        .select('followers')
        .eq('uid', creatorUserId)
        .maybeSingle();

    if (row == null) return false;
    return _idList(row['followers']).contains(user.id);
  } catch (_) {
    return false;
  }
});

/// Provider for the follower count of a creator.
///
/// Reads the live `users.followersCount` column, falling back to the length of
/// the `followers` jsonb array when the count column is absent. Degrades to `0`
/// on any failure.
final followerCountProvider =
    FutureProvider.family<int, String>((ref, creatorUserId) async {
  try {
    final row = await SupabaseService.client
        .from('users')
        .select('followersCount, followers')
        .eq('uid', creatorUserId)
        .maybeSingle();

    if (row == null) return 0;
    final count = (row['followersCount'] as num?)?.toInt();
    if (count != null) return count;
    return _idList(row['followers']).length;
  } catch (_) {
    return 0;
  }
});

/// Notifier for follow/unfollow actions.
///
/// Because the `follows` table does not exist, follow relationships are modeled
/// via the `users.followers` / `users.following` jsonb arrays with set
/// semantics:
///   - The target user's `followers` array gains/loses the current user's id.
///   - The current user's `following` array gains/loses the target user's id.
///
/// RLS on `users` allows a user to update only their own row
/// (`uid = auth.uid()::text`), so the write to the current user's `following`
/// row is the one that reliably succeeds; the write to the target's `followers`
/// row is attempted but tolerated to fail. All writes are wrapped so a failure
/// degrades gracefully — a raw PostgrestException / RLS error never reaches the
/// UI. The counts are kept consistent with the arrays on rows we can write.
class FollowActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  FollowActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Follow a creator. Returns `true` on success, `false` on failure.
  Future<bool> follow(String creatorUserId) async {
    // Re-entry guard: prevent duplicate work from rapid taps.
    if (state.isLoading) return false;

    final user = SupabaseService.currentUser;
    if (user == null) return false;

    try {
      state = const AsyncValue.loading();

      await _applyFollowChange(
        currentUserId: user.id,
        targetUserId: creatorUserId,
        following: true,
      );

      ref.invalidate(isFollowingProvider(creatorUserId));
      ref.invalidate(followerCountProvider(creatorUserId));

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Unfollow a creator. Returns `true` on success, `false` on failure.
  Future<bool> unfollow(String creatorUserId) async {
    // Re-entry guard: prevent duplicate work from rapid taps.
    if (state.isLoading) return false;

    final user = SupabaseService.currentUser;
    if (user == null) return false;

    try {
      state = const AsyncValue.loading();

      await _applyFollowChange(
        currentUserId: user.id,
        targetUserId: creatorUserId,
        following: false,
      );

      ref.invalidate(isFollowingProvider(creatorUserId));
      ref.invalidate(followerCountProvider(creatorUserId));

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Applies a follow/unfollow change across both user rows using set
  /// semantics on the jsonb arrays, keeping the count columns consistent.
  ///
  /// The current user's own row (`following`) is the authoritative write under
  /// RLS. The target user's row (`followers`) is attempted separately; if RLS
  /// blocks it, that failure is swallowed so the toggle still succeeds locally
  /// rather than crashing.
  Future<void> _applyFollowChange({
    required String currentUserId,
    required String targetUserId,
    required bool following,
  }) async {
    final client = SupabaseService.client;

    // 1) Update the current user's `following` array + count (own row → RLS ok).
    final selfRow = await client
        .from('users')
        .select('following, followingCount')
        .eq('uid', currentUserId)
        .maybeSingle();

    final followingSet = _idList(selfRow?['following']).toSet();
    final wasFollowing = followingSet.contains(targetUserId);
    if (following) {
      followingSet.add(targetUserId);
    } else {
      followingSet.remove(targetUserId);
    }

    // Only write when the set actually changed (idempotent set semantics).
    if (following != wasFollowing) {
      await client.from('users').update({
        'following': followingSet.toList(),
        'followingCount': followingSet.length,
      }).eq('uid', currentUserId);
    }

    // 2) Best-effort update of the target user's `followers` array + count.
    // RLS may block writing another user's row; tolerate that gracefully.
    try {
      final targetRow = await client
          .from('users')
          .select('followers, followersCount')
          .eq('uid', targetUserId)
          .maybeSingle();

      final followersSet = _idList(targetRow?['followers']).toSet();
      final wasFollower = followersSet.contains(currentUserId);
      if (following) {
        followersSet.add(currentUserId);
      } else {
        followersSet.remove(currentUserId);
      }

      if (following != wasFollower) {
        await client.from('users').update({
          'followers': followersSet.toList(),
          'followersCount': followersSet.length,
        }).eq('uid', targetUserId);
      }
    } catch (_) {
      // Target row not writable under RLS — leave it; the current user's
      // following state is already recorded. No error reaches the UI.
    }
  }
}

/// Provider for follow actions
final followActionsProvider =
    StateNotifierProvider<FollowActionsNotifier, AsyncValue<void>>((ref) {
  return FollowActionsNotifier(ref);
});
