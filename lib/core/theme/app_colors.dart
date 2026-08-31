import 'package:flutter/material.dart';

/// Central color palette — modern, minimal "grouped-card" design language.
///
/// Direction: fresh green accent, near-black text, soft off-white page
/// background with pure-white floating cards (light) and a clean near-black
/// surface stack (dark). All token names are kept stable so every screen and
/// widget that already references them picks up the new look automatically.
class AppColors {
  AppColors._();

  // ── Brand — Purple ─────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF7C3AED); // Violet 600
  static const Color primaryLight  = Color(0xFFA78BFA); // Violet 400
  static const Color primaryDark   = Color(0xFF6D28D9); // Violet 700
  static const Color primaryDeep   = Color(0xFF5B21B6); // Violet 800
  static const Color primaryBg     = Color(0xFFF1EBFF); // Tinted violet wash

  // ── Secondary (compatibility) ──────────────────────────────────────────────
  static const Color secondary     = Color(0xFF0B0B12); // Near-black

  // ── Accent ─────────────────────────────────────────────────────────────────
  static const Color accent        = Color(0xFF16C784); // Alias → primary green
  static const Color accentPink    = Color(0xFFF43F8E);
  static const Color accentTeal    = Color(0xFF14B8A6);
  static const Color accentPurple  = Color(0xFF8B5CF6);
  static const Color accentGreen   = Color(0xFF22C55E);
  static const Color accentOrange  = Color(0xFFFB923C);
  static const Color accentIndigo  = Color(0xFF6366F1);
  static const Color accentAmber   = Color(0xFFF59E0B);
  static const Color accentBrown   = Color(0xFF92400E);
  static const Color neutral       = Color(0xFF71717A);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16C784);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFF43F5E);
  static const Color info    = Color(0xFF38BDF8);

  // ── Light surfaces ─────────────────────────────────────────────────────────
  static const Color background  = Color(0xFFF6F7F9); // Soft off-white page
  static const Color surface     = Color(0xFFFFFFFF); // Floating cards
  static const Color card        = Color(0xFFFFFFFF);
  static const Color surfaceAlt  = Color(0xFFF1F3F6); // Inputs / subtle fills
  static const Color border      = Color(0xFFEDEFF3); // Very light hairline
  static const Color divider     = Color(0xFFF1F3F6);

  // ── Dark surfaces ──────────────────────────────────────────────────────────
  static const Color darkBackground  = Color(0xFF0B0B0F); // Near-black page
  static const Color darkSurface     = Color(0xFF141419); // App bars
  static const Color darkCard        = Color(0xFF1A1A21); // Floating cards
  static const Color darkSurfaceAlt  = Color(0xFF20202A); // Inputs / fills
  static const Color darkBorder      = Color(0xFF2A2A34);
  static const Color darkDivider     = Color(0xFF23232D);
  static const Color darkTextPrimary   = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextHint      = Color(0xFF6B6B76);

  // ── Light text ─────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0B0B12); // Near black
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  static const Color textHint      = Color(0xFF9CA3AF); // Light gray

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
  static const Color shimmerBase      = Color(0xFFEDEFF3);
  static const Color shimmerHighlight = Color(0xFFFFFFFF);
  static const Color darkShimmerBase      = darkSurfaceAlt;
  static const Color darkShimmerHighlight = Color(0xFF2C2C38);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF6F7F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A1A21), Color(0xFF141419)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
