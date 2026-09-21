import 'package:flutter/material.dart';

/// Central color palette — modern marketplace green theme.
///
/// Design direction: **fresh emerald green marketplace** with premium modern
/// aesthetics. All token names are kept stable so every screen and widget
/// that already references them picks up the new look automatically.
///
/// Palette philosophy:
/// - **Primary (Emerald)** — trust, growth, marketplace/money vibes
/// - **Deep dark surfaces** — modern, premium OLED-friendly dark mode
/// - **Vibrant accents** — teal, mint, amber for balance and warmth
/// - **Rich gradients** — used sparingly on hero surfaces and CTAs
class AppColors {
  AppColors._();

  // ── Brand — Emerald Green ────────────────────────────────────────────────
  // Fresh, modern marketplace green. Evokes growth, trust, and success.
  static const Color primary       = Color(0xFF10B981); // Emerald 500
  static const Color primaryLight  = Color(0xFF34D399); // Emerald 400
  static const Color primaryDark   = Color(0xFF059669); // Emerald 600
  static const Color primaryDeep   = Color(0xFF047857); // Emerald 700
  static const Color primaryBg     = Color(0xFFECFDF5); // Emerald 50 wash

  // ── Secondary (compatibility) ──────────────────────────────────────────────
  static const Color secondary     = Color(0xFF0A0F0D); // Near-black w/ green tint

  // ── Accent Colors ──────────────────────────────────────────────────────────
  static const Color accent        = Color(0xFF10B981); // Alias → primary
  static const Color accentMint    = Color(0xFF6EE7B7); // Soft mint
  static const Color accentTeal    = Color(0xFF14B8A6); // Teal 500
  static const Color accentEmerald = Color(0xFF10B981); // Emerald 500
  static const Color accentLime    = Color(0xFF84CC16); // Lime 500
  static const Color accentPurple  = Color(0xFF8B5CF6); // Violet 500
  static const Color accentPink    = Color(0xFFEC4899); // Pink 500
  static const Color accentGreen   = Color(0xFF22C55E); // Green 500
  static const Color accentOrange  = Color(0xFFFB923C); // Orange 400
  static const Color accentIndigo  = Color(0xFF6366F1); // Indigo 500
  static const Color accentAmber   = Color(0xFFF59E0B); // Amber 500
  static const Color accentBrown   = Color(0xFF92400E);
  static const Color accentCyan    = Color(0xFF06B6D4); // Cyan 500
  static const Color neutral       = Color(0xFF71717A);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Match primary
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error   = Color(0xFFEF4444); // Red 500
  static const Color info    = Color(0xFF06B6D4); // Cyan 500

  // ── Light surfaces ─────────────────────────────────────────────────────────
  // Soft off-white with the faintest green undertone.
  static const Color background  = Color(0xFFF7FAF8); // Whisper green-white
  static const Color surface     = Color(0xFFFFFFFF); // Pure white cards
  static const Color card        = Color(0xFFFFFFFF);
  static const Color surfaceAlt  = Color(0xFFF1F5F3); // Inputs / subtle fills
  static const Color border      = Color(0xFFE5EDEA); // Hairline w/ green hint
  static const Color divider     = Color(0xFFEEF3F0);

  // ── Dark surfaces ──────────────────────────────────────────────────────────
  // Deep, rich near-black stack with subtle warm green undertones.
  // Premium OLED-friendly with layered surfaces for visual hierarchy.
  static const Color darkBackground  = Color(0xFF0A0F0D); // Deepest — page
  static const Color darkSurface     = Color(0xFF101613); // App bars / bottom nav
  static const Color darkCard        = Color(0xFF161E1A); // Floating cards
  static const Color darkSurfaceAlt  = Color(0xFF1D2621); // Inputs / fills
  static const Color darkBorder      = Color(0xFF283029); // Card borders
  static const Color darkDivider     = Color(0xFF212925);
  static const Color darkTextPrimary   = Color(0xFFF0FDF4); // Slight green-white
  static const Color darkTextSecondary = Color(0xFFA7B0AC);
  static const Color darkTextHint      = Color(0xFF6B746F);

  // ── Light text ─────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0A0F0D); // Near black
  static const Color textSecondary = Color(0xFF4B5563); // Slate 600
  static const Color textHint      = Color(0xFF9CA3AF); // Gray 400

  // ── Social ─────────────────────────────────────────────────────────────────
  static const Color socialInstagram = Color(0xFFE1306C);
  static const Color socialYoutube   = Color(0xFFFF0000);
  static const Color socialTiktok    = Color(0xFF010101);
  static const Color socialTwitter   = Color(0xFF1DA1F2);
  static const Color socialFacebook  = Color(0xFF1877F2);
  static const Color socialLinkedIn  = Color(0xFF0A66C2);

  // ── Role chips ─────────────────────────────────────────────────────────────
  static const Color roleCreator = primary;       // Emerald
  static const Color roleBrand   = accentPurple;  // Violet
  static const Color roleAdmin   = error;         // Red
  static const Color verified    = primary;       // Emerald check

  // ── Shimmer ────────────────────────────────────────────────────────────────
  static const Color shimmerBase      = Color(0xFFE9F0EC);
  static const Color shimmerHighlight = Color(0xFFFFFFFF);
  static const Color darkShimmerBase      = darkSurfaceAlt;
  static const Color darkShimmerHighlight = Color(0xFF2B3530);

  // ── Gradients ──────────────────────────────────────────────────────────────
  /// Primary CTA gradient — vibrant emerald.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hero surface gradient — deep, rich emerald for premium panels.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Light card gradient — subtle depth.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FAF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark card gradient — layered dark surface.
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1D2621), Color(0xFF161E1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gold / premium tier gradient (subscriptions, badges).
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Fresh mint gradient — for onboarding, empty states, positive moments.
  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Teal gradient — secondary accent for variety.
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Purple accent gradient — for creator/brand differentiation.
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep hero gradient — for premium/pro tier surfaces.
  static const LinearGradient deepGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF064E3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
