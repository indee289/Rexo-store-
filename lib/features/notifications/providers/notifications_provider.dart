import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Provider for user notifications list.
///
/// Uses Supabase realtime so the NotificationsScreen updates live when the
/// admin broadcast Edge Function inserts new `notifications` rows. The stream
/// is ordered newest-first and filtered to the current user.
///
/// NEEDS-USER-ACTION: Realtime must be enabled for the `notifications` table
/// in the Supabase dashboard (Database -> Replication / Realtime) for live
/// updates to arrive. Without it the initial snapshot still loads.
final notificationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = SupabaseService.currentUser;
  if (user == null) {
    return Stream.value(<Map<String, dynamic>>[]);
  }

  return SupabaseService.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .map((rows) => List<Map<String, dynamic>>.from(rows));
});

/// Unread notifications count derived from the realtime notifications stream.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? const [];
  return notifications.where((n) => n['is_read'] == false).length;
});

/// Notification actions notifier
class NotificationActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  NotificationActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Mark a single notification as read
  Future<void> markAsRead(String id) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true}).eq('id', id);

      ref.invalidate(notificationsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      ref.invalidate(notificationsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a notification
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

/// Notification actions provider
final notificationActionsProvider =
    StateNotifierProvider<NotificationActionsNotifier, AsyncValue<void>>((ref) {
  return NotificationActionsNotifier(ref);
});
