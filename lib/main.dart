import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/onesignal_service.dart';
import 'services/onesignal_verification.dart';
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

  // SECURITY: Detect a fresh install and clear any auth session that survived
  // an uninstall (e.g. via Android cloud backup). Without this, a reinstalled
  // app could auto-login as the previous user — including the admin account.
  //
  // We store a flag in SharedPreferences. SharedPreferences is wiped on a true
  // uninstall, so if the flag is missing but a Supabase session exists, the
  // session was restored from backup and must be invalidated.
  try {
    final prefs = await SharedPreferences.getInstance();
    const installedFlag = 'rexo_installed_flag_v1';
    final hasFlag = prefs.getBool(installedFlag) ?? false;
    if (!hasFlag) {
      // Fresh install (or first launch after this fix). If a session was
      // restored from backup, sign it out so the user must log in explicitly.
      if (SupabaseService.isAuthenticated) {
        await SupabaseService.signOut();
      }
      await prefs.setBool(installedFlag, true);
    }
  } catch (_) {
    // Never block startup on this guard.
  }

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
      // Wire up the push-subscription verification dialog. It shows once the
      // device registers and requests push permission on the user's tap — the
      // only place OneSignal permission is requested (never at launch).
      setupOneSignalVerification();
    } catch (_) {
      // OneSignal may not be available in all environments - skip silently
    }
  });
}
