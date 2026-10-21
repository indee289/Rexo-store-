import 'onesignal_service.dart';

/// One-time push-permission request after the device registers with OneSignal.
///
/// Previously this showed a OneSignal-branded "integration complete" dialog to
/// end users, which is a developer verification artifact and must never be
/// shown in production. That dialog has been removed. Now, once the device has
/// a real server-assigned subscription id, we request notification permission
/// exactly once (the standard OS prompt) — no custom branded banner.

/// Guard so permission is requested at most once per app session.
bool _permissionRequested = false;

/// A real, server-assigned subscription id is non-empty and NOT the transient
/// `local-` placeholder the SDK assigns before the device registers.
bool _isRegistered(String? id) =>
    id != null && id.isNotEmpty && !id.startsWith('local-');

/// Wire up the one-time permission request. Registers an observer AND evaluates
/// the current id immediately, because the id may already be server-assigned
/// before the observer attaches.
void setupOneSignalVerification() {
  OneSignalService.addPushSubscriptionObserver(_maybeRequestPermission);
  _maybeRequestPermission(OneSignalService.pushSubscriptionId);
}

void _maybeRequestPermission(String? subscriptionId) {
  if (_permissionRequested || !_isRegistered(subscriptionId)) return;
  _permissionRequested = true;
  // Standard OS notification-permission prompt. No custom UI/banner.
  OneSignalService.requestPermission();
}
