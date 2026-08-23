import 'package:flutter/material.dart';

import '../core/router/app_router.dart';
import 'onesignal_service.dart';

/// One-time OneSignal "integration complete" verification dialog.
///
/// Registers a push-subscription observer and, once the device receives a real
/// server-assigned subscription id, shows a dialog exactly once whose action
/// requests notification permission. This is the ONLY place OneSignal push
/// permission is requested (never at launch), per the integration guidance.

/// Guard so the dialog is shown at most once per app session.
bool _dialogShown = false;

/// A real, server-assigned subscription id is non-empty and NOT the transient
/// `local-` placeholder the SDK assigns before the device registers.
bool _isRegistered(String? id) =>
    id != null && id.isNotEmpty && !id.startsWith('local-');

/// Wire up the verification dialog. Registers an observer AND evaluates the
/// current id immediately, because the id may already be server-assigned before
/// the observer attaches (reacting only to change events could miss it).
void setupOneSignalVerification() {
  OneSignalService.addPushSubscriptionObserver(_maybeShowIntegrationDialog);
  _maybeShowIntegrationDialog(OneSignalService.pushSubscriptionId);
}

void _maybeShowIntegrationDialog(String? subscriptionId) {
  if (_dialogShown || !_isRegistered(subscriptionId)) return;

  // The observer can fire from a non-widget context; use the root navigator so
  // the dialog appears over whatever route is currently visible. If the
  // navigator isn't ready yet, leave the guard unset so a later change event
  // retries.
  final context = rootNavigatorKey.currentContext;
  if (context == null) return;

  _dialogShown = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Your OneSignal SDK integration is complete!'),
      content: const Text(
        'You can now send Push Notifications & In-App Messages through '
        'OneSignal. Tap below to enable push notifications.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            // The one and only push-permission request.
            OneSignalService.requestPermission();
          },
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
