import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Primary palette — deep premium blue
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);

  /// Accent / secondary
  static const Color secondary = Color(0xFF0F172A);
  static const Color accent = Color(0xFF8B5CF6);

  /// Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  /// Alternate surface (input fills, chips, message-in bubble).
  static const Color surfaceAlt = Color(0xFFEFF6FF);
  static const Color darkSurfaceAlt = Color(0xFF1E293B);

  /// Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  /// Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);

  /// Borders and dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  /// Role accent colors
  static const Color roleCreator = primary;
  static const Color roleBrand = Color(0xFF8B5CF6);
  static const Color roleAdmin = Color(0xFFEF4444);

  /// Verified-checkmark accent
  static const Color verified = primary;

  /// Social-platform brand accents
  static const Color socialInstagram = Color(0xFFE1306C);
  static const Color socialYoutube = Color(0xFFFF0000);
  static const Color socialTiktok = Color(0xFF010101);
  static const Color socialTwitter = Color(0xFF1DA1F2);
  static const Color socialFacebook = Color(0xFF1877F2);
  static const Color socialLinkedIn = Color(0xFF0A66C2);

  /// Neutral/section accent palette
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentIndigo = Color(0xFF4F46E5);
  static const Color accentBrown = Color(0xFF92400E);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color neutral = Color(0xFF64748B);

  /// Premium gradient for primary buttons/accents
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hero/banner gradient
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card gradient (subtle)
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark theme surface ramp
  static const Color darkBackground = Color(0xFF0B0F1A);
  static const Color darkSurface = Color(0xFF141B2D);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextHint = Color(0xFF475569);

  /// Shimmer colors (light theme)
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

  /// Shimmer colors (dark theme)
  static const Color darkShimmerBase = darkSurfaceAlt;
  static const Color darkShimmerHighlight = Color(0xFF334155);
}
