import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Provider for user notifications list.
///
/// Uses a regular SELECT query instead of .stream() because the live
/// notifications table PK column name is unconfirmed and .stream()
/// throws when the primaryKey column doesn't exist.
///
/// LIVE SCHEMA COLUMNS:
///   userId (text) — ownership column
///   title, message, type, read (bool), link, createdAt
final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return <Map<String, dynamic>>[];

  try {
    final response = await SupabaseService.client
        .from('notifications')
        .select()
        .eq('userId', user.id)
        .order('createdAt', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(response);
  } catch (_) {
    return <Map<String, dynamic>>[];
  }
});

/// Unread count — derived from notifications list.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? const [];
  return notifications.where((n) => n['read'] == false).length;
});

/// Notification actions notifier
class NotificationActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  NotificationActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> markAsRead(String id) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'read': true}).eq('id', id);
      ref.invalidate(notificationsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;
      await SupabaseService.client
          .from('notifications')
          .update({'read': true})
          .eq('userId', user.id)
          .eq('read', false);
      ref.invalidate(notificationsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .delete()
          .eq('id', id);
      ref.invalidate(notificationsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationActionsProvider =
    StateNotifierProvider<NotificationActionsNotifier, AsyncValue<void>>((ref) {
  return NotificationActionsNotifier(ref);
});
