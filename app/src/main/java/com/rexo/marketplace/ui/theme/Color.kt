package com.rexo.marketplace.ui.theme

import androidx.compose.ui.graphics.Color

// Rexo Brand Colors - Based on React app's Tailwind config
object RexoColors {
    // Primary Brand Colors
    val Indigo600 = Color(0xFF4F46E5)
    val Indigo700 = Color(0xFF4338CA)
    val Rose500 = Color(0xFFF43F5E)
    val Rose600 = Color(0xFFE11D48)
    
    // Slate (Main UI Colors)
    val Slate50 = Color(0xFFF8FAFC)
    val Slate100 = Color(0xFFF1F5F9)
    val Slate200 = Color(0xFFE2E8F0)
    val Slate300 = Color(0xFFCBD5E1)
    val Slate400 = Color(0xFF94A3B8)
    val Slate500 = Color(0xFF64748B)
    val Slate600 = Color(0xFF475569)
    val Slate700 = Color(0xFF334155)
    val Slate800 = Color(0xFF1E293B)
    val Slate900 = Color(0xFF0F172A)
    val Slate950 = Color(0xFF020617)
    
    // Emerald (Success/Money)
    val Emerald50 = Color(0xFFF0FDF4)
    val Emerald100 = Color(0xFFDCFCE7)
    val Emerald400 = Color(0xFF4ADE80)
    val Emerald500 = Color(0xFF22C55E)
    val Emerald600 = Color(0xFF16A34A)
    val Emerald700 = Color(0xFF15803D)
    
    // Amber (Warning/Pending)
    val Amber50 = Color(0xFFFFFBEB)
    val Amber100 = Color(0xFFFEF3C7)
    val Amber500 = Color(0xFFF59E0B)
    val Amber600 = Color(0xFFD97706)
    
    // Red/Rose (Error/Danger)
    val Red50 = Color(0xFFFEF2F2)
    val Red100 = Color(0xFFFEE2E2)
    val Red500 = Color(0xFFEF4444)
    val Red600 = Color(0xFFDC2626)
    
    // Purple (Premium Features)
    val Purple50 = Color(0xFFFAF5FF)
    val Purple500 = Color(0xFFA855F7)
    val Purple600 = Color(0xFF9333EA)
    
    // Background Colors
    val BackgroundLight = Color(0xFFF4F6F8)
    val BackgroundDark = Slate950
    
    // Surface Colors
    val SurfaceLight = Color(0xFFFFFFFF)
    val SurfaceDark = Slate900
    
    // Glass Effect Colors (with transparency)
    val GlassLight = Color(0xCCFFFFFF) // 80% white
    val GlassDark = Color(0xCC1E293B)  // 80% slate-800
}

// Light Theme Colors
val LightColorScheme = androidx.compose.material3.lightColorScheme(
    primary = RexoColors.Indigo600,
    onPrimary = Color.White,
    primaryContainer = RexoColors.Indigo700,
    onPrimaryContainer = Color.White,
    
    secondary = RexoColors.Rose500,
    onSecondary = Color.White,
    secondaryContainer = RexoColors.Rose600,
    onSecondaryContainer = Color.White,
    
    tertiary = RexoColors.Emerald600,
    onTertiary = Color.White,
    
    error = RexoColors.Red600,
    onError = Color.White,
    errorContainer = RexoColors.Red50,
    onErrorContainer = RexoColors.Red600,
    
    background = RexoColors.BackgroundLight,
    onBackground = RexoColors.Slate900,
    
    surface = RexoColors.SurfaceLight,
    onSurface = RexoColors.Slate900,
    surfaceVariant = RexoColors.Slate50,
    onSurfaceVariant = RexoColors.Slate700,
    
    outline = RexoColors.Slate200,
    outlineVariant = RexoColors.Slate100,
    
    surfaceTint = RexoColors.Indigo600,
    inverseSurface = RexoColors.Slate900,
    inverseOnSurface = RexoColors.Slate50,
)

// Dark Theme Colors
val DarkColorScheme = androidx.compose.material3.darkColorScheme(
    primary = RexoColors.Indigo600,
    onPrimary = Color.White,
    primaryContainer = RexoColors.Indigo700,
    onPrimaryContainer = Color.White,
    
    secondary = RexoColors.Rose500,
    onSecondary = Color.White,
    secondaryContainer = RexoColors.Rose600,
    onSecondaryContainer = Color.White,
    
    tertiary = RexoColors.Emerald500,
    onTertiary = Color.White,
    
    error = RexoColors.Red500,
    onError = Color.White,
    errorContainer = RexoColors.Red600,
    onErrorContainer = Color.White,
    
    background = RexoColors.BackgroundDark,
    onBackground = RexoColors.Slate100,
    
    surface = RexoColors.SurfaceDark,
    onSurface = RexoColors.Slate100,
    surfaceVariant = RexoColors.Slate800,
    onSurfaceVariant = RexoColors.Slate300,
    
    outline = RexoColors.Slate800,
    outlineVariant = RexoColors.Slate700,
    
    surfaceTint = RexoColors.Indigo600,
    inverseSurface = RexoColors.Slate50,
    inverseOnSurface = RexoColors.Slate900,
)
