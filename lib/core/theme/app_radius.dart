import 'package:flutter/material.dart';

/// Corner radius scale — **Campster premium**.
///
/// Tighter than the previous glass ramp (10/14/20/26/32/40). Very large radii
/// read as "soft" and work for thick translucent material, but on opaque cards
/// they waste corner space and make dense content look like it is bulging. This
/// scale is the one used by most premium product UIs: moderate on cards,
/// generous on sheets, pills for anything interactive and short.
///
/// Every token name from the earlier scales is preserved, so existing
/// call-sites compile and pick up the new geometry automatically.
abstract class AppRadius {
  AppRadius._();

  static const double xs = 8; // badges, tiny tags, skeleton bars
  static const double sm = 12; // icon bubbles, chips, small tiles
  static const double md = 14; // inputs, list rows, compact buttons
  static const double lg = 18; // cards, grouped sections
  static const double xl = 24; // dialogs, large cards
  static const double xxl = 28; // sheets, hero panels
  static const double pill = 999; // pills, avatars, nav dock

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Top-only radius for bottom sheets.
  static const BorderRadius topXl =
      BorderRadius.vertical(top: Radius.circular(xl));
  static const BorderRadius topXxl =
      BorderRadius.vertical(top: Radius.circular(xxl));

  /// Bottom-only radius, for bars anchored under the status bar.
  static const BorderRadius bottomXl =
      BorderRadius.vertical(bottom: Radius.circular(xl));
}

/// Elevation — **soft layered shadows**.
///
/// Depth is the whole job now that surfaces are opaque. Each level is two
/// shadows: a tight contact shadow that grounds the edge, and a wide ambient
/// shadow that gives the lift. Alphas stay very low (3-10%); a single dark
/// shadow is the fastest way to make a light UI look heavy and dated.
///
/// The `isDark` parameter is retained for call-site compatibility; the app is
/// light-only so both branches return the same values.
abstract class AppElevation {
  AppElevation._();

  /// Resting surface — cards, grouped sections, tiles.
  static List<BoxShadow> card(bool isDark) => const [
        BoxShadow(
          color: Color(0x0A000000), // 4% — contact
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x0F000000), // 6% — ambient
          blurRadius: 14,
          offset: Offset(0, 4),
          spreadRadius: -4,
        ),
      ];

  /// Floating surface — nav dock, FAB, sticky action bars.
  static List<BoxShadow> raised(bool isDark) => const [
        BoxShadow(
          color: Color(0x0F000000), // 6%
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: Color(0x1A000000), // 10%
          blurRadius: 28,
          offset: Offset(0, 10),
          spreadRadius: -8,
        ),
      ];

  /// Modal surface — sheets and dialogs.
  static List<BoxShadow> modal(bool isDark) => const [
        BoxShadow(
          color: Color(0x1F000000), // 12%
          blurRadius: 48,
          offset: Offset(0, 20),
          spreadRadius: -12,
        ),
      ];

  /// Brand-tinted lift under a filled red button.
  static List<BoxShadow> brand(bool isDark) => const [
        BoxShadow(
          color: Color(0x338B1A1A), // brand red @ 20%
          blurRadius: 16,
          offset: Offset(0, 6),
          spreadRadius: -6,
        ),
      ];

  /// No shadow — for a surface nested inside another surface.
  static List<BoxShadow> none(bool isDark) => const [];
}
