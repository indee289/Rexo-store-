import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography — a two-font premium system:
/// • Manrope (600–700) for headings / titles / buttons
/// • Inter (400–500) for body / labels / captions
///
/// Swap the two builders below to re-font the whole app.
class AppTextStyles {
  AppTextStyles._();

  /// Heading / title typeface.
  static TextStyle _heading({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.manrope(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  /// Body / label typeface.
  static TextStyle _body({
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

  /// Base font family used by the theme (body text).
  static String? get fontFamily => GoogleFonts.inter().fontFamily;

  // ── Headings (Manrope) ─────────────────────────────────────────────────
  static TextStyle get h1 =>
      _heading(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.5);
  static TextStyle get h2 =>
      _heading(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.4);
  static TextStyle get h3 =>
      _heading(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -0.3);
  static TextStyle get h4 =>
      _heading(fontSize: 20, fontWeight: FontWeight.w700, height: 1.35, letterSpacing: -0.2);
  static TextStyle get h5 =>
      _heading(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: -0.2);
  static TextStyle get h6 =>
      _heading(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: -0.1);

  // ── Body (Inter) ───────────────────────────────────────────────────────
  static TextStyle get bodyLarge =>
      _body(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyMedium =>
      _body(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall =>
      _body(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get caption =>
      _body(fontSize: 11, fontWeight: FontWeight.w400, height: 1.4);

  // ── Buttons (Manrope) ──────────────────────────────────────────────────
  static TextStyle get button => _heading(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.2,
        letterSpacing: 0.1,
      );

  // ── Labels (Inter) ─────────────────────────────────────────────────────
  static TextStyle get labelLarge =>
      _body(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);
  static TextStyle get labelMedium =>
      _body(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4);
  static TextStyle get labelSmall =>
      _body(fontSize: 10, fontWeight: FontWeight.w500, height: 1.4);
  static TextStyle get overline => _heading(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        height: 1.4,
      );
}
