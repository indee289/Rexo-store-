import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'services/onesignal_service.dart';
import 'services/onesignal_verification.dart';
import 'services/push_notification_service.dart';
import 'services/supabase_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Any uncaught asynchronous Dart error is reported (visible in logcat as a
  // Flutter error) instead of being allowed to terminate the isolate silently.
  // This alone prevents the "closes on the splash screen" behavior for errors
  // that escape a Future.
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'Campster startup',
    ));
    return true;
  };

  // Show a Flutter frame IMMEDIATELY. Previously the app awaited
  // Supabase.initialize() before runApp(); if that threw (bad config, storage
  // plugin error, offline session recovery, etc.) the process died while only
  // the native launch splash was visible — exactly the reported crash. Now the
  // bootstrap runs inside a widget, so a failure shows a retryable error
  // screen instead of closing the app.
  runApp(const _CampsterBootstrap());
}

/// Owns core startup (Supabase) and renders one of three states: a loading
/// splash, a recoverable error screen, or the real app once ready.
class _CampsterBootstrap extends StatefulWidget {
  const _CampsterBootstrap();

  @override
  State<_CampsterBootstrap> createState() => _CampsterBootstrapState();
}

class _CampsterBootstrapState extends State<_CampsterBootstrap> {
  late Future<void> _coreFuture;
  bool _optionalServicesStarted = false;

  @override
  void initState() {
    super.initState();
    _coreFuture = _initializeCore();
  }

  Future<void> _initializeCore() async {
    // Only Supabase is required before the app can render; a 20s ceiling keeps
    // a hung network/plugin call from leaving the user on an endless splash.
    await SupabaseService.initialize().timeout(const Duration(seconds: 20));
    await _clearSessionOnFreshInstall();
  }

  /// A fresh install must not inherit an old account session restored from an
  /// Android cloud backup. Never allowed to block or fail startup.
  Future<void> _clearSessionOnFreshInstall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const installedFlag = 'rexo_installed_flag_v1';
      final hasFlag = prefs.getBool(installedFlag) ?? false;
      if (!hasFlag) {
        if (SupabaseService.isAuthenticated) {
          await SupabaseService.signOut().timeout(const Duration(seconds: 8));
        }
        await prefs.setBool(installedFlag, true);
      }
    } catch (error, stack) {
      debugPrint('[Startup] Fresh-install guard skipped: $error\n$stack');
    }
  }

  void _retry() {
    setState(() {
      _coreFuture = _initializeCore();
    });
  }

  /// Firebase / FCM / OneSignal are optional. They run AFTER the first frame
  /// and can never block the UI or crash the app if their native/config
  /// integration is unavailable on a device.
  void _startOptionalServices() {
    if (_optionalServicesStarted) return;
    _optionalServicesStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeOptionalServices());
    });
  }

  Future<void> _initializeOptionalServices() async {
    try {
      await Firebase.initializeApp();
      try {
        await PushNotificationService.initialize();
      } catch (error, stack) {
        debugPrint('[Startup] FCM init skipped: $error\n$stack');
      }
    } catch (error, stack) {
      debugPrint('[Startup] Firebase init skipped: $error\n$stack');
    }

    try {
      await OneSignalService.initialize();
      setupOneSignalVerification();
    } catch (error, stack) {
      debugPrint('[Startup] OneSignal init skipped: $error\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _coreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootstrapShell(child: _StartupLoading());
        }
        if (snapshot.hasError) {
          return _BootstrapShell(
            child: _StartupError(error: snapshot.error!, onRetry: _retry),
          );
        }
        // Core ready — hand off to the real app and start optional services.
        _startOptionalServices();
        return const ProviderScope(child: RexoApp());
      },
    );
  }
}

/// Minimal MaterialApp used only for the pre-app loading/error states so they
/// have Directionality, theme and text styling without touching the real app.
class _BootstrapShell extends StatelessWidget {
  final Widget child;

  const _BootstrapShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0095F6),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF0EDE5),
      ),
      home: child,
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image(
                  image: AssetImage('assets/logo.png'),
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(height: 14),
                  Text('Starting Campster…'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _StartupError({required this.error, required this.onRetry});

  /// A short, non-sensitive code the user can report so the exact failing
  /// subsystem is identifiable without a device log.
  String get _code {
    final text = error.toString().toLowerCase();
    if (error is TimeoutException || text.contains('timeout')) {
      return 'C-START-TIMEOUT';
    }
    if (text.contains('shared_preferences') ||
        text.contains('missingplugin') ||
        text.contains('platformexception')) {
      return 'C-START-STORAGE';
    }
    if (text.contains('configuration') ||
        text.contains('url') ||
        text.contains('anon key')) {
      return 'C-START-CONFIG';
    }
    return 'C-START-SERVICE';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.error_outline_rounded, size: 64),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Campster couldn't start",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please check your internet connection and try again. If the '
                    'problem continues, send the code below to support.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    _code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SelectableText(
                    AppConstants.supportEmail,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
