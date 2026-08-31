import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Single source of truth for the app's typeface. Modern, clean, geometric
  /// sans — the LinkedIn/Instagram-style vibe. Swap here to re-font the whole
  /// app.
  static TextStyle _font({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  /// Heading styles using Poppins
  /// Colors are intentionally omitted so they inherit from the active theme's
  /// textTheme (light or dark), ensuring proper contrast in both modes.
  static TextStyle get h1 => _font(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get h2 => _font(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get h3 => _font(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get h4 => _font(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get h5 => _font(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get h6 => _font(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// Body styles
  static TextStyle get bodyLarge => _font(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => _font(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => _font(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Caption
  static TextStyle get caption => _font(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  /// Button text
  static TextStyle get button => _font(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.2,
      );

  /// Label styles
  static TextStyle get labelLarge => _font(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get labelMedium => _font(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get labelSmall => _font(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  /// Overline
  static TextStyle get overline => _font(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        height: 1.4,
      );
}
