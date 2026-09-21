import 'package:flutter/material.dart';

/// Corner-radius scale (Theme_System token set).
///
/// Tuned for the modern minimal look: generous, soft rounding on cards,
/// buttons, inputs and sheets.
abstract class AppRadius {
  AppRadius._();

  static const double sm = 10; // chips, badges, small tiles
  static const double md = 14; // buttons, inputs
  static const double lg = 20; // cards
  static const double xl = 28; // bottom sheets, large surfaces
  static const double pill = 999; // fully rounded pills / avatars

  /// Pre-built `BorderRadius` helpers for the common sizes.
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Top-only radius (used by bottom sheets / the floating dock).
  static const BorderRadius topXl =
      BorderRadius.vertical(top: Radius.circular(xl));
}

/// Soft elevation shadows (Theme_System token set).
///
/// Diffuse, low-opacity shadows give floating cards a gentle lift in light
/// mode and a subtle depth in dark mode.
abstract class AppElevation {
  AppElevation._();

  /// Card shadow — soft and diffuse.
  static List<BoxShadow> card(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.28 : 0.05),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: -2,
        ),
      ];

  /// Slightly stronger shadow for floating/raised surfaces (dock, sticky CTAs,
  /// sheets, dialogs).
  static List<BoxShadow> raised(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.45 : 0.10),
          offset: const Offset(0, 10),
          blurRadius: 30,
          spreadRadius: -4,
        ),
      ];
}
