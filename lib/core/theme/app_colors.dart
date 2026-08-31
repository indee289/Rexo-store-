import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand — Teal ───────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF0D9488); // Teal 600
  static const Color primaryLight  = Color(0xFF14B8A6); // Teal 500
  static const Color primaryDark   = Color(0xFF0F766E); // Teal 700
  static const Color primaryDeep   = Color(0xFF115E59); // Teal 800
  static const Color primaryBg     = Color(0xFFF0FDFA); // Teal 50

  // ── Secondary (compatibility) ──────────────────────────────────────────────
  static const Color secondary     = Color(0xFF0F172A); // Near-black

  // ── Accent ─────────────────────────────────────────────────────────────────
  static const Color accent        = Color(0xFFF59E0B); // Amber
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
  static const Color background  = Color(0xFFFFFFFF); // Pure white
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color card        = Color(0xFFFFFFFF);
  static const Color surfaceAlt  = Color(0xFFF8FAFC); // Near-white for inputs
  static const Color border      = Color(0xFFE2E8F0); // Light gray
  static const Color divider     = Color(0xFFF1F5F9);

  // ── Dark surfaces (kept for compatibility) ─────────────────────────────────
  static const Color darkBackground  = Color(0xFF0D0E1A);
  static const Color darkSurface     = Color(0xFF13141F);
  static const Color darkCard        = Color(0xFF1A1B2E);
  static const Color darkSurfaceAlt  = Color(0xFF1E2035);
  static const Color darkBorder      = Color(0xFF2A2B40);
  static const Color darkDivider     = Color(0xFF1E2035);
  static const Color darkTextPrimary   = Color(0xFFF0F0FF);
  static const Color darkTextSecondary = Color(0xFF9B9DC8);
  static const Color darkTextHint      = Color(0xFF4B4D72);

  // ── Light text ─────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A); // Near black
  static const Color textSecondary = Color(0xFF64748B); // Medium gray
  static const Color textHint      = Color(0xFF94A3B8); // Light gray

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
  static const Color shimmerBase      = Color(0xFFF1F5F9);
  static const Color shimmerHighlight = Color(0xFFFFFFFF);
  static const Color darkShimmerBase      = darkSurfaceAlt;
  static const Color darkShimmerHighlight = Color(0xFF252640);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
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
