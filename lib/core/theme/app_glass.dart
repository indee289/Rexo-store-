import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Liquid-glass material tokens — the single source of truth for every frosted
/// surface in the app.
///
/// A glass pane is always built from the same four layers, in this order:
///   1. **Blur** — a [BackdropFilter] using one of the [blurSigma] steps, which
///      samples whatever the ambient backdrop painted behind it.
///   2. **Tint** — a translucent fill ([surface], [card], [recessed], ...) so
///      the pane has body and text stays legible.
///   3. **Sheen** — [AppColors.glassSheen], a specular highlight that fades
///      from the top edge, which is what makes the pane read as *curved* glass.
///   4. **Rim** — a hairline 1px [border] plus the brighter [rimHighlight] along
///      the top edge only.
///
/// Use the `GlassSurface` widget (lib/core/widgets/glass/glass_surface.dart)
/// rather than assembling these by hand — it applies the layers in the correct
/// order and guards against nesting blurs.
///
/// ### Why the tints are stronger than a typical dark-mode glass spec
/// The canonical "8-18% white" glass tint assumes a dark or richly coloured
/// backdrop. Campster is light-only: at 12% white over a near-white backdrop a
/// pane is invisible and body text drops below WCAG AA. So primary panes use
/// 32-55% white, and the 8-18% range is reserved for [tintOverImage] /
/// [tintOverBrand], where there genuinely is colour behind the glass.
abstract class AppGlass {
  AppGlass._();

  // ───────────────────────────────────────────────────────────────────────────
  // Blur
  // ───────────────────────────────────────────────────────────────────────────

  /// Standard backdrop blur for cards and mid-size panes.
  static const double blurSigma = 24;

  /// Lighter blur for small glass (chips, icon buttons, inline pills).
  static const double blurSigmaSubtle = 14;

  /// Heavy blur for modal glass — sheets, dialogs, the nav bar.
  static const double blurSigmaModal = 30;

  /// Blur used by the ambient backdrop to smear its colour blobs.
  static const double blurSigmaBackdrop = 60;

  /// Ready-made image filters, so call-sites don't re-import `dart:ui`.
  static ui.ImageFilter get filter =>
      ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);
  static ui.ImageFilter get filterSubtle =>
      ui.ImageFilter.blur(sigmaX: blurSigmaSubtle, sigmaY: blurSigmaSubtle);
  static ui.ImageFilter get filterModal =>
      ui.ImageFilter.blur(sigmaX: blurSigmaModal, sigmaY: blurSigmaModal);

  /// Build a blur filter for an arbitrary sigma.
  static ui.ImageFilter blurOf(double sigma) =>
      ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

  // ───────────────────────────────────────────────────────────────────────────
  // Opacity ramp
  // ───────────────────────────────────────────────────────────────────────────

  /// Primary pane tint opacity (sheets, app bars).
  static const double surfaceOpacity = 0.55;

  /// Card pane tint opacity.
  static const double cardOpacity = 0.48;

  /// Recessed fill opacity (inputs, chips, tracks).
  static const double recessedOpacity = 0.32;

  /// Tint opacity when glass sits over an image or a brand-red fill — this is
  /// the classic 8-18% range, usable because there is real colour behind.
  static const double overImageOpacity = 0.18;
  static const double overBrandOpacity = 0.12;

  /// Nav bar / dock tint.
  static const double dockOpacityLight = 0.62;
  static const double dockOpacityDark = 0.62;

  /// Glass button fill.
  static const double buttonOpacityLight = 0.42;
  static const double buttonOpacityDark = 0.42;

  /// Hairline rim.
  static const double borderOpacityLight = 0.55;
  static const double borderOpacityDark = 0.55;

  /// Width of the hairline rim. Kept at a true hairline.
  static const double borderWidth = 1.0;

  // ───────────────────────────────────────────────────────────────────────────
  // Tints
  // ───────────────────────────────────────────────────────────────────────────

  /// Primary frosted pane tint — sheets, app bars, large surfaces.
  ///
  /// The `isDark` parameter is retained for call-site compatibility. The app is
  /// light-only, so both branches resolve identically.
  static Color surface(bool isDark) => AppColors.surface;

  /// Card pane tint.
  static Color card(bool isDark) => AppColors.card;

  /// Recessed fill for inputs, chips and track backgrounds.
  static Color recessed(bool isDark) => AppColors.surfaceAlt;

  /// Nav bar / dock tint.
  static Color dock(bool isDark) =>
      Colors.white.withOpacity(dockOpacityLight);

  /// Translucent fill for glass-style buttons.
  static Color button(bool isDark) =>
      Colors.white.withOpacity(buttonOpacityLight);

  /// Tint for glass laid over photography.
  static Color tintOverImage(bool isDark) =>
      Colors.white.withOpacity(overImageOpacity);

  /// Tint for glass laid over a brand-red fill.
  static Color tintOverBrand(bool isDark) =>
      Colors.white.withOpacity(overBrandOpacity);

  /// Brand-tinted glass — selected chips, active tabs.
  static Color brandTint(bool isDark) => AppColors.primary.withOpacity(0.14);

  /// Hairline rim that reads as a light edge on a glass pane.
  static Color border(bool isDark) =>
      Colors.white.withOpacity(borderOpacityLight);

  /// Slightly darker rim for panes that need to separate from a light backdrop.
  static Color borderContrast(bool isDark) => AppColors.border;

  /// Brand rim for focused inputs and active surfaces.
  static Color borderBrand(bool isDark) => AppColors.primary.withOpacity(0.45);

  /// Scrim behind modal glass.
  static Color scrim(bool isDark) => Colors.black.withOpacity(0.28);

  // ───────────────────────────────────────────────────────────────────────────
  // Decoration helpers
  // ───────────────────────────────────────────────────────────────────────────

  /// The specular sheen laid over a pane. See [AppColors.glassSheen].
  static const Gradient sheen = AppColors.glassSheen;

  /// The bright top-edge rim light. See [AppColors.glassRim].
  static const Gradient rimHighlight = AppColors.glassRim;

  /// A complete glass decoration for a pane of the given [radius].
  ///
  /// Pass this to a `Container` that is already wrapped in a `ClipRRect` +
  /// `BackdropFilter`; it supplies the tint, rim and shadow but not the blur.
  static BoxDecoration decoration({
    required BorderRadius radius,
    Color? tint,
    Color? rim,
    List<BoxShadow>? shadow,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: gradient == null ? (tint ?? AppColors.surface) : null,
      gradient: gradient,
      borderRadius: radius,
      border: Border.all(
        color: rim ?? Colors.white.withOpacity(borderOpacityLight),
        width: borderWidth,
      ),
      boxShadow: shadow,
    );
  }
}
