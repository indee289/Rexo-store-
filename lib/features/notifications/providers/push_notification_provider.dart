import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Push notification state
class PushNotificationState {
  final String? fcmToken;
  final bool isRegistering;
  final String? error;
  final Map<String, dynamic>? lastNotification;

  const PushNotificationState({
    this.fcmToken,
    this.isRegistering = false,
    this.error,
    this.lastNotification,
  });

  PushNotificationState copyWith({
    String? fcmToken,
    bool? isRegistering,
    String? error,
    Map<String, dynamic>? lastNotification,
  }) {
    return PushNotificationState(
      fcmToken: fcmToken ?? this.fcmToken,
      isRegistering: isRegistering ?? this.isRegistering,
      error: error,
      lastNotification: lastNotification ?? this.lastNotification,
    );
  }
}

/// Push notification notifier (structural placeholder for FCM)
class PushNotificationNotifier extends StateNotifier<PushNotificationState> {
  PushNotificationNotifier() : super(const PushNotificationState());

  /// Register FCM token - saves to user_devices table
  Future<void> registerToken(String token) async {
    state = state.copyWith(isRegistering: true, error: null);

    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isRegistering: false, error: 'Not authenticated');
        return;
      }

      // Update the FCM token in user_devices table for this user
      // Try to update existing device record first, or insert new one
      final existingDevices = await SupabaseService.client
          .from('user_devices')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      if (existingDevices.isNotEmpty) {
        await SupabaseService.client
            .from('user_devices')
            .update({'fcm_token': token})
            .eq('id', existingDevices[0]['id']);
      }

      state = state.copyWith(
        fcmToken: token,
        isRegistering: false,
      );
    } catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: 'Failed to register push token',
      );
    }
  }

  /// Handle incoming notification payload
  void handleNotification(Map<String, dynamic> data) {
    state = state.copyWith(lastNotification: data);

    // Process notification based on type
    final type = data['type'] as String?;
    switch (type) {
      case 'campaign_update':
      case 'order_status':
      case 'message':
      case 'warning':
        // Store notification for display
        _storeNotification(data);
        break;
      default:
        break;
    }
  }

  /// Store notification in the notifications table.
  ///
  /// Live schema columns (confirmed Stage C):
  ///   "userId"    text  — ownership column
  ///   message     text  — body content (NOT 'body')
  ///   read        bool  — read state   (NOT 'is_read')
  ///   "createdAt" timestamptz          (NOT 'created_at')
  Future<void> _storeNotification(Map<String, dynamic> data) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      await SupabaseService.client.from('notifications').insert({
        'userId': userId,
        'title': data['title'] ?? 'Notification',
        'message': data['body'] ?? data['message'] ?? '',
        'type': data['type'] ?? 'general',
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Silently fail — notification storage is non-critical
    }
  }
}

/// Provider for push notification notifier
final pushNotificationProvider =
    StateNotifierProvider<PushNotificationNotifier, PushNotificationState>((ref) {
  return PushNotificationNotifier();
});
