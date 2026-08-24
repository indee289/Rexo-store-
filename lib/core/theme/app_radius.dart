import 'package:flutter/material.dart';

/// Corner-radius scale (Theme_System token set).
///
/// See design "Radius & elevation tokens".
abstract class AppRadius {
  AppRadius._();

  static const double sm = 8; // chips, badges
  static const double md = 12; // buttons, inputs
  static const double lg = 16; // cards
  static const double xl = 24; // bottom sheets
  static const double pill = 999; // fully rounded pills / avatars

  /// Pre-built `BorderRadius` helpers for the common sizes.
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Top-only radius (used by bottom sheets / the glass dock).
  static const BorderRadius topXl =
      BorderRadius.vertical(top: Radius.circular(xl));
}

/// Soft elevation shadows (Theme_System token set).
///
/// Provides a soft shadow in light mode and a lifted shadow in dark mode,
/// mirroring the existing `PremiumCard` treatment.
abstract class AppElevation {
  AppElevation._();

  /// Card shadow. Not `const` because it depends on `isDark` and uses
  /// `withOpacity`, matching the pattern already used in `AppTheme`.
  static List<BoxShadow> card(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.30 : 0.04),
          offset: const Offset(0, 2),
          blurRadius: 8,
        ),
      ];

  /// Slightly stronger shadow for floating/raised surfaces (e.g. the dock,
  /// sticky CTAs, sheets).
  static List<BoxShadow> raised(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.40 : 0.08),
          offset: const Offset(0, 6),
          blurRadius: 20,
        ),
      ];
}
