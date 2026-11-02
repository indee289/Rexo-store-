import 'package:flutter/material.dart';

/// Corner radius scale — **Liquid Glass**.
///
/// Glass panes need generous, continuous-looking corners: the blur reads as
/// thick material only when the corner is large. The scale below is the glass
/// ramp; every token name from the previous (tight, 6-16px) scale is preserved
/// so existing call-sites compile and automatically pick up the new geometry.
abstract class AppRadius {
  AppRadius._();

  static const double xs = 10;  // tiny badges, dots, inline tags
  static const double sm = 14;  // chips, small pills, stat tiles
  static const double md = 20;  // inputs, compact buttons, list rows
  static const double lg = 26;  // cards, standard glass panes
  static const double xl = 32;  // sheets, dialogs, large surfaces
  static const double xxl = 40; // hero panes, full-bleed glass headers
  static const double pill = 999; // fully rounded pills / avatars

  /// Pre-built `BorderRadius` helpers.
  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Top-only radius for bottom sheets / modals.
  static const BorderRadius topXl =
      BorderRadius.vertical(top: Radius.circular(xl));

  /// Top-only radius for full-height glass sheets.
  static const BorderRadius topXxl =
      BorderRadius.vertical(top: Radius.circular(xxl));

  /// Bottom-only radius for glass app bars that float under the status bar.
  static const BorderRadius bottomXl =
      BorderRadius.vertical(bottom: Radius.circular(xl));
}

/// Elevation — **Liquid Glass**.
///
/// Glass depth comes from three stacked cues: a wide ambient shadow that
/// separates the pane from the backdrop, a tight contact shadow, and the
/// specular rim drawn by the glass widgets themselves. Shadows stay soft and
/// low-alpha so panes never look like opaque Material cards.
///
/// The `isDark` parameter is retained for call-site compatibility; the app is
/// light-only so both branches return the same values.
abstract class AppElevation {
  AppElevation._();

  /// Resting glass pane (cards, tiles).
  static List<BoxShadow> card(bool isDark) => const [
        BoxShadow(
          color: Color(0x14000000), // 8% ink — ambient
          blurRadius: 24,
          offset: Offset(0, 10),
          spreadRadius: -6,
        ),
        BoxShadow(
          color: Color(0x0A000000), // 4% ink — contact
          blurRadius: 6,
          offset: Offset(0, 2),
          spreadRadius: -2,
        ),
      ];

  /// Floating glass (nav bar, FAB, sticky action bars).
  static List<BoxShadow> raised(bool isDark) => const [
        BoxShadow(
          color: Color(0x1F000000), // 12% ink
          blurRadius: 36,
          offset: Offset(0, 14),
          spreadRadius: -8,
        ),
        BoxShadow(
          color: Color(0x0F000000), // 6% ink
          blurRadius: 10,
          offset: Offset(0, 3),
          spreadRadius: -3,
        ),
      ];

  /// Modal glass (sheets, dialogs) — the heaviest lift.
  static List<BoxShadow> modal(bool isDark) => const [
        BoxShadow(
          color: Color(0x2E000000), // 18% ink
          blurRadius: 48,
          offset: Offset(0, 18),
          spreadRadius: -10,
        ),
      ];

  /// Brand-tinted glow under filled red buttons.
  static List<BoxShadow> brand(bool isDark) => const [
        BoxShadow(
          color: Color(0x4D8B1A1A), // brand red @ 30%
          blurRadius: 22,
          offset: Offset(0, 8),
          spreadRadius: -6,
        ),
      ];

  /// No shadow — for panes that sit flush inside another glass pane.
  static List<BoxShadow> none(bool isDark) => const [];
}
