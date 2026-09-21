import 'package:flutter/material.dart';

/// iOS-inspired corner radius scale.
///
/// Follows Apple's continuous corner geometry — soft, refined rounding
/// consistent with iOS 16+ system components.
abstract class AppRadius {
  AppRadius._();

  static const double sm = 8;   // chips, small tags, badges
  static const double md = 12;  // iOS buttons, inputs, alerts
  static const double lg = 16;  // iOS cards, sheets on smaller surfaces
  static const double xl = 20;  // iOS bottom sheets, modals, large surfaces
  static const double pill = 999; // fully rounded pills / avatars

  /// Pre-built `BorderRadius` helpers.
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Top-only radius — iOS bottom sheets, modals.
  static const BorderRadius topXl =
      BorderRadius.vertical(top: Radius.circular(xl));
}

/// iOS-inspired elevation.
///
/// iOS uses very restrained shadows — most depth comes from hairline borders
/// and subtle vertical offset, not blur. These tokens deliver that feel.
abstract class AppElevation {
  AppElevation._();

  /// Card shadow — barely-there, iOS-style lift.
  static List<BoxShadow> card(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          offset: const Offset(0, 1),
          blurRadius: 4,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];

  /// Raised surface — sticky CTAs, floating dock, sheets.
  static List<BoxShadow> raised(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          offset: const Offset(0, 12),
          blurRadius: 32,
          spreadRadius: -6,
        ),
      ];
}
