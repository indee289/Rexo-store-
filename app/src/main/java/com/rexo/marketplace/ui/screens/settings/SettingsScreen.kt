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
import com.rexo.marketplace.data.repository.AuthRepository
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import kotlinx.coroutines.launch

/**
 * Settings Screen - Premium clean white design
 *
 * Features:
 * - Appearance toggle (dark mode)
 * - Notification preferences
 * - About section with app version
 * - Privacy Policy link
 * - Help center
 * - Sign Out with confirmation
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit = {},
    onNavigateToPrivacyPolicy: () -> Unit = {},
    onSignOut: () -> Unit = {}
) {
    var darkMode by remember { mutableStateOf(false) }
    var pushNotifications by remember { mutableStateOf(true) }
    var emailNotifications by remember { mutableStateOf(true) }
    var showSignOutDialog by remember { mutableStateOf(false) }
    var isSigningOut by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()
    val authRepository = remember { AuthRepository() }

    Scaffold(
        containerColor = Color.White,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Settings",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            Icons.Outlined.ArrowBack,
                            contentDescription = "Back",
                            tint = RexoColors.TextPrimary
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(horizontal = 20.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            // Appearance Section
            item {
                SettingsSectionHeader("Appearance")
            }

            item {
                SettingsToggleItem(
                    icon = Icons.Outlined.DarkMode,
                    title = "Dark Mode",
                    subtitle = "Switch to dark theme",
                    checked = darkMode,
                    onCheckedChange = { darkMode = it }
                )
            }

            // Notifications Section
            item {
                SettingsSectionHeader("Notifications")
            }

            item {
                SettingsToggleItem(
                    icon = Icons.Outlined.Notifications,
                    title = "Push Notifications",
                    subtitle = "Receive push notifications",
                    checked = pushNotifications,
                    onCheckedChange = { pushNotifications = it }
                )
            }

            item {
                SettingsToggleItem(
                    icon = Icons.Outlined.Email,
                    title = "Email Notifications",
                    subtitle = "Receive updates via email",
                    checked = emailNotifications,
                    onCheckedChange = { emailNotifications = it }
                )
            }

            // About Section
            item {
                SettingsSectionHeader("About")
            }

            item {
                SettingsNavItem(
                    icon = Icons.Outlined.Info,
                    title = "App Version",
                    subtitle = "1.0.0",
                    onClick = { }
                )
            }

            item {
                SettingsNavItem(
                    icon = Icons.Outlined.Policy,
                    title = "Privacy Policy",
                    subtitle = "Read our privacy policy",
                    onClick = onNavigateToPrivacyPolicy
                )
            }

            item {
                SettingsNavItem(
                    icon = Icons.Outlined.Description,
                    title = "Terms of Service",
                    subtitle = "Read our terms",
                    onClick = { }
                )
            }

            item {
                SettingsNavItem(
                    icon = Icons.Outlined.Help,
                    title = "Help Center",
                    subtitle = "Get help and support",
                    onClick = { }
                )
            }

            // Account Section
            item {
                SettingsSectionHeader("Account")
            }

            item {
                SettingsNavItem(
                    icon = Icons.Outlined.Logout,
                    title = "Sign Out",
                    subtitle = "Sign out of your account",
                    onClick = { showSignOutDialog = true },
                    textColor = RexoColors.Error
                )
            }
        }
    }

    // Sign Out Confirmation Dialog
    if (showSignOutDialog) {
        AlertDialog(
            onDismissRequest = { showSignOutDialog = false },
            title = {
                Text(
                    text = "Sign Out",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            },
            text = {
                Text(
                    text = "Are you sure you want to sign out?",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoColors.TextSecondary
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        isSigningOut = true
                        scope.launch {
                            authRepository.signOut()
                            isSigningOut = false
                            showSignOutDialog = false
                            onSignOut()
                        }
                    },
                    enabled = !isSigningOut,
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = RexoColors.Error
                    )
                ) {
                    if (isSigningOut) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = Color.White,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text("Sign Out")
                    }
                }
            },
            dismissButton = {
                OutlinedButton(
                    onClick = { showSignOutDialog = false },
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun SettingsSectionHeader(text: String) {
    Text(
        text = text,
        style = RexoTheme.typography.titleSmall,
        fontWeight = FontWeight.Bold,
        color = RexoColors.AccentOrange,
        modifier = Modifier.padding(top = 16.dp, bottom = 8.dp)
    )
}

@Composable
private fun SettingsNavItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
    textColor: Color = RexoColors.TextPrimary
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        color = Color.White
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 14.dp),
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
                    tint = textColor,
                    modifier = Modifier.size(24.dp)
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
                tint = RexoColors.Gray400,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun SettingsToggleItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 14.dp),
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
                    tint = RexoColors.AccentOrange,
                    modifier = Modifier.size(24.dp)
                )

                Column {
                    Text(
                        text = title,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.TextPrimary
                    )
                    Text(
                        text = subtitle,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                }
            }

            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange,
                colors = SwitchDefaults.colors(
                    checkedThumbColor = Color.White,
                    checkedTrackColor = RexoColors.AccentOrange,
                    uncheckedThumbColor = Color.White,
                    uncheckedTrackColor = RexoColors.Gray300
                )
            )
        }
    }
}
