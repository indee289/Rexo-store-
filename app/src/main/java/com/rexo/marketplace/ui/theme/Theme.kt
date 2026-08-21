package com.rexo.marketplace.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import com.google.accompanist.systemuicontroller.rememberSystemUiController

/**
 * Rexo Marketplace Material 3 Theme
 * 
 * Features:
 * - Custom color palette based on Tailwind config
 * - Dynamic color support (Material You on Android 12+)
 * - Dark mode support
 * - Edge-to-edge display
 * - Glass/blur effects support
 */
@Composable
fun RexoMarketplaceTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        // Dynamic color is available on Android 12+ with Material You
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        // Use custom Rexo colors
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    
    // System UI Controller for status bar and navigation bar
    val systemUiController = rememberSystemUiController()
    val view = LocalView.current
    
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            
            // Enable edge-to-edge display
            WindowCompat.setDecorFitsSystemWindows(window, false)
            
            // Set status bar color (transparent for edge-to-edge)
            window.statusBarColor = Color.Transparent.toArgb()
            window.navigationBarColor = Color.Transparent.toArgb()
            
            // Set status bar icons color (dark icons on light theme, light on dark)
            systemUiController.setSystemBarsColor(
                color = Color.Transparent,
                darkIcons = !darkTheme
            )
        }
    }
    
    MaterialTheme(
        colorScheme = colorScheme,
        typography = RexoTypography,
        shapes = RexoShapes,
        content = content
    )
}
