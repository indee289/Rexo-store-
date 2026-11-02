import 'package:flutter/material.dart';

/// Central color palette — **Campster "Liquid Glass" (light only)**.
///
/// Design direction: iOS 26 style liquid glass. A soft, slightly tinted
/// backdrop carries blurred colour blobs; every surface above it is a
/// translucent frosted pane with a 1px light rim and a specular top-edge
/// highlight. Brand red is the single accent.
///
/// Surface tokens are deliberately **semi-transparent** — they are designed to
/// be painted on top of a [BackdropFilter]. Never place them on top of an
/// opaque container or the glass effect is lost.
///
/// **Dark tokens intentionally point to light equivalents** — the app is
/// light-only by product decision. Legacy call-sites that still reference
/// `dark*` tokens continue to compile and render identically.
class AppColors {
  AppColors._();

  // ── Brand — Campster Red ─────────────────────────────────────────────────
  /// Primary brand red (logo / website).
  static const Color primary       = Color(0xFF8B1A1A);
  /// Gradient + specular highlight red.
  static const Color primaryLight  = Color(0xFFA52020);
  /// Pressed / deep states.
  static const Color primaryDark   = Color(0xFF5E1010);
  static const Color primaryDeep   = Color(0xFF3D0A0A);
  /// Red tinted wash for selected chips / subtle fills.
  static const Color primaryBg     = Color(0xFFF6E7E7);

  /// Brand red at low alpha — for glass tints that must stay translucent.
  static const Color primaryGlass  = Color(0x1F8B1A1A); // 12%
  static const Color primaryRim    = Color(0x668B1A1A); // 40%

  // ── Secondary (compatibility) ──────────────────────────────────────────────
  static const Color secondary     = Color(0xFF1A1416);

  // ── Accent family ──────────────────────────────────────────────────────────
  static const Color accent        = primary;
  static const Color accentMint    = Color(0xFF5EC9A8);
  static const Color accentTeal    = Color(0xFF13A396);
  static const Color accentEmerald = Color(0xFF0F9D6E);
  static const Color accentLime    = Color(0xFF7FB51F);
  static const Color accentPurple  = Color(0xFF7A3FA8);
  static const Color accentPink    = Color(0xFFD6336C);
  static const Color accentGreen   = Color(0xFF1C9E4B);
  static const Color accentOrange  = Color(0xFFE0821F);
  static const Color accentIndigo  = Color(0xFF4A52C4);
  static const Color accentAmber   = Color(0xFFE2A32A);
  static const Color accentBrown   = Color(0xFF8A5524);
  static const Color accentCyan    = Color(0xFF2196A8);
  static const Color accentRed     = primaryLight;
  static const Color neutral       = Color(0xFF6B6168);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF1C9E4B);
  static const Color warning = Color(0xFFE2A32A);
  static const Color error   = Color(0xFFC62828);
  static const Color info    = Color(0xFF2F6FB5);

  // ── Backdrop ───────────────────────────────────────────────────────────────
  /// Base backdrop the blurred colour blobs are painted on. Slightly deeper
  /// than white so the frosted panes above it read as glass.
  static const Color background  = Color(0xFFEFECEE);

  /// Secondary backdrop stop — warm, faintly red-tinted.
  static const Color backgroundWarm = Color(0xFFF6EFEC);
  /// Tertiary backdrop stop — cool, keeps the gradient from looking muddy.
  static const Color backgroundCool = Color(0xFFE9E9EF);

  // ── Glass surfaces (translucent — must sit over a BackdropFilter) ─────────
  /// Primary frosted pane (sheets, app bars, nav bar).
  static const Color surface     = Color(0x8CFFFFFF); // white @ 55%
  /// Card pane — a touch lighter so cards separate from sheets.
  static const Color card        = Color(0x7AFFFFFF); // white @ 48%
  /// Recessed fill for inputs / chips / track backgrounds.
  static const Color surfaceAlt  = Color(0x52FFFFFF); // white @ 32%

  /// Readable hairline separator. Deliberately a low-alpha *dark* value: a
  /// white rim is invisible where glass meets the light backdrop, so dividers
  /// and list separators use this instead.
  static const Color border      = Color(0x1F1A1416); // 12% ink
  static const Color divider     = Color(0x141A1416); // 8% ink
  static const Color separator   = Color(0x1F1A1416); // 12% ink

  /// Gray family (mostly for compat / disabled states).
  static const Color systemGray  = Color(0xFF8B8289);
  static const Color systemGray2 = Color(0xFFA39BA1);
  static const Color systemGray3 = Color(0xFFC2BBC0);
  static const Color systemGray4 = Color(0xFFD7D1D5);
  static const Color systemGray5 = Color(0xFFE8E4E7);
  static const Color systemGray6 = Color(0xFFF4F1F3);

  // ── Legacy dark tokens (point to light — app is light-only) ──
  static const Color darkBackground    = background;
  static const Color darkSurface       = surface;
  static const Color darkCard          = card;
  static const Color darkSurfaceAlt    = surfaceAlt;
  static const Color darkBorder        = border;
  static const Color darkDivider       = divider;
  static const Color darkTextPrimary   = textPrimary;
  static const Color darkTextSecondary = textSecondary;
  static const Color darkTextHint      = textHint;

  // ── Text (contrast-checked against the light glass panes) ────────────────
  /// Primary label — near-black ink. ~15:1 on the frosted pane.
  static const Color textPrimary   = Color(0xFF1A1416);
  /// Secondary label — meta, descriptions. ~5.2:1 on the frosted pane.
  static const Color textSecondary = Color(0xFF615861);
  /// Tertiary label / placeholder. ~3.1:1 — decorative or large text only.
  static const Color textHint      = Color(0xFF8E868D);
  /// Label used on top of filled brand-red surfaces.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

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
  static const Color roleAdmin   = accentIndigo;
  static const Color verified    = info;

  // ── Shimmer (tuned for the glass backdrop) ───────────────────────────────
  static const Color shimmerBase      = Color(0x33FFFFFF);
  static const Color shimmerHighlight = Color(0x80FFFFFF);
  static const Color darkShimmerBase      = shimmerBase;
  static const Color darkShimmerHighlight = shimmerHighlight;

  // ── Gradients ──────────────────────────────────────────────────────────────
  /// Brand red gradient — filled buttons, active indicators.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep red press / hero gradient.
  static const LinearGradient deepGradient = LinearGradient(
    colors: [primary, primaryDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Specular sheen laid over glass surfaces: a bright top edge fading out.
  static const LinearGradient glassSheen = LinearGradient(
    colors: [Color(0x59FFFFFF), Color(0x0DFFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.45, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Rim light that runs along the top edge of a glass pane.
  static const LinearGradient glassRim = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0xB3FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Ambient backdrop gradient painted behind every screen.
  static const LinearGradient backdropGradient = LinearGradient(
    colors: [backgroundWarm, background, backgroundCool],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hero gradient alias — brand red.
  static const LinearGradient heroGradient = primaryGradient;

  /// Card gradient — translucent white, top-lit. Safe to paint on glass.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0x99FFFFFF), Color(0x5CFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkCardGradient = cardGradient;

  /// Gold — premium / pro badges.
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE2A32A), Color(0xFFB8761A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Legacy aliases — kept so old call-sites compile. All resolve to brand red
  /// so no screen can reintroduce the retired blue/Instagram palette.
  static const LinearGradient storyGradient = primaryGradient;
  static const LinearGradient mintGradient = primaryGradient;
  static const LinearGradient tealGradient = primaryGradient;
  static const LinearGradient purpleGradient = deepGradient;
}
