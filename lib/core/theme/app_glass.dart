import 'package:flutter/material.dart';

/// Glassmorphism / translucency tokens (Theme_System token set).
///
/// Modern, premium, iOS-style aesthetic: clean, glassy, translucent surfaces.
/// These tokens define the semi-transparent surface tints and blur sigmas that
/// downstream components consume:
///   * the bottom navigation bar / dock renders a transparent, blurred surface,
///   * glass buttons (`PremiumButton` translucent style) render a soft frosted
///     fill,
///   * premium sheets / overlays can share the same frosted treatment.
///
/// Pair these with a `BackdropFilter(filter: ui.ImageFilter.blur(...))` and a
/// `ClipRRect` using [AppRadius] to produce the frosted-glass effect.
abstract class AppGlass {
  AppGlass._();

  /// Standard backdrop blur sigma for the dock, sheets, and large surfaces.
  static const double blurSigma = 20;

  /// Lighter blur for subtle glass (buttons, chips, small overlays).
  static const double blurSigmaSubtle = 12;

  /// Opacity applied to translucent glass surfaces.
  static const double surfaceOpacity = 0.60;
  static const double dockOpacityLight = 0.70;
  static const double dockOpacityDark = 0.55;
  static const double buttonOpacityLight = 0.55;
  static const double buttonOpacityDark = 0.10;
  static const double borderOpacityLight = 0.50;
  static const double borderOpacityDark = 0.12;

  /// Base tints the translucent surfaces are derived from.
  static const Color _lightBase = Colors.white;
  static const Color _darkBase = Color(0xFF1E1E1E);

  /// Translucent surface tint for frosted panels/sheets.
  static Color surface(bool isDark) => (isDark ? _darkBase : _lightBase)
      .withOpacity(surfaceOpacity);

  /// Translucent background for the bottom navigation bar / dock.
  static Color dock(bool isDark) => (isDark ? _darkBase : _lightBase)
      .withOpacity(isDark ? dockOpacityDark : dockOpacityLight);

  /// Translucent fill for glass-style (transparent) buttons.
  static Color button(bool isDark) => (isDark ? Colors.white : _lightBase)
      .withOpacity(isDark ? buttonOpacityDark : buttonOpacityLight);

  /// Hairline border that reads as a light rim on glass surfaces.
  static Color border(bool isDark) => Colors.white
      .withOpacity(isDark ? borderOpacityDark : borderOpacityLight);
}
