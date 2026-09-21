import 'package:flutter/material.dart';

/// Central color palette — **iOS-inspired light theme**.
///
/// Design direction: Apple Human Interface Guidelines — light, airy, refined.
/// System grays for surfaces, crisp black text, emerald green marketplace
/// accent. Grouped-list style with hairline separators.
///
/// **Dark tokens intentionally point to light equivalents** — the app is
/// light-only. Legacy call-sites that still reference dark* tokens continue
/// to compile, but visually the app is always light.
class AppColors {
  AppColors._();

  // ── Brand — Emerald Green ────────────────────────────────────────────────
  static const Color primary       = Color(0xFF10B981); // Emerald 500
  static const Color primaryLight  = Color(0xFF34D399); // Emerald 400
  static const Color primaryDark   = Color(0xFF059669); // Emerald 600
  static const Color primaryDeep   = Color(0xFF047857); // Emerald 700
  static const Color primaryBg     = Color(0xFFECFDF5); // Emerald 50 wash

  // ── Secondary (compatibility) ──────────────────────────────────────────────
  static const Color secondary     = Color(0xFF000000);

  // ── iOS System Colors + Accents ────────────────────────────────────────────
  static const Color accent        = Color(0xFF10B981);
  static const Color accentMint    = Color(0xFF6EE7B7);
  static const Color accentTeal    = Color(0xFF14B8A6);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentLime    = Color(0xFF84CC16);
  static const Color accentPurple  = Color(0xFFAF52DE); // iOS system purple
  static const Color accentPink    = Color(0xFFFF2D55); // iOS system pink
  static const Color accentGreen   = Color(0xFF34C759); // iOS system green
  static const Color accentOrange  = Color(0xFFFF9500); // iOS system orange
  static const Color accentIndigo  = Color(0xFF5856D6); // iOS system indigo
  static const Color accentAmber   = Color(0xFFFFCC00); // iOS system yellow
  static const Color accentBrown   = Color(0xFFA2845E); // iOS system brown
  static const Color accentCyan    = Color(0xFF32ADE6); // iOS system cyan
  static const Color neutral       = Color(0xFF8E8E93); // iOS system gray

  // ── Semantic (iOS system) ──────────────────────────────────────────────────
  static const Color success = Color(0xFF34C759); // iOS system green
  static const Color warning = Color(0xFFFF9500); // iOS system orange
  static const Color error   = Color(0xFFFF3B30); // iOS system red
  static const Color info    = Color(0xFF007AFF); // iOS system blue

  // ── iOS Light surfaces ─────────────────────────────────────────────────────
  /// iOS grouped background — the "outside" of grouped list cells.
  static const Color background  = Color(0xFFF2F2F7); // systemGroupedBackground
  /// Card / cell surface — pure white on grouped background.
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color card        = Color(0xFFFFFFFF);
  /// Secondary fill — inputs, chips, tinted surfaces.
  static const Color surfaceAlt  = Color(0xFFF2F2F7); // secondarySystemFill
  /// iOS hairline separator (opaque, non-transparent version).
  static const Color border      = Color(0xFFE5E5EA); // systemGray5
  static const Color divider     = Color(0xFFE5E5EA);
  /// True iOS separator (only for lists — same as border for consistency).
  static const Color separator   = Color(0xFFC6C6C8);
  /// iOS system gray family.
  static const Color systemGray  = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);

  // ── Legacy dark tokens (point to light equivalents — app is light-only) ──
  // These are kept so 100+ existing call-sites like `isDark ? darkCard : card`
  // continue to compile without a mass search-and-replace. Since we now force
  // ThemeMode.light in app.dart, the dark branch is effectively unreachable
  // and these values are visually irrelevant.
  static const Color darkBackground    = background;
  static const Color darkSurface       = surface;
  static const Color darkCard          = surface;
  static const Color darkSurfaceAlt    = surfaceAlt;
  static const Color darkBorder        = border;
  static const Color darkDivider       = divider;
  static const Color darkTextPrimary   = Color(0xFF000000);
  static const Color darkTextSecondary = Color(0x993C3C43);
  static const Color darkTextHint      = Color(0x4D3C3C43);

  // ── iOS Light text (label hierarchy) ───────────────────────────────────────
  /// Primary label — pure black.
  static const Color textPrimary   = Color(0xFF000000);
  /// Secondary label — iOS uses black at 60% opacity.
  static const Color textSecondary = Color(0x993C3C43);
  /// Tertiary label / placeholder — iOS uses black at 30% opacity.
  static const Color textHint      = Color(0x4D3C3C43);

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
  static const Color shimmerBase      = Color(0xFFE5E5EA);
  static const Color shimmerHighlight = Color(0xFFF8F8FA);
  static const Color darkShimmerBase      = shimmerBase;
  static const Color darkShimmerHighlight = shimmerHighlight;

  // ── Gradients ──────────────────────────────────────────────────────────────
  /// Primary CTA gradient — soft emerald.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hero surface gradient — deep emerald for premium panels.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card gradient — subtle depth on cards that opt-in.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Legacy dark card gradient — points to light (unreachable in light mode).
  static const LinearGradient darkCardGradient = cardGradient;

  /// Gold gradient — premium/pro tier badges.
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD60A), Color(0xFFFF9500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Fresh mint gradient — onboarding, positive moments.
  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Teal gradient — secondary accent variety.
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF32ADE6), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Purple gradient — creator/brand accent.
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFAF52DE), Color(0xFF5856D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep hero gradient — premium tier.
  static const LinearGradient deepGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF064E3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
