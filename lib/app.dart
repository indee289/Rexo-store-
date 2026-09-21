import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class RexoApp extends ConsumerWidget {
  const RexoApp({super.key});

  /// Maximum allowed text scale factor.
  ///
  /// - At scale ≤ 1.0  : app looks exactly as designed.
  /// - At scale 1.0–1.15: slight growth — still comfortable and accessible.
  /// - Above 1.15      : capped here so no screen becomes unusable.
  static const double _maxTextScale = 1.15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Rexo',
      debugShowCheckedModeBanner: false,
      // ── Light-only theme by product decision ──────────────────────────────
      // The user-facing "Appearance" picker in settings still reads/writes
      // ThemeMode via [settingsProvider] for backward compatibility, but the
      // app itself always renders in the iOS-inspired light theme.
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme, // Alias — no dark mode
      themeMode: ThemeMode.light,
      routerConfig: router,
      // ── Centralized text-scale cap ────────────────────────────────────────
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedTextScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: _maxTextScale,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedTextScaler),
          child: child!,
        );
      },
    );
  }
}
