import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// iOS-inspired typography using **Inter** as an SF Pro-equivalent.
///
/// Follows Apple's iOS Human Interface Guidelines type scale:
/// - Large Title (34), Title 1/2/3, Headline (17 semibold), Body (17),
///   Callout (16), Subheadline (15), Footnote (13), Caption (12/11).
///
/// All screens/widgets continue to import familiar names (`h1`..`h6`,
/// `bodyLarge`, `caption`, etc.) — these are re-mapped onto the iOS scale
/// so the existing 69 screens automatically adopt the new type ramp.
class AppTextStyles {
  AppTextStyles._();

  /// Single typeface (SF Pro equivalent) — iOS uses one family for everything.
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

  /// Base font family used across the app (Inter as SF Pro alternative).
  static String? get fontFamily => GoogleFonts.inter().fontFamily;

  // ── iOS Type Scale ─────────────────────────────────────────────────────────
  /// Large Title — 34pt bold, used at the top of scrollable screens.
  static TextStyle get largeTitle =>
      _t(fontSize: 34, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: 0.37);

  /// Title 1 — 28pt bold.
  static TextStyle get title1 =>
      _t(fontSize: 28, fontWeight: FontWeight.w700, height: 1.20, letterSpacing: 0.36);

  /// Title 2 — 22pt bold.
  static TextStyle get title2 =>
      _t(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: 0.35);

  /// Title 3 — 20pt semibold.
  static TextStyle get title3 =>
      _t(fontSize: 20, fontWeight: FontWeight.w600, height: 1.25, letterSpacing: 0.38);

  /// Headline — 17pt semibold.
  static TextStyle get headline =>
      _t(fontSize: 17, fontWeight: FontWeight.w600, height: 1.30, letterSpacing: -0.41);

  /// Body — 17pt regular.
  static TextStyle get body =>
      _t(fontSize: 17, fontWeight: FontWeight.w400, height: 1.35, letterSpacing: -0.41);

  /// Callout — 16pt regular.
  static TextStyle get callout =>
      _t(fontSize: 16, fontWeight: FontWeight.w400, height: 1.30, letterSpacing: -0.32);

  /// Subheadline — 15pt regular.
  static TextStyle get subheadline =>
      _t(fontSize: 15, fontWeight: FontWeight.w400, height: 1.35, letterSpacing: -0.24);

  /// Footnote — 13pt regular.
  static TextStyle get footnote =>
      _t(fontSize: 13, fontWeight: FontWeight.w400, height: 1.35, letterSpacing: -0.08);

  /// Caption 1 — 12pt regular.
  static TextStyle get caption1 =>
      _t(fontSize: 12, fontWeight: FontWeight.w400, height: 1.35, letterSpacing: 0);

  /// Caption 2 — 11pt regular.
  static TextStyle get caption2 =>
      _t(fontSize: 11, fontWeight: FontWeight.w400, height: 1.35, letterSpacing: 0.07);

  // ── Legacy compatibility aliases ───────────────────────────────────────────
  // Existing 100+ call-sites reference these names. They map onto the iOS
  // scale so screens automatically adopt the iOS typography with zero edits.

  /// h1 → iOS Title 1 (28pt bold).
  static TextStyle get h1 => title1;
  /// h2 → iOS Title 2 (22pt bold).
  static TextStyle get h2 => title2;
  /// h3 → iOS Title 3 (20pt semibold).
  static TextStyle get h3 => title3;
  /// h4 → iOS Headline (17pt semibold).
  static TextStyle get h4 => headline;
  /// h5 → 17pt medium — between headline and body.
  static TextStyle get h5 =>
      _t(fontSize: 17, fontWeight: FontWeight.w600, height: 1.30, letterSpacing: -0.41);
  /// h6 → 15pt semibold — small section titles.
  static TextStyle get h6 =>
      _t(fontSize: 15, fontWeight: FontWeight.w600, height: 1.35, letterSpacing: -0.24);

  /// bodyLarge → iOS Body (17pt).
  static TextStyle get bodyLarge => body;
  /// bodyMedium → iOS Callout (16pt).
  static TextStyle get bodyMedium => callout;
  /// bodySmall → iOS Subheadline (15pt).
  static TextStyle get bodySmall => subheadline;
  /// caption → iOS Caption 1 (12pt).
  static TextStyle get caption => caption1;

  /// button → iOS-style button label (17pt semibold, white, tight tracking).
  static TextStyle get button => _t(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.2,
        letterSpacing: -0.24,
      );

  /// Label variants used by widgets.
  static TextStyle get labelLarge => _t(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.24,
      );
  static TextStyle get labelMedium => _t(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.08,
      );
  static TextStyle get labelSmall => _t(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0.07,
      );

  /// iOS uppercase section header — the small caps label above grouped lists.
  static TextStyle get sectionHeader => _t(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0x993C3C43),
        letterSpacing: -0.08,
      );
}
