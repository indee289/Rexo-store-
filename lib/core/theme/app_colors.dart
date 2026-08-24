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

  /// Alternate surface (input fills, chips, message-in bubble).
  /// Semantic surface token added for the premium redesign.
  static const Color surfaceAlt = Color(0xFFF3F4F6);
  static const Color darkSurfaceAlt = Color(0xFF2C2C2C);

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

  /// Role accent colors.
  ///
  /// These pull the previously hard-coded role-badge literals (from
  /// `public_profile_screen.dart`) into the token system so `RoleBadge` and
  /// any role tag reference tokens instead of raw `Color(0xFF...)` values.
  static const Color roleCreator = primary;
  static const Color roleBrand = Color(0xFF2196F3);
  static const Color roleAdmin = Color(0xFF9C27B0);

  /// Verified-checkmark accent (Twitter/X style blue).
  static const Color verified = Color(0xFF1DA1F2);

  /// Social-platform brand accents.
  ///
  /// These pull the previously hard-coded social brand literals (from
  /// `linked_accounts_screen.dart`) into the token system so linked-account
  /// fields reference tokens instead of raw `Color(0xFF...)` values.
  static const Color socialInstagram = Color(0xFFE1306C);
  static const Color socialYoutube = Color(0xFFFF0000);
  static const Color socialTiktok = Color(0xFF010101);

  /// Neutral/section accent palette.
  ///
  /// Pulls the previously hard-coded Material named colors (e.g. `Colors.teal`,
  /// `Colors.indigo`) used to colour-code admin sections into the token system,
  /// so admin screens reference tokens instead of raw Material color constants
  /// while keeping their existing visual variety.
  static const Color accentTeal = Color(0xFF009688);
  static const Color accentIndigo = Color(0xFF3F51B5);
  static const Color accentBrown = Color(0xFF795548);
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentPurple = roleAdmin;
  static const Color accentAmber = Color(0xFFFFB300);
  static const Color neutral = Color(0xFF9E9E9E);

  /// Gradient for primary buttons/accents
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Shimmer colors (light theme).
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  /// Shimmer colors (dark theme).
  ///
  /// Added so skeleton loaders can stay fully token-driven in both themes
  /// instead of relying on inline `Color(0xFF...)` literals. The base reuses
  /// the dark alternate surface; the highlight matches the dark hairline
  /// border value from the design's color table.
  static const Color darkShimmerBase = darkSurfaceAlt;
  static const Color darkShimmerHighlight = Color(0xFF3A3A3A);
}
