package com.rexo.marketplace.ui.theme

import androidx.compose.ui.graphics.Color

// Rexo Brand Colors - Clean White Minimal Design
object RexoColors {
    // Primary Accent - Orange-Red for CTAs and active states
    val AccentOrange = Color(0xFFFF4500)
    val AccentOrangeDark = Color(0xFFE03E00)

    // Text Colors
    val TextPrimary = Color(0xFF1A1A1A)      // Black for headings and main text
    val TextSecondary = Color(0xFF6B7280)    // Gray for secondary text

    // Background & Surface
    val BackgroundLight = Color(0xFFFFFFFF)
    val BackgroundDark = Color(0xFF121212)
    val SurfaceLight = Color(0xFFFFFFFF)
    val SurfaceDark = Color(0xFF1E1E1E)

    // Card & Border
    val CardBorder = Color(0xFFF0F0F0)       // Light gray border for cards
    val CardBorderDark = Color(0xFF2C2C2C)

    // Status Colors
    val Success = Color(0xFF22C55E)          // Green for success states
    val SuccessLight = Color(0xFFF0FDF4)
    val Warning = Color(0xFFF59E0B)          // Amber for warnings
    val WarningLight = Color(0xFFFFFBEB)
    val Error = Color(0xFFEF4444)            // Red for errors
    val ErrorLight = Color(0xFFFEF2F2)

    // Neutral shades
    val Gray50 = Color(0xFFF9FAFB)
    val Gray100 = Color(0xFFF3F4F6)
    val Gray200 = Color(0xFFE5E7EB)
    val Gray300 = Color(0xFFD1D5DB)
    val Gray400 = Color(0xFF9CA3AF)
    val Gray500 = Color(0xFF6B7280)
    val Gray600 = Color(0xFF4B5563)
    val Gray700 = Color(0xFF374151)
    val Gray800 = Color(0xFF1F2937)
    val Gray900 = Color(0xFF111827)

    // Legacy compatibility - kept for GlassSurface component
    val GlassLight = Color(0xFFFFFFFF)
}

// Light Theme Colors - Clean white minimal design
val LightColorScheme = androidx.compose.material3.lightColorScheme(
    primary = RexoColors.AccentOrange,
    onPrimary = Color.White,
    primaryContainer = RexoColors.AccentOrange,
    onPrimaryContainer = Color.White,

    secondary = RexoColors.TextSecondary,
    onSecondary = Color.White,
    secondaryContainer = RexoColors.Gray100,
    onSecondaryContainer = RexoColors.TextPrimary,

    tertiary = RexoColors.Success,
    onTertiary = Color.White,

    error = RexoColors.Error,
    onError = Color.White,
    errorContainer = RexoColors.ErrorLight,
    onErrorContainer = RexoColors.Error,

    background = RexoColors.BackgroundLight,
    onBackground = RexoColors.TextPrimary,

    surface = RexoColors.SurfaceLight,
    onSurface = RexoColors.TextPrimary,
    surfaceVariant = RexoColors.Gray50,
    onSurfaceVariant = RexoColors.TextSecondary,

    outline = RexoColors.CardBorder,
    outlineVariant = RexoColors.Gray100,

    surfaceTint = RexoColors.AccentOrange,
    inverseSurface = RexoColors.Gray900,
    inverseOnSurface = Color.White,
)

// Dark Theme Colors
val DarkColorScheme = androidx.compose.material3.darkColorScheme(
    primary = RexoColors.AccentOrange,
    onPrimary = Color.White,
    primaryContainer = RexoColors.AccentOrangeDark,
    onPrimaryContainer = Color.White,

    secondary = RexoColors.Gray400,
    onSecondary = Color.White,
    secondaryContainer = RexoColors.Gray800,
    onSecondaryContainer = RexoColors.Gray100,

    tertiary = RexoColors.Success,
    onTertiary = Color.White,

    error = RexoColors.Error,
    onError = Color.White,
    errorContainer = RexoColors.Error,
    onErrorContainer = Color.White,

    background = RexoColors.BackgroundDark,
    onBackground = Color.White,

    surface = RexoColors.SurfaceDark,
    onSurface = Color.White,
    surfaceVariant = RexoColors.Gray800,
    onSurfaceVariant = RexoColors.Gray300,

    outline = RexoColors.CardBorderDark,
    outlineVariant = RexoColors.Gray700,

    surfaceTint = RexoColors.AccentOrange,
    inverseSurface = RexoColors.Gray50,
    inverseOnSurface = RexoColors.Gray900,
)
