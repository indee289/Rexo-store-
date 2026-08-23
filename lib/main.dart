import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/onesignal_service.dart';
import 'services/push_notification_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar to transparent - icon brightness adapts via theme's AppBarTheme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Initialize Firebase for push notifications
  // Wrapped in try-catch: app must work without Firebase
  bool firebaseAvailable = false;
  try {
    await Firebase.initializeApp();
    firebaseAvailable = true;
  } catch (_) {
    // Firebase may not be configured in all environments - skip silently
  }

  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: RexoApp(),
    ),
  );

  // Defer push notification setup until AFTER the first frame so it never
  // blocks initial render. Firebase is already initialized above; this only
  // wires up FCM listeners/permissions. Fire-and-forget + guarded so a failure
  // can never crash startup. FCM token still registers on login via
  // auth_provider's onUserLogin.
  if (firebaseAvailable) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await PushNotificationService.initialize();
      } catch (_) {
        // Push notifications may not be available in all environments - skip silently
      }
    });
  }

  // Initialize OneSignal (cross-platform push + in-app messaging) after the
  // first frame as well. It does not depend on Firebase — OneSignal manages its
  // own delivery credentials from the dashboard — so it runs regardless of
  // [firebaseAvailable]. Fire-and-forget + guarded so it can never crash
  // startup. The OneSignal external id is set on login via auth_provider.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await OneSignalService.initialize();
    } catch (_) {
      // OneSignal may not be available in all environments - skip silently
    }
  });
}
