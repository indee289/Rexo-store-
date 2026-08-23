import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
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

  // Initialize push notifications after Supabase is ready
  // Only attempt if Firebase initialized successfully
  if (firebaseAvailable) {
    try {
      await PushNotificationService.initialize();
    } catch (_) {
      // Push notifications may not be available in all environments - skip silently
    }
  }

  runApp(
    const ProviderScope(
      child: RexoApp(),
    ),
  );
}
