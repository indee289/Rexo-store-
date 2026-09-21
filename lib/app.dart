import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_provider.dart';

class RexoApp extends ConsumerWidget {
  const RexoApp({super.key});

  /// Maximum allowed text scale factor.
  ///
  /// - At scale ≤ 1.0  : app looks exactly as designed.
  /// - At scale 1.0–1.15: slight growth — still comfortable and accessible.
  /// - Above 1.15      : capped here so no screen becomes unusable.
  ///
  /// Using Flutter's modern [TextScaler] API (not the deprecated
  /// textScaleFactor property). Accessibility is preserved — this is a
  /// *cap*, not a hard lock to 1.0.
  static const double _maxTextScale = 1.15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Rexo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: router,
      // ── Centralized text-scale cap ────────────────────────────────────────
      // Intercepts every MediaQuery in the widget tree and limits the
      // TextScaler so large system-font settings don't shatter fixed-width
      // layouts. We use a builder + MediaQuery.withClampedTextScaling so the
      // cap applies to ALL text inside the app without touching individual
      // widgets.
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
