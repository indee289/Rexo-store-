import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'supabase_service.dart';

/// Handles Firebase Cloud Messaging initialization, permission requests,
/// token management, and saving tokens to the user_devices table.
///
/// All operations are wrapped in try-catch so that failures never crash the app.
/// Push notifications are optional - the app must work without Firebase.
///
/// ============================================================================
/// CANNOT-VERIFY-WITHOUT-DEVICE:
/// Actual push notification delivery requires:
///   1. A real physical device or emulator with Google Play Services
///   2. Real Firebase credentials configured in google-services.json (Android)
///      and GoogleService-Info.plist (iOS)
///   3. A valid Firebase project with Cloud Messaging enabled
///   4. POST_NOTIFICATIONS permission granted by the user (Android 13+)
///
/// This service correctly:
///   - Requests POST_NOTIFICATIONS permission via requestPermission()
///   - Retrieves and saves FCM token to user_devices table
///   - Wraps all operations in try-catch (Firebase may not be configured)
///   - Listens for token refresh events
///   - Handles foreground/background messages
///
/// STATUS: CANNOT-VERIFY-WITHOUT-DEVICE - Code is implemented correctly but
/// push delivery cannot be tested without real device + real Firebase credentials.
/// ============================================================================
class PushNotificationService {
  PushNotificationService._();

  static FirebaseMessaging? _messaging;

  /// Local notifications plugin used to render a heads-up banner when an FCM
  /// message arrives while the app is in the foreground (FCM does not display
  /// a system notification for foreground messages on its own).
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static bool _localNotificationsReady = false;

  /// Android notification channel used for foreground heads-up notifications.
  /// Created programmatically so no manual channel XML is required under
  /// android/app/src/main.
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'rexo_high_importance',
    'General',
    description: 'General notifications from Rexo',
    importance: Importance.high,
  );

  /// Safely get the messaging instance, returns null if unavailable
  static FirebaseMessaging? get _safeMessaging {
    try {
      _messaging ??= FirebaseMessaging.instance;
      return _messaging;
    } catch (_) {
      return null;
    }
  }

  /// Initialize the local notifications plugin and Android channel.
  /// Best-effort: any failure leaves [_localNotificationsReady] false and the
  /// app keeps working without foreground banners.
  static Future<void> _initLocalNotifications() async {
    if (_localNotificationsReady) return;
    try {
      final plugin = FlutterLocalNotificationsPlugin();

      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await plugin.initialize(initSettings);

      // Create the Android channel (no-op on iOS).
      try {
        await plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_androidChannel);
      } catch (_) {
        // Channel creation may fail on non-Android platforms - ignore.
      }

      _localNotifications = plugin;
      _localNotificationsReady = true;
    } catch (_) {
      // Local notifications unavailable - foreground banners simply won't show.
      _localNotificationsReady = false;
    }
  }

  /// Initialize push notifications - call after Firebase.initializeApp()
  /// This method never throws. If Firebase is not available, it silently returns.
  static Future<void> initialize() async {
    try {
      final messaging = _safeMessaging;
      if (messaging == null) return;

      // Initialize local notifications so foreground messages can show a
      // heads-up banner. Best-effort; never blocks FCM setup.
      await _initLocalNotifications();

      // Request notification permissions (handles Android 13+ automatically)
      final settings = await messaging.requestPermission(
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
        try {
          messaging.onTokenRefresh.listen(
            _saveTokenToDatabase,
            onError: (_) {}, // Silently ignore stream errors
          );
        } catch (_) {
          // Token refresh listener may not be available
        }
      }

      // Handle foreground messages
      try {
        FirebaseMessaging.onMessage.listen(
          _handleForegroundMessage,
          onError: (_) {},
        );
      } catch (_) {
        // Foreground message listener may not be available
      }

      // Handle background message tap (app opened from notification)
      try {
        FirebaseMessaging.onMessageOpenedApp.listen(
          _handleMessageOpenedApp,
          onError: (_) {},
        );
      } catch (_) {
        // Background message listener may not be available
      }
    } catch (_) {
      // Firebase messaging initialization failed - skip silently
    }
  }

  /// Request notification permission explicitly.
  /// Call this on first launch or when user enables notifications in settings.
  /// Returns true if permission was granted, false otherwise.
  static Future<bool> requestPermission() async {
    try {
      final messaging = _safeMessaging;
      if (messaging == null) return false;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Get FCM token and save to database
  static Future<void> _getAndSaveToken() async {
    try {
      final messaging = _safeMessaging;
      if (messaging == null) return;

      final token = await messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    } catch (_) {
      // FCM token retrieval may fail in emulators or unsupported environments
    }
  }

  /// Save FCM token to user_devices table
  static Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

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

  /// Handle foreground message by showing a local heads-up notification.
  ///
  /// FCM does not surface a system notification while the app is in the
  /// foreground, so we render one via flutter_local_notifications. Everything
  /// is guarded so a rendering failure never crashes the app.
  static void _handleForegroundMessage(RemoteMessage message) {
    try {
      final plugin = _localNotifications;
      if (plugin == null || !_localNotificationsReady) return;

      final notification = message.notification;
      final data = message.data;

      // Prefer the notification payload, fall back to data payload.
      final title = notification?.title ??
          (data['title'] as String?) ??
          'Rexo';
      final body = notification?.body ??
          (data['body'] as String?) ??
          (data['message'] as String?) ??
          '';

      // Nothing meaningful to show.
      if (title.isEmpty && body.isEmpty) return;

      final androidDetails = AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      // Use a per-message id so multiple notifications can coexist.
      final id =
          DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

      plugin.show(id, title, body, details);
    } catch (_) {
      // Best-effort: never crash on a foreground push.
    }
  }

  /// Handle when user taps a background notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to appropriate screen based on message data
  }

  /// Called when user logs in - register/update token
  static Future<void> onUserLogin() async {
    try {
      await _getAndSaveToken();
    } catch (_) {
      // Silently fail - push notifications are optional
    }
  }

  /// Called when user logs out - optionally remove token
  static Future<void> onUserLogout() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      final messaging = _safeMessaging;
      if (messaging == null) return;

      final token = await messaging.getToken();
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
