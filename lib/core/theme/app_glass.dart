import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Surface material tokens — the single source of truth for how a panel looks.
///
/// ### What changed, and why
/// This file used to describe a frosted-glass material: blur sigmas,
/// translucent tint opacities, a specular sheen and a rim light. All of that is
/// gone. A `BackdropFilter` forces a save-layer plus a blur pass for every pane
/// that uses one, and with cards in a scrolling list that was by far the most
/// expensive thing the UI did per frame.
///
/// A panel is now three cheap layers:
///   1. an **opaque fill**,
///   2. a **hairline border** at very low alpha,
///   3. a **layered shadow** from [AppElevation].
///
/// On a light canvas that looks all but identical to the frosted version while
/// painting in a single pass.
///
/// Use the `AppSurface` widget rather than assembling these by hand.
///
/// The `isDark` parameters are retained for call-site compatibility; the app is
/// light-only, so both branches resolve identically.
abstract class AppGlass {
  AppGlass._();

  /// Hairline border width. A true hairline — anything heavier reads as a
  /// wireframe rather than a card edge.
  static const double borderWidth = 1.0;

  // ── Fills ────────────────────────────────────────────────────────────────

  /// Primary elevated surface — sheets, bars, section panels.
  static Color surface(bool isDark) => AppColors.surface;

  /// Card surface.
  static Color card(bool isDark) => AppColors.card;

  /// Recessed fill — inputs, chips, tracks, skeletons.
  static Color recessed(bool isDark) => AppColors.surfaceAlt;

  /// Floating navigation dock.
  static Color dock(bool isDark) => AppColors.surface;

  /// Secondary button fill.
  static Color button(bool isDark) => AppColors.surfaceAlt;

  /// Brand-tinted fill — selected chips, active rows, icon bubbles.
  static Color brandTint(bool isDark) => AppColors.primaryBg;

  /// Translucent white, for a panel laid over photography where the image
  /// should still read through.
  static Color tintOverImage(bool isDark) => Colors.white.withOpacity(0.88);

  /// Translucent white over a brand-red fill.
  static Color tintOverBrand(bool isDark) => Colors.white.withOpacity(0.16);

  // ── Edges ────────────────────────────────────────────────────────────────

  /// Standard hairline border.
  static Color border(bool isDark) => AppColors.border;

  /// Slightly stronger edge, for a panel that must separate from a same-tone
  /// neighbour.
  static Color borderContrast(bool isDark) => AppColors.separator;

  /// Brand edge — focused inputs, selected cards.
  static Color borderBrand(bool isDark) => AppColors.primaryRim;

  /// Scrim behind modals.
  static Color scrim(bool isDark) => Colors.black.withOpacity(0.32);

  // ── Decoration helper ────────────────────────────────────────────────────

  /// A complete surface decoration for a panel of the given [radius].
  static BoxDecoration decoration({
    required BorderRadius radius,
    Color? fill,
    Color? borderColor,
    List<BoxShadow>? shadow,
    Gradient? gradient,
    bool bordered = true,
  }) {
    return BoxDecoration(
      color: gradient == null ? (fill ?? AppColors.surface) : null,
      gradient: gradient,
      borderRadius: radius,
      border: bordered
          ? Border.all(
              color: borderColor ?? AppColors.border,
              width: borderWidth,
            )
          : null,
      boxShadow: shadow,
    );
  }
}
