import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography — **Campster Liquid Glass**.
///
/// One sans-serif family (**Inter**) with sharp weight contrast, which is what
/// keeps labels legible on a translucent pane: on glass, weight and size carry
/// the hierarchy because background contrast is partly lost to the blur.
/// Titles are bold with tight negative tracking; body text is 14pt regular.
///
/// Legacy aliases (h1..h6, bodyLarge, caption, ...) map onto this ramp so every
/// screen picks it up without touching its call-sites.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _t({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  static String? get fontFamily => GoogleFonts.inter().fontFamily;

  // ── Scale ─────────────────────────────────────────────────────────────────
  /// Screen big title / large screen name.
  static TextStyle get largeTitle =>
      _t(fontSize: 26, fontWeight: FontWeight.w700, height: 1.20, letterSpacing: -0.4);

  /// Screen title (App bar big title).
  static TextStyle get title1 =>
      _t(fontSize: 22, fontWeight: FontWeight.w700, height: 1.20, letterSpacing: -0.3);

  /// Section title / profile name.
  static TextStyle get title2 =>
      _t(fontSize: 18, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.2);

  /// Sub-section title / stat value.
  static TextStyle get title3 =>
      _t(fontSize: 16, fontWeight: FontWeight.w600, height: 1.25, letterSpacing: -0.1);

  /// Headline — inline bold names, key labels, card titles.
  static TextStyle get headline =>
      _t(fontSize: 14, fontWeight: FontWeight.w600, height: 1.30, letterSpacing: -0.1);

  /// Body — standard body text.
  static TextStyle get body =>
      _t(fontSize: 14, fontWeight: FontWeight.w400, height: 1.35);

  /// Callout — slightly larger body.
  static TextStyle get callout =>
      _t(fontSize: 15, fontWeight: FontWeight.w400, height: 1.30);

  /// Subheadline — secondary content and descriptions.
  static TextStyle get subheadline =>
      _t(fontSize: 13, fontWeight: FontWeight.w400, height: 1.35);

  /// Footnote — meta, timestamps.
  static TextStyle get footnote =>
      _t(fontSize: 12, fontWeight: FontWeight.w400, height: 1.35);

  /// Caption 1 — small meta text.
  static TextStyle get caption1 =>
      _t(fontSize: 11, fontWeight: FontWeight.w400, height: 1.35);

  /// Caption 2 — smallest.
  static TextStyle get caption2 =>
      _t(fontSize: 10, fontWeight: FontWeight.w400, height: 1.35);

  // ── Legacy compatibility aliases ───────────────────────────────────────────
  static TextStyle get h1 => title1;
  static TextStyle get h2 => title2;
  static TextStyle get h3 => title3;
  static TextStyle get h4 => headline;
  static TextStyle get h5 =>
      _t(fontSize: 14, fontWeight: FontWeight.w600, height: 1.30);
  static TextStyle get h6 =>
      _t(fontSize: 13, fontWeight: FontWeight.w600, height: 1.30);

  static TextStyle get bodyLarge => body;
  static TextStyle get bodyMedium => body;
  static TextStyle get bodySmall => subheadline;
  static TextStyle get caption => caption1;

  /// Button label — 14pt semibold, white for use on the brand-red fill.
  /// Glass buttons override the colour per variant.
  static TextStyle get button => _t(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.2,
      );

  static TextStyle get labelLarge => _t(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.30,
      );
  static TextStyle get labelMedium => _t(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.30,
      );
  static TextStyle get labelSmall => _t(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.30,
      );

  /// Section header — small, tracked-out, muted.
  static TextStyle get sectionHeader => _t(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF737373),
        letterSpacing: 0.5,
      );
}
