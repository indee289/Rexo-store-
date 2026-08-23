import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Centralized wrapper around ALL OneSignal SDK interactions.
///
/// Per the OneSignal integration guidance, no OneSignal SDK call should live
/// outside this class — initialization, user identity (login/logout), email /
/// SMS subscriptions, tags, logging, permission, and the push-subscription
/// observer all route through here. This keeps SDK usage isolated and makes
/// future SDK upgrades and testing easier.
///
/// OneSignal is a cross-platform push + in-app messaging service. On Android it
/// delivers via FCM (credentials configured in the OneSignal dashboard, NOT via
/// the app's google-services.json); on iOS via APNs. It coexists with the
/// legacy FCM [PushNotificationService].
///
/// All operations are wrapped in try-catch so a failure can never crash the
/// app — push is an optional enhancement, not a hard dependency.
///
/// ============================================================================
/// CANNOT-VERIFY-WITHOUT-DEVICE:
/// Actual OneSignal push delivery / device registration requires:
///   1. A real physical device or emulator with Google Play Services (Android)
///      or a real iOS device / Apple-Silicon simulator (APNs).
///   2. The OneSignal App ID configured (see [_appId]) and matching platform
///      credentials set in the OneSignal dashboard (FCM v1 key / APNs auth key).
///   3. Network connectivity so the device can register and receive a
///      server-assigned push subscription id.
///
/// STATUS: CANNOT-VERIFY-WITHOUT-DEVICE — code follows the OneSignal Flutter
/// 5.x API but registration/delivery cannot be tested inside this sandbox.
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

  /// Strong references to registered push-subscription observers. OneSignal may
  /// store observers weakly, so we retain them here for the app's lifetime.
  static final List<void Function(String?)> _retainedObservers = [];

  /// Initialize OneSignal. Safe to call once after the first frame.
  /// Never throws — any failure leaves the SDK inactive and the app running.
  ///
  /// NOTE: This intentionally does NOT request notification permission. Per the
  /// integration guidance, permission is requested only from the verification
  /// dialog's "Got it" action (see onesignal_verification.dart), never at
  /// launch.
  static Future<void> initialize() async {
    if (_initialized) return;
    if (_appId.isEmpty) return;

    try {
      // Verbose logging only in debug builds; silent in release.
      OneSignal.Debug.setLogLevel(
        kReleaseMode ? OSLogLevel.none : OSLogLevel.verbose,
      );

      OneSignal.initialize(_appId);
      _initialized = true;
    } catch (_) {
      // OneSignal unavailable (e.g. no Play Services / misconfigured) — skip.
      _initialized = false;
    }
  }

  // ---------------------------------------------------------------------------
  // User identity
  // ---------------------------------------------------------------------------

  /// Associate the current OneSignal subscription with an app user so pushes
  /// can be targeted by external id. Call on login / session restore.
  static Future<void> onUserLogin(String userId) async {
    if (userId.isEmpty) return;
    try {
      if (!_initialized) await initialize();
      OneSignal.login(userId);
    } catch (_) {
      // Non-critical — targeting by external id simply won't be available.
    }
  }

  /// Disassociate the user from this device's OneSignal subscription.
  /// Call on logout so the next user isn't targeted with the previous id.
  static Future<void> onUserLogout() async {
    try {
      if (!_initialized) return;
      OneSignal.logout();
    } catch (_) {
      // Non-critical.
    }
  }

  // ---------------------------------------------------------------------------
  // Email / SMS subscriptions & tags
  // ---------------------------------------------------------------------------

  static void addEmail(String email) {
    try {
      OneSignal.User.addEmail(email);
    } catch (_) {}
  }

  static void removeEmail(String email) {
    try {
      OneSignal.User.removeEmail(email);
    } catch (_) {}
  }

  static void addSms(String number) {
    try {
      OneSignal.User.addSms(number);
    } catch (_) {}
  }

  static void removeSms(String number) {
    try {
      OneSignal.User.removeSms(number);
    } catch (_) {}
  }

  static void addTag(String key, String value) {
    try {
      OneSignal.User.addTagWithKey(key, value);
    } catch (_) {}
  }

  static void removeTag(String key) {
    try {
      OneSignal.User.removeTag(key);
    } catch (_) {}
  }

  static void setLogLevel(OSLogLevel level) {
    try {
      OneSignal.Debug.setLogLevel(level);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Permission & push subscription (used by the verification dialog)
  // ---------------------------------------------------------------------------

  /// Request notification permission. This is the ONLY place permission is
  /// requested (from the verification dialog's "Got it" action).
  /// Returns true if permission is granted.
  static Future<bool> requestPermission() async {
    try {
      if (!_initialized) await initialize();
      return await OneSignal.Notifications.requestPermission(true);
    } catch (_) {
      return false;
    }
  }

  /// The current push subscription id, or null if unavailable. A real,
  /// server-assigned id is non-empty and NOT prefixed with `local-`.
  static String? get pushSubscriptionId {
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (_) {
      return null;
    }
  }

  /// Register a push-subscription observer. The callback receives the current
  /// subscription id whenever it changes. The observer is retained for the
  /// app's lifetime.
  static void addPushSubscriptionObserver(void Function(String? id) onChange) {
    try {
      if (!_initialized) return;
      _retainedObservers.add(onChange);
      OneSignal.User.pushSubscription.addObserver((state) {
        onChange(state.current.id);
      });
    } catch (_) {
      // Non-critical — verification dialog simply won't trigger.
    }
  }
}
