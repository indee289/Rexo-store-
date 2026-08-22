import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Primary palette
  static const Color primary = Color(0xFFFF5722);
  static const Color primaryLight = Color(0xFFFF8A65);
  static const Color primaryDark = Color(0xFFE64A19);

  /// Secondary
  static const Color secondary = Color(0xFF1A1A2E);

  /// Backgrounds
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  /// Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);

  /// Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  /// Borders and dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  /// Gradient for primary buttons/accents
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Shimmer colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
