import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Provider for user notifications list
final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final response = await SupabaseService.client
      .from('notifications')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Unread notifications count
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final notifications = await ref.watch(notificationsProvider.future);
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
