import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Handles OneSignal SDK initialization, permission requests, and user
/// identity (external id) management.
///
/// OneSignal is a cross-platform push + in-app messaging service. On Android it
/// delivers via FCM (configured in the OneSignal dashboard, NOT via the app's
/// google-services.json); on iOS via APNs. This service is safe to run on both
/// platforms and coexists with the existing FCM [PushNotificationService].
///
/// All operations are wrapped in try-catch so a failure can never crash the
/// app — push is an optional enhancement, not a hard dependency.
///
/// ============================================================================
/// CANNOT-VERIFY-WITHOUT-DEVICE:
/// Actual OneSignal push delivery requires:
///   1. A real physical device or emulator with Google Play Services (Android)
///      or a real iOS device (APNs does not work on the iOS simulator).
///   2. The OneSignal App ID configured (see [_appId]) and the matching
///      platform credentials set in the OneSignal dashboard:
///        - Android: a Google Service Account / FCM v1 key
///        - iOS: an APNs auth key + a Notification Service Extension
///   3. Notification permission granted by the user.
///
/// This service correctly:
///   - Initializes the SDK with the App ID
///   - Requests notification permission
///   - Associates the OneSignal subscription with the Supabase user id via
///     OneSignal.login()/logout() so the backend can target specific users
///
/// STATUS: CANNOT-VERIFY-WITHOUT-DEVICE — code is implemented per the OneSignal
/// Flutter 5.x API but delivery cannot be tested inside this sandbox.
/// ============================================================================
class OneSignalService {
  OneSignalService._();

  /// OneSignal App ID. This is a PUBLIC client identifier (not a secret), so a
  /// working default is baked in for convenience, and it can still be
  /// overridden at build time via `--dart-define=ONESIGNAL_APP_ID=...`.
  static const String _appId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: 'cf5dccaf-cd4e-4fbc-ae21-009a5d2a1d7b',
  );

  static bool _initialized = false;

  /// Initialize OneSignal. Safe to call once after the first frame.
  /// Never throws — any failure leaves the SDK inactive and the app running.
  static Future<void> initialize() async {
    if (_initialized) return;
    if (_appId.isEmpty) return;

    try {
      // Verbose logging only in debug builds; silent in release.
      OneSignal.Debug.setLogLevel(
        kReleaseMode ? OSLogLevel.none : OSLogLevel.verbose,
      );

      OneSignal.initialize(_appId);

      // Ask for notification permission. `fallbackToSettings: true` routes the
      // user to system settings if they previously denied. Best-effort.
      try {
        await OneSignal.Notifications.requestPermission(true);
      } catch (_) {
        // Permission prompt may be unavailable in some environments.
      }

      _initialized = true;
    } catch (_) {
      // OneSignal unavailable (e.g. no Play Services / misconfigured) — skip.
      _initialized = false;
    }
  }

  /// Associate the current OneSignal subscription with an app user so pushes
  /// can be targeted by external id. Call on login / session restore.
  static Future<void> onUserLogin(String userId) async {
    if (userId.isEmpty) return;
    try {
      if (!_initialized) await initialize();
      await OneSignal.login(userId);
    } catch (_) {
      // Non-critical — targeting by external id simply won't be available.
    }
  }

  /// Disassociate the user from this device's OneSignal subscription.
  /// Call on logout so the next user isn't targeted with the previous id.
  static Future<void> onUserLogout() async {
    try {
      if (!_initialized) return;
      await OneSignal.logout();
    } catch (_) {
      // Non-critical.
    }
  }

  /// Explicitly (re)request notification permission — e.g. from a settings
  /// toggle. Returns true if permission is granted.
  static Future<bool> requestPermission() async {
    try {
      if (!_initialized) await initialize();
      return await OneSignal.Notifications.requestPermission(true);
    } catch (_) {
      return false;
    }
  }
}
