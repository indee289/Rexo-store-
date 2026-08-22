import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'supabase_service.dart';

/// Handles Firebase Cloud Messaging initialization, permission requests,
/// token management, and saving tokens to the user_devices table.
class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize push notifications - call after Firebase.initializeApp()
  static Future<void> initialize() async {
    // Request notification permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token and save it
      await _getAndSaveToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Get FCM token and save to database
  static Future<void> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    } catch (_) {
      // FCM token retrieval may fail in emulators or unsupported environments
    }
  }

  /// Save FCM token to user_devices table
  static Future<void> _saveTokenToDatabase(String token) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      // Check if a device with this token already exists
      final existing = await SupabaseService.client
          .from('user_devices')
          .select('id')
          .eq('user_id', user.id)
          .eq('fcm_token', token)
          .maybeSingle();

      if (existing == null) {
        // Insert new device entry
        await SupabaseService.client.from('user_devices').insert({
          'user_id': user.id,
          'device_name': Platform.isAndroid ? 'Android' : 'iOS',
          'device_type': Platform.isAndroid ? 'android' : 'ios',
          'fcm_token': token,
          'app_version': '1.0.0',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {
      // Silently fail - non-critical operation
    }
  }

  /// Handle foreground message
  static void _handleForegroundMessage(RemoteMessage message) {
    // Messages received while app is in foreground
    // Could show a local notification or in-app banner
  }

  /// Handle when user taps a background notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to appropriate screen based on message data
  }

  /// Called when user logs in - register/update token
  static Future<void> onUserLogin() async {
    await _getAndSaveToken();
  }

  /// Called when user logs out - optionally remove token
  static Future<void> onUserLogout() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await SupabaseService.client
            .from('user_devices')
            .delete()
            .eq('user_id', user.id)
            .eq('fcm_token', token);
      }
    } catch (_) {
      // Silently fail
    }
  }
}
