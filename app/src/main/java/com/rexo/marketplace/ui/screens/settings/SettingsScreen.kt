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
import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.data.repository.AuthRepository
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import kotlinx.coroutines.launch

/**
 * Settings Screen - Full settings with all preferences
 *
 * Includes:
 * - Language selector (English, Hindi)
 * - Theme selector (System, Light, Dark)
 * - Security: Change password
 * - Notification preferences (push, email, campaign alerts)
 * - Privacy Policy navigation
 * - Terms of Service navigation
 * - Help & Support navigation
 * - App version info
 * - Logout with confirmation dialog
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit = {},
    onNavigateToPrivacyPolicy: () -> Unit = {},
    onNavigateToTermsOfService: () -> Unit = {},
    onNavigateToHelpSupport: () -> Unit = {},
    onSignOut: () -> Unit = {}
) {
    // Preferences state
    var selectedLanguage by remember { mutableStateOf("English") }
    var selectedTheme by remember { mutableStateOf("System") }
    var pushNotifications by remember { mutableStateOf(true) }
    var emailNotifications by remember { mutableStateOf(true) }
    var campaignAlerts by remember { mutableStateOf(true) }
    var showSignOutDialog by remember { mutableStateOf(false) }
    var showLanguageDialog by remember { mutableStateOf(false) }
    var showThemeDialog by remember { mutableStateOf(false) }
    var showPasswordDialog by remember { mutableStateOf(false) }
    var isSigningOut by remember { mutableStateOf(false) }
    var passwordResetSent by remember { mutableStateOf(false) }
    var passwordResetError by remember { mutableStateOf<String?>(null) }

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
            // General Section
            item {
                SettingsSectionHeader("General")
            }

            item {
                SettingsNavItem(
                    icon = Icons.Outlined.Language,
                    title = "Language",
                    subtitle = selectedLanguage,
                    onClick = { showLanguageDialog = true }
                )
            }

            item {
                SettingsNavItem(
                    icon = Icons.Outlined.Palette,
                    title = "Theme",
                    subtitle = selectedTheme,
                    onClick = { showThemeDialog = true }
                )
            }

            // Security Section
            item {
                SettingsSectionHeader("Security")
            }

            item {
                SettingsNavItem(
                    icon = Icons.Outlined.Lock,
                    title = "Change Password",
                    subtitle = if (passwordResetSent) "Reset email sent!" else "Update your password",
                    onClick = { showPasswordDialog = true }
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

            item {
                SettingsToggleItem(
                    icon = Icons.Outlined.Campaign,
                    title = "Campaign Alerts",
                    subtitle = "New campaign notifications",
                    checked = campaignAlerts,
                    onCheckedChange = { campaignAlerts = it }
                )
            }

            // Legal Section
            item {
                SettingsSectionHeader("Legal")
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
                    onClick = onNavigateToTermsOfService
                )
            }

            // Support Section
            item {
                SettingsSectionHeader("Support")
            }

            item {
                SettingsNavItem(
                    icon = Icons.Outlined.Help,
                    title = "Help & Support",
                    subtitle = "Get help and FAQs",
                    onClick = onNavigateToHelpSupport
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
                    subtitle = "1.0.0 (Build 1)",
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

            item {
                Spacer(modifier = Modifier.height(32.dp))
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

    // Language Selection Dialog
    if (showLanguageDialog) {
        AlertDialog(
            onDismissRequest = { showLanguageDialog = false },
            title = {
                Text(
                    text = "Select Language",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            },
            text = {
                Column {
                    listOf("English", "Hindi").forEach { language ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    selectedLanguage = language
                                    showLanguageDialog = false
                                }
                                .padding(vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            RadioButton(
                                selected = selectedLanguage == language,
                                onClick = {
                                    selectedLanguage = language
                                    showLanguageDialog = false
                                },
                                colors = RadioButtonDefaults.colors(
                                    selectedColor = RexoColors.AccentOrange
                                )
                            )
                            Text(
                                text = language,
                                style = RexoTheme.typography.bodyMedium,
                                color = RexoColors.TextPrimary
                            )
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showLanguageDialog = false }) {
                    Text("Cancel", color = RexoColors.TextSecondary)
                }
            }
        )
    }

    // Theme Selection Dialog
    if (showThemeDialog) {
        AlertDialog(
            onDismissRequest = { showThemeDialog = false },
            title = {
                Text(
                    text = "Select Theme",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            },
            text = {
                Column {
                    listOf("System", "Light", "Dark").forEach { theme ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    selectedTheme = theme
                                    showThemeDialog = false
                                }
                                .padding(vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            RadioButton(
                                selected = selectedTheme == theme,
                                onClick = {
                                    selectedTheme = theme
                                    showThemeDialog = false
                                },
                                colors = RadioButtonDefaults.colors(
                                    selectedColor = RexoColors.AccentOrange
                                )
                            )
                            Column {
                                Text(
                                    text = theme,
                                    style = RexoTheme.typography.bodyMedium,
                                    color = RexoColors.TextPrimary
                                )
                                Text(
                                    text = when (theme) {
                                        "System" -> "Follow device settings"
                                        "Light" -> "Always use light theme"
                                        "Dark" -> "Always use dark theme"
                                        else -> ""
                                    },
                                    style = RexoTheme.typography.bodySmall,
                                    color = RexoColors.TextSecondary
                                )
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showThemeDialog = false }) {
                    Text("Cancel", color = RexoColors.TextSecondary)
                }
            }
        )
    }

    // Change Password Dialog
    if (showPasswordDialog) {
        AlertDialog(
            onDismissRequest = {
                showPasswordDialog = false
                passwordResetError = null
            },
            title = {
                Text(
                    text = "Change Password",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = "We will send a password reset link to your registered email address.",
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoColors.TextSecondary
                    )
                    if (passwordResetError != null) {
                        Text(
                            text = passwordResetError!!,
                            style = RexoTheme.typography.bodySmall,
                            color = RexoColors.Error
                        )
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        scope.launch {
                            val email = SupabaseClient.auth.currentUserOrNull()?.email
                            if (email != null) {
                                val result = authRepository.sendPasswordResetEmail(email)
                                if (result.isSuccess) {
                                    passwordResetSent = true
                                    showPasswordDialog = false
                                    passwordResetError = null
                                } else {
                                    passwordResetError = "Failed to send reset email. Try again."
                                }
                            } else {
                                passwordResetError = "No email found for current user."
                            }
                        }
                    },
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = RexoColors.AccentOrange
                    )
                ) {
                    Text("Send Reset Link")
                }
            },
            dismissButton = {
                OutlinedButton(
                    onClick = {
                        showPasswordDialog = false
                        passwordResetError = null
                    },
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
