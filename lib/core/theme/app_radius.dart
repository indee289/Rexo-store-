import 'package:flutter/material.dart';

/// Instagram-inspired corner radius scale.
///
/// Instagram uses very tight, minimal radii: small chips are pills, buttons
/// are 6-8px, cards are unrounded (feed) or 8px (highlights). Story rings
/// and avatars are full circles.
abstract class AppRadius {
  AppRadius._();

  static const double sm = 6;   // chips, small tags, badges (IG uses ~4-6)
  static const double md = 8;   // IG buttons, inputs, action pills
  static const double lg = 12;  // IG cards, small containers
  static const double xl = 16;  // IG bottom sheets, larger surfaces
  static const double pill = 999; // fully rounded pills / avatars

  /// Pre-built `BorderRadius` helpers.
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Top-only radius for bottom sheets / modals.
  static const BorderRadius topXl =
      BorderRadius.vertical(top: Radius.circular(xl));
}

/// Instagram-inspired elevation.
///
/// Instagram uses **almost no shadows** — depth comes from hairline
/// borders and the flat white surface. These tokens return empty lists so
/// existing call-sites keep compiling but produce zero visual shadow.
abstract class AppElevation {
  AppElevation._();

  /// Card shadow — none. Instagram cards use just a hairline border.
  static List<BoxShadow> card(bool isDark) => const [];

  /// Raised — a barely-there lift for sticky bars.
  static List<BoxShadow> raised(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          offset: const Offset(0, -0.5),
          blurRadius: 0,
        ),
      ];
}
