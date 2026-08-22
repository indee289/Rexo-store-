import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/push_notification_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar to transparent with dark icons
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Initialize Firebase for push notifications
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase may not be configured in all environments
  }

  await SupabaseService.initialize();

  // Initialize push notifications after Supabase is ready
  try {
    await PushNotificationService.initialize();
  } catch (_) {
    // Push notifications may not be available in all environments
  }

  runApp(
    const ProviderScope(
      child: RexoApp(),
    ),
  );
}
