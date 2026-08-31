import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight  = Color(0xFF818CF8); // Indigo 400
  static const Color primaryDark   = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDeep   = Color(0xFF3730A3); // Indigo 700

  // ── Accent ─────────────────────────────────────────────────────────────────
  static const Color accent        = Color(0xFFF59E0B); // Amber — warm contrast
  static const Color accentPink    = Color(0xFFEC4899);
  static const Color accentTeal    = Color(0xFF14B8A6);
  static const Color accentPurple  = Color(0xFFA855F7);
  static const Color accentGreen   = Color(0xFF22C55E);
  static const Color accentOrange  = Color(0xFFF97316);
  static const Color accentIndigo  = Color(0xFF6366F1);
  static const Color accentAmber   = Color(0xFFF59E0B);
  static const Color accentBrown   = Color(0xFF92400E);
  static const Color neutral       = Color(0xFF6B7280);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF38BDF8);

  // ── Light surfaces ─────────────────────────────────────────────────────────
  static const Color background  = Color(0xFFF5F6FF); // very slight indigo tint
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color card        = Color(0xFFFFFFFF);
  static const Color surfaceAlt  = Color(0xFFEEF0FF); // indigo tinted
  static const Color border      = Color(0xFFE0E2F0);
  static const Color divider     = Color(0xFFF0F1FA);

  // ── Dark surfaces ──────────────────────────────────────────────────────────
  static const Color darkBackground  = Color(0xFF0D0E1A); // near black indigo
  static const Color darkSurface     = Color(0xFF13141F); // dark navy
  static const Color darkCard        = Color(0xFF1A1B2E); // card navy
  static const Color darkSurfaceAlt  = Color(0xFF1E2035);
  static const Color darkBorder      = Color(0xFF2A2B40);
  static const Color darkDivider     = Color(0xFF1E2035);
  static const Color darkTextPrimary   = Color(0xFFF0F0FF);
  static const Color darkTextSecondary = Color(0xFF9B9DC8);
  static const Color darkTextHint      = Color(0xFF4B4D72);

  // ── Light text ─────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0D0E1A);
  static const Color textSecondary = Color(0xFF4B4D72);
  static const Color textHint      = Color(0xFF9B9DC8);

  // ── Social ─────────────────────────────────────────────────────────────────
  static const Color socialInstagram = Color(0xFFE1306C);
  static const Color socialYoutube   = Color(0xFFFF0000);
  static const Color socialTiktok    = Color(0xFF010101);
  static const Color socialTwitter   = Color(0xFF1DA1F2);
  static const Color socialFacebook  = Color(0xFF1877F2);
  static const Color socialLinkedIn  = Color(0xFF0A66C2);

  // ── Role chips ─────────────────────────────────────────────────────────────
  static const Color roleCreator = primary;
  static const Color roleBrand   = accentPurple;
  static const Color roleAdmin   = error;
  static const Color verified    = primary;

  // ── Shimmer ────────────────────────────────────────────────────────────────
  static const Color shimmerBase      = Color(0xFFE8E9F8);
  static const Color shimmerHighlight = Color(0xFFF5F6FF);
  static const Color darkShimmerBase      = darkSurfaceAlt;
  static const Color darkShimmerHighlight = Color(0xFF252640);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFEEF0FF), Color(0xFFF5F6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A1B2E), Color(0xFF13141F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
