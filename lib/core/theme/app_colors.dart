import 'package:flutter/material.dart';

/// Central colour palette — **Campster premium, light**.
///
/// Design direction: a warm off-white canvas with opaque white cards lifted by
/// soft layered shadows, hairline separators at very low opacity, and brand red
/// used sparingly as the single accent. Think Stripe / Linear rather than
/// Material's saturated surfaces.
///
/// ### Why surfaces are opaque now
/// The previous iteration made every surface semi-transparent so it could sit
/// over a `BackdropFilter`. That has been removed: a blur is a full save-layer
/// plus a blur pass per pane, and with cards in a scrolling list it was the
/// single most expensive thing the UI did. Opaque surfaces over a flat canvas
/// paint in one pass, and on a light background they look near-identical —
/// depth now comes from shadow and hairlines instead.
///
/// **Dark tokens intentionally point to light equivalents** — the app is
/// light-only by product decision. Legacy call-sites referencing `dark*`
/// continue to compile and render identically.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  /// Primary brand red (logo / website).
  static const Color primary = Color(0xFF8B1A1A);

  /// Gradient + highlight red.
  static const Color primaryLight = Color(0xFFA52020);

  /// Pressed / deep states.
  static const Color primaryDark = Color(0xFF6B1212);
  static const Color primaryDeep = Color(0xFF4A0C0C);

  /// Very light red wash — selected rows, subtle fills, tinted icon bubbles.
  static const Color primaryBg = Color(0xFFFBF0F0);

  /// Brand red at low alpha, for tints that must stay light.
  static const Color primaryGlass = Color(0x148B1A1A); // 8%
  static const Color primaryRim = Color(0x3D8B1A1A); // 24%

  // ── Secondary (compatibility) ────────────────────────────────────────────
  static const Color secondary = Color(0xFF1A1714);

  // ── Accents ──────────────────────────────────────────────────────────────
  static const Color accent = primary;
  static const Color accentMint = Color(0xFF3FAE8E);
  static const Color accentTeal = Color(0xFF0E8F84);
  static const Color accentEmerald = Color(0xFF0C8A5F);
  static const Color accentLime = Color(0xFF6D9E18);
  static const Color accentPurple = Color(0xFF6E3597);
  static const Color accentPink = Color(0xFFC42B60);
  static const Color accentGreen = Color(0xFF178740);
  static const Color accentOrange = Color(0xFFCF7417);
  static const Color accentIndigo = Color(0xFF3F47B0);
  static const Color accentAmber = Color(0xFFC98E1E);
  static const Color accentBrown = Color(0xFF7A4A1F);
  static const Color accentCyan = Color(0xFF1B8495);
  static const Color accentRed = primaryLight;
  static const Color neutral = Color(0xFF6B6460);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF178740);
  static const Color warning = Color(0xFFC98E1E);
  static const Color error = Color(0xFFBE2B2B);
  static const Color info = Color(0xFF2A62A8);

  // ── Canvas and surfaces (all opaque) ─────────────────────────────────────
  /// App canvas — warm off-white, so white cards read as lifted.
  static const Color background = Color(0xFFF6F5F3);

  /// Secondary canvas stop, used by the subtle top wash.
  static const Color backgroundWarm = Color(0xFFFAF8F6);
  static const Color backgroundCool = Color(0xFFF2F1EF);

  /// Primary elevated surface — cards, sheets, bars.
  static const Color surface = Color(0xFFFFFFFF);

  /// Card surface. Same as [surface]; kept distinct so a future tier can
  /// differ without touching call-sites.
  static const Color card = Color(0xFFFFFFFF);

  /// Recessed fill — inputs, chips, progress tracks, skeletons.
  static const Color surfaceAlt = Color(0xFFF1EFEC);

  /// Hairline separator — 7% ink. Deliberately faint: on an off-white canvas a
  /// darker rule is the quickest way to make an interface look cheap.
  static const Color border = Color(0x121A1714);
  static const Color divider = Color(0x0D1A1714); // 5%
  static const Color separator = Color(0x121A1714);

  /// Gray family (disabled states, compatibility).
  static const Color systemGray = Color(0xFF8A827D);
  static const Color systemGray2 = Color(0xFFA39B96);
  static const Color systemGray3 = Color(0xFFC3BCB7);
  static const Color systemGray4 = Color(0xFFDCD7D2);
  static const Color systemGray5 = Color(0xFFEBE7E3);
  static const Color systemGray6 = Color(0xFFF5F3F1);

  // ── Legacy dark tokens (point to light — app is light-only) ─────────────
  static const Color darkBackground = background;
  static const Color darkSurface = surface;
  static const Color darkCard = card;
  static const Color darkSurfaceAlt = surfaceAlt;
  static const Color darkBorder = border;
  static const Color darkDivider = divider;
  static const Color darkTextPrimary = textPrimary;
  static const Color darkTextSecondary = textSecondary;
  static const Color darkTextHint = textHint;

  // ── Text (contrast-checked on white and on the canvas) ──────────────────
  /// Primary label — warm near-black. ~16:1 on white.
  static const Color textPrimary = Color(0xFF1A1714);

  /// Secondary label — meta, descriptions. ~6.1:1 on white.
  static const Color textSecondary = Color(0xFF6B6460);

  /// Tertiary label / placeholder. ~3.4:1 — large or decorative text only.
  static const Color textHint = Color(0xFF9B938E);

  /// Label on top of a filled brand-red surface.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Social brand colours ─────────────────────────────────────────────────
  static const Color socialInstagram = Color(0xFFE1306C);
  static const Color socialYoutube = Color(0xFFFF0000);
  static const Color socialTiktok = Color(0xFF010101);
  static const Color socialTwitter = Color(0xFF1DA1F2);
  static const Color socialFacebook = Color(0xFF1877F2);
  static const Color socialLinkedIn = Color(0xFF0A66C2);

  // ── Role chips ───────────────────────────────────────────────────────────
  static const Color roleCreator = primary;
  static const Color roleBrand = accentPurple;
  static const Color roleAdmin = accentIndigo;
  static const Color verified = info;

  // ── Skeleton / shimmer ───────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFEDEAE7);
  static const Color shimmerHighlight = Color(0xFFF8F6F4);
  static const Color darkShimmerBase = shimmerBase;
  static const Color darkShimmerHighlight = shimmerHighlight;

  // ── Gradients ────────────────────────────────────────────────────────────
  /// Brand gradient — filled buttons, active indicators, avatar rings.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep brand gradient — hero surfaces.
  static const LinearGradient deepGradient = LinearGradient(
    colors: [primary, primaryDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Barely-there warm wash over the canvas. Replaces the old blurred colour
  /// blobs, which only existed to give the removed blur something to sample.
  static const LinearGradient backdropGradient = LinearGradient(
    colors: [backgroundWarm, background, backgroundCool],
    stops: [0.0, 0.45, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Scrim gradient for text over imagery.
  static const LinearGradient imageScrim = LinearGradient(
    colors: [Color(0xC6000000), Color(0x00000000)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  /// Gold — premium / pro badges.
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD9A52A), Color(0xFFA9711A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Legacy aliases — kept so old call-sites compile. All resolve to brand red
  /// so no screen can reintroduce a retired palette.
  static const LinearGradient heroGradient = primaryGradient;
  static const LinearGradient storyGradient = primaryGradient;
  static const LinearGradient mintGradient = primaryGradient;
  static const LinearGradient tealGradient = primaryGradient;
  static const LinearGradient purpleGradient = deepGradient;
  static const LinearGradient cardGradient = LinearGradient(
    colors: [surface, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkCardGradient = cardGradient;

  /// Retired glass tokens, kept as flat equivalents so no call-site breaks
  /// while the components are migrated.
  static const LinearGradient glassSheen = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x00FFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient glassRim = glassSheen;
}
