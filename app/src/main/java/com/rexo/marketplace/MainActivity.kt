package com.rexo.marketplace

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.rexo.marketplace.navigation.MainScaffold
import com.rexo.marketplace.ui.theme.RexoMarketplaceTheme

/**
 * Main Activity - Entry point for Rexo Marketplace app
 *
 * Features:
 * - Edge-to-edge display
 * - Material 3 theming
 * - Splash screen support
 * - System bars transparency
 * - Navigation integration with auth-aware start destination
 * - Theme persistence via DataStore
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install splash screen before super.onCreate()
        installSplashScreen()

        super.onCreate(savedInstanceState)

        // Enable edge-to-edge display
        enableEdgeToEdge()

        setContent {
            val themeMode by RexoApplication.preferencesManager.themeMode
                .collectAsState(initial = "System")

            val darkTheme = when (themeMode) {
                "Dark" -> true
                "Light" -> false
                else -> isSystemInDarkTheme()
            }

            RexoMarketplaceTheme(darkTheme = darkTheme) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    // MainScaffold handles auth state check and navigation
                    MainScaffold()
                }
            }
        }
    }
}
