import 'package:flutter/material.dart';

/// Central color palette — **Instagram-inspired**.
///
/// Design direction: Instagram's clean, content-first aesthetic.
/// Pure white backgrounds, black text, blue accent, hairline borders,
/// no shadows, no gradients (except story rings). Minimal chrome.
///
/// **Dark tokens intentionally point to light equivalents** — the app is
/// light-only. Legacy call-sites that still reference dark* tokens continue
/// to compile.
class AppColors {
  AppColors._();

  // ── Brand — Instagram Blue ───────────────────────────────────────────────
  static const Color primary       = Color(0xFF0095F6); // IG action blue
  static const Color primaryLight  = Color(0xFF3897F0); // IG verified blue
  static const Color primaryDark   = Color(0xFF00376B); // Deep IG navy
  static const Color primaryDeep   = Color(0xFF002855);
  static const Color primaryBg     = Color(0xFFE0F2FE); // Blue tinted bg wash

  // ── Secondary (compatibility) ──────────────────────────────────────────────
  static const Color secondary     = Color(0xFF000000);

  // ── Instagram Accent Colors ────────────────────────────────────────────────
  static const Color accent        = primary;
  static const Color accentMint    = Color(0xFF6EE7B7);
  static const Color accentTeal    = Color(0xFF14B8A6);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentLime    = Color(0xFF84CC16);
  static const Color accentPurple  = Color(0xFF833AB4); // IG story purple
  static const Color accentPink    = Color(0xFFED4956); // IG like red
  static const Color accentGreen   = Color(0xFF00A400); // IG check green
  static const Color accentOrange  = Color(0xFFFCB045); // IG story orange
  static const Color accentIndigo  = Color(0xFF515BD4);
  static const Color accentAmber   = Color(0xFFFCAF45);
  static const Color accentBrown   = Color(0xFF92400E);
  static const Color accentCyan    = Color(0xFF3897F0);
  static const Color accentRed     = Color(0xFFFD1D1D); // IG story red
  static const Color neutral       = Color(0xFF737373); // IG secondary text

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00A400);
  static const Color warning = Color(0xFFFCAF45);
  static const Color error   = Color(0xFFED4956); // IG-style red
  static const Color info    = primary;

  // ── Instagram Light surfaces ───────────────────────────────────────────────
  /// App background — Sand Dune warm off-white for premium feel.
  static const Color background  = Color(0xFFF0EDE5); // SAND DUNE
  /// Card/cell surface — frosted glass (semi-transparent warm white).
  /// Used with BackdropFilter blur for the liquid-glass effect.
  static const Color surface     = Color(0xCCFFFFFF); // 80% white
  static const Color card        = Color(0xCCFFFFFF); // 80% white
  /// Secondary fill for inputs/chips — slightly warmer, also translucent.
  static const Color surfaceAlt  = Color(0xB3E8E5DD); // 70% warm sand
  /// Hairline separator — slightly warmer.
  static const Color border      = Color(0x66DBD8D0); // 40% warm hairline
  static const Color divider     = Color(0x66E8E5DD); // 40%
  static const Color separator   = Color(0x66DBD8D0); // 40%
  /// Gray family (mostly for compat).
  static const Color systemGray  = Color(0xFF8E8E8E);
  static const Color systemGray2 = Color(0xFFA8A8A8);
  static const Color systemGray3 = Color(0xFFC7C7C7);
  static const Color systemGray4 = Color(0xFFDBDBDB);
  static const Color systemGray5 = Color(0xFFEFEFEF);
  static const Color systemGray6 = Color(0xFFFAFAFA);

  // ── Legacy dark tokens (point to light — app is light-only) ──
  static const Color darkBackground    = background;
  static const Color darkSurface       = surface;
  static const Color darkCard          = surface;
  static const Color darkSurfaceAlt    = surfaceAlt;
  static const Color darkBorder        = border;
  static const Color darkDivider       = divider;
  static const Color darkTextPrimary   = Color(0xFF1A1A1A);
  static const Color darkTextSecondary = Color(0xFF737373);
  static const Color darkTextHint      = Color(0xFFA8A8A8);

  // ── Instagram Light text ───────────────────────────────────────────────────
  /// IG primary label — pure black.
  static const Color textPrimary   = Color(0xFF000000);
  /// IG secondary label — the classic IG gray.
  static const Color textSecondary = Color(0xFF737373);
  /// IG tertiary label / placeholder.
  static const Color textHint      = Color(0xFFA8A8A8);

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
  static const Color roleAdmin   = accentPink;
  static const Color verified    = primaryLight;

  // ── Shimmer ────────────────────────────────────────────────────────────────
  static const Color shimmerBase      = Color(0xFFEFEFEF);
  static const Color shimmerHighlight = Color(0xFFF8F8F8);
  static const Color darkShimmerBase      = shimmerBase;
  static const Color darkShimmerHighlight = shimmerHighlight;

  // ── Gradients ──────────────────────────────────────────────────────────────
  /// Solid blue "gradient" (flat — no gradient in IG buttons).
  /// Kept as a Gradient shape for compat with old call-sites that used it.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// The iconic Instagram story ring gradient (purple → red → orange).
  static const LinearGradient storyGradient = LinearGradient(
    colors: [
      Color(0xFF833AB4), // purple
      Color(0xFFFD1D1D), // red
      Color(0xFFFCB045), // orange
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hero gradient alias — use story gradient for hero surfaces.
  static const LinearGradient heroGradient = storyGradient;

  /// Card gradient — flat white (no actual gradient) for compat.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkCardGradient = cardGradient;

  /// Gold — for premium/pro badges.
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFCB045), Color(0xFFED4956)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Mint — kept for compat, uses IG's colors.
  static const LinearGradient mintGradient = storyGradient;
  static const LinearGradient tealGradient = storyGradient;
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF833AB4), Color(0xFF515BD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient deepGradient = LinearGradient(
    colors: [Color(0xFF00376B), Color(0xFF002855)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
