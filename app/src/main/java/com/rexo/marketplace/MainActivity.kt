package com.rexo.marketplace

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.rexo.marketplace.ui.theme.RexoMarketplaceTheme

/**
 * Main Activity for Rexo Marketplace
 * 
 * Features:
 * - Edge-to-edge display (Android 10+)
 * - Splash screen API (Android 12+)
 * - Jetpack Compose UI
 * - Material 3 Design
 */
class MainActivity : ComponentActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install splash screen before super.onCreate()
        installSplashScreen()
        
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display
        enableEdgeToEdge()
        
        setContent {
            RexoMarketplaceTheme {
                // Main app content
                RexoMarketplaceApp()
            }
        }
    }
}

/**
 * Main Composable for Rexo Marketplace
 * 
 * This is the root composable that will contain:
 * - Navigation setup
 * - Authentication state management
 * - Main screens
 * 
 * TODO: Implement full navigation and screens
 */
@Composable
fun RexoMarketplaceApp() {
    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        // Temporary welcome screen showing successful setup
        WelcomeScreen()
    }
}

/**
 * Temporary Welcome Screen
 * Shows that Kotlin conversion is complete
 */
@Composable
fun WelcomeScreen() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "🚀",
                style = MaterialTheme.typography.displayLarge
            )
            
            Text(
                text = "Rexo Marketplace",
                style = MaterialTheme.typography.displayMedium,
                color = MaterialTheme.colorScheme.primary
            )
            
            Text(
                text = "Native Kotlin Android",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "✅ Jetpack Compose",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Text(
                        text = "✅ Material 3 Design",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Text(
                        text = "✅ Room Database",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Text(
                        text = "✅ Supabase Ready",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Text(
                        text = "✅ Firebase FCM",
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "React → Kotlin Conversion Complete!\nReady to implement screens.",
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
        }
    }
}
