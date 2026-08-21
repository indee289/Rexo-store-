package com.rexo.marketplace.ui.screens.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Settings Screen - App preferences and configuration
 * Features:
 * - Theme toggle (Light/Dark)
 * - Notification preferences
 * - Account settings
 * - About/Help
 * - Version info
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit = {}
) {
    var darkMode by remember { mutableStateOf(false) }
    var notificationsEnabled by remember { mutableStateOf(true) }
    var emailNotifications by remember { mutableStateOf(true) }
    var pushNotifications by remember { mutableStateOf(true) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Settings",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Appearance Section
            item {
                SectionHeader("Appearance")
            }
            
            item {
                SettingsSwitchItem(
                    icon = Icons.Outlined.DarkMode,
                    title = "Dark Mode",
                    subtitle = "Enable dark theme",
                    checked = darkMode,
                    onCheckedChange = { darkMode = it }
                )
            }
            
            // Notifications Section
            item {
                SectionHeader("Notifications")
            }
            
            item {
                SettingsSwitchItem(
                    icon = Icons.Outlined.Notifications,
                    title = "Push Notifications",
                    subtitle = "Receive notifications on your device",
                    checked = pushNotifications,
                    onCheckedChange = { pushNotifications = it }
                )
            }
            
            item {
                SettingsSwitchItem(
                    icon = Icons.Outlined.Email,
                    title = "Email Notifications",
                    subtitle = "Receive updates via email",
                    checked = emailNotifications,
                    onCheckedChange = { emailNotifications = it }
                )
            }
            
            // Account Section
            item {
                SectionHeader("Account")
            }
            
            item {
                SettingsItem(
                    icon = Icons.Outlined.Security,
                    title = "Privacy & Security",
                    subtitle = "Manage your privacy settings",
                    onClick = { /* TODO */ }
                )
            }
            
            item {
                SettingsItem(
                    icon = Icons.Outlined.Language,
                    title = "Language",
                    subtitle = "English (US)",
                    onClick = { /* TODO */ }
                )
            }
            
            item {
                SettingsItem(
                    icon = Icons.Outlined.Storage,
                    title = "Storage & Cache",
                    subtitle = "Manage app data",
                    onClick = { /* TODO */ }
                )
            }
            
            // Support Section
            item {
                SectionHeader("Support")
            }
            
            item {
                SettingsItem(
                    icon = Icons.Outlined.Help,
                    title = "Help Center",
                    subtitle = "Get help and support",
                    onClick = { /* TODO */ }
                )
            }
            
            item {
                SettingsItem(
                    icon = Icons.Outlined.Feedback,
                    title = "Send Feedback",
                    subtitle = "Share your thoughts",
                    onClick = { /* TODO */ }
                )
            }
            
            item {
                SettingsItem(
                    icon = Icons.Outlined.Policy,
                    title = "Terms & Privacy",
                    subtitle = "Read our policies",
                    onClick = { /* TODO */ }
                )
            }
            
            // About Section
            item {
                SectionHeader("About")
            }
            
            item {
                SettingsItem(
                    icon = Icons.Outlined.Info,
                    title = "App Version",
                    subtitle = "1.0.0 (Build 1)",
                    onClick = { /* TODO */ }
                )
            }
            
            // Danger Zone
            item {
                Spacer(modifier = Modifier.height(12.dp))
            }
            
            item {
                SettingsItem(
                    icon = Icons.Outlined.Delete,
                    title = "Delete Account",
                    subtitle = "Permanently delete your account",
                    onClick = { /* TODO */ },
                    textColor = Color(0xFFEF4444)
                )
            }
        }
    }
}

@Composable
fun SectionHeader(text: String) {
    Text(
        text = text,
        style = RexoTheme.typography.titleSmall,
        fontWeight = FontWeight.Bold,
        color = RexoTheme.colorScheme.primary,
        modifier = Modifier.padding(top = 12.dp, bottom = 4.dp)
    )
}

@Composable
fun SettingsItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
    textColor: Color = RexoTheme.colorScheme.onSurface
) {
    GlassSurface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    tint = textColor
                )
                
                Column {
                    Text(
                        text = title,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = textColor
                    )
                    Text(
                        text = subtitle,
                        style = RexoTheme.typography.bodySmall,
                        color = textColor.copy(alpha = 0.6f)
                    )
                }
            }
            
            Icon(
                imageVector = Icons.Outlined.ChevronRight,
                contentDescription = "Go",
                tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.4f)
            )
        }
    }
}

@Composable
fun SettingsSwitchItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    GlassSurface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    tint = RexoTheme.colorScheme.primary
                )
                
                Column {
                    Text(
                        text = title,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = subtitle,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            }
            
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange
            )
        }
    }
}
