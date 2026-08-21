package com.rexo.marketplace.ui.screens.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rexo.marketplace.data.repository.CreatorProfileDto
import com.rexo.marketplace.data.repository.UserDto
import com.rexo.marketplace.data.repository.WalletDto
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.ProfileState
import com.rexo.marketplace.ui.viewmodel.ProfileViewModel

/**
 * Profile Screen - Clean reference design
 * Shows user profile data from Supabase with settings list.
 * No hardcoded data - all from real Supabase queries.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    onNavigateBack: () -> Unit = {},
    onNavigateToSettings: () -> Unit = {},
    onNavigateToAdmin: () -> Unit = {},
    onSignOut: () -> Unit = {},
    isAdmin: Boolean = false,
    profileViewModel: ProfileViewModel? = null
) {
    val viewModel = profileViewModel ?: viewModel()
    val profileState by viewModel.profileState.collectAsState()
    val signedOut by viewModel.signedOut.collectAsState()

    // Navigate to auth on sign out
    LaunchedEffect(signedOut) {
        if (signedOut) {
            onSignOut()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Profile",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White
                )
            )
        },
        containerColor = Color.White
    ) { paddingValues ->
        when (val state = profileState) {
            is ProfileState.Loading -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        color = RexoColors.AccentOrange
                    )
                }
            }

            is ProfileState.Error -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.ErrorOutline,
                            contentDescription = "Error",
                            modifier = Modifier.size(48.dp),
                            tint = RexoColors.Error
                        )
                        Text(
                            text = state.message,
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextSecondary,
                            textAlign = TextAlign.Center
                        )
                        OutlinedButton(
                            onClick = { viewModel.loadProfile() },
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text("Retry")
                        }
                    }
                }
            }

            is ProfileState.Empty -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Person,
                            contentDescription = "No profile",
                            modifier = Modifier.size(48.dp),
                            tint = RexoColors.Gray400
                        )
                        Text(
                            text = "Profile not found",
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextSecondary
                        )
                    }
                }
            }

            is ProfileState.Loaded -> {
                ProfileContent(
                    user = state.user,
                    creatorProfile = state.creatorProfile,
                    wallet = state.wallet,
                    isAdmin = isAdmin,
                    onNavigateToAdmin = onNavigateToAdmin,
                    onSignOut = { viewModel.signOut() },
                    modifier = Modifier.padding(paddingValues)
                )
            }
        }
    }
}

@Composable
private fun ProfileContent(
    user: UserDto,
    creatorProfile: CreatorProfileDto?,
    wallet: WalletDto?,
    isAdmin: Boolean,
    onNavigateToAdmin: () -> Unit,
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 100.dp)
    ) {
        // Profile Avatar Section
        item {
            ProfileAvatarSection(user = user)
        }

        // Stats Row
        item {
            StatsRow(
                wallet = wallet,
                creatorProfile = creatorProfile
            )
        }

        // Connected Accounts Button
        item {
            ConnectedAccountsButton(
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 16.dp)
            )
        }

        // Settings List
        item {
            SettingsList(
                isAdmin = isAdmin,
                onNavigateToAdmin = onNavigateToAdmin,
                onSignOut = onSignOut
            )
        }
    }
}

@Composable
private fun ProfileAvatarSection(user: UserDto) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 24.dp, bottom = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Avatar with edit icon
        Box(contentAlignment = Alignment.BottomEnd) {
            // Avatar circle
            Surface(
                modifier = Modifier.size(100.dp),
                shape = CircleShape,
                color = RexoColors.Gray100
            ) {
                Box(contentAlignment = Alignment.Center) {
                    if (user.avatar.isNullOrBlank()) {
                        // Show initials
                        Text(
                            text = getInitials(user.name),
                            style = RexoTheme.typography.headlineMedium,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.TextPrimary
                        )
                    } else {
                        // Placeholder for AsyncImage - show initials as fallback
                        Text(
                            text = getInitials(user.name),
                            style = RexoTheme.typography.headlineMedium,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.TextPrimary
                        )
                    }
                }
            }

            // Edit pencil icon overlay
            Surface(
                modifier = Modifier.size(28.dp),
                shape = CircleShape,
                color = RexoColors.TextPrimary
            ) {
                Icon(
                    imageVector = Icons.Filled.Edit,
                    contentDescription = "Edit profile",
                    modifier = Modifier.padding(6.dp),
                    tint = Color.White
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Display name
        Text(
            text = user.name,
            style = RexoTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = RexoColors.TextPrimary
        )

        // Handle
        Text(
            text = if (user.handle != null) "@${user.handle}" else "@${user.email.substringBefore("@")}",
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary
        )

        Spacer(modifier = Modifier.height(4.dp))

        // Member since
        Text(
            text = "Member since ${formatMemberDate(user.created_at)}",
            style = RexoTheme.typography.bodySmall,
            color = RexoColors.Gray400
        )
    }
}

@Composable
private fun StatsRow(
    wallet: WalletDto?,
    creatorProfile: CreatorProfileDto?
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        StatColumn(
            value = formatCurrency(wallet?.total_earnings ?: 0.0),
            label = "Money earned"
        )
        StatDivider()
        StatColumn(
            value = (creatorProfile?.completed_campaigns ?: 0).toString(),
            label = "Total campaigns"
        )
        StatDivider()
        StatColumn(
            value = "${creatorProfile?.engagement_rate ?: 0.0}%",
            label = "Engagement"
        )
    }
}

@Composable
private fun StatColumn(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            style = RexoTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = RexoColors.TextPrimary
        )
        Text(
            text = label,
            style = RexoTheme.typography.bodySmall,
            color = RexoColors.TextSecondary
        )
    }
}

@Composable
private fun StatDivider() {
    Box(
        modifier = Modifier
            .width(1.dp)
            .height(36.dp)
            .background(RexoColors.Gray200)
    )
}

@Composable
private fun ConnectedAccountsButton(modifier: Modifier = Modifier) {
    Button(
        onClick = { /* TODO: Navigate to connected accounts */ },
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = RexoColors.TextPrimary,
            contentColor = Color.White
        ),
        contentPadding = PaddingValues(vertical = 14.dp)
    ) {
        Text(
            text = "Connected accounts",
            style = RexoTheme.typography.bodyLarge,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
private fun SettingsList(
    isAdmin: Boolean,
    onNavigateToAdmin: () -> Unit,
    onSignOut: () -> Unit
) {
    Column(
        modifier = Modifier.padding(top = 8.dp)
    ) {
        // Admin Panel - Only visible for admin role users
        if (isAdmin) {
            SettingsItem(
                icon = Icons.Outlined.AdminPanelSettings,
                label = "Admin Panel",
                onClick = onNavigateToAdmin
            )
        }

        // Referrals
        SettingsItem(
            icon = Icons.Outlined.CardGiftcard,
            label = "Referrals",
            badge = "Earn 10%",
            onClick = { }
        )

        // Language
        SettingsItem(
            icon = Icons.Outlined.Language,
            label = "Language",
            trailingText = "English",
            onClick = { }
        )

        // Theme
        SettingsItem(
            icon = Icons.Outlined.Palette,
            label = "Theme",
            trailingText = "System",
            onClick = { }
        )

        // Notifications
        SettingsItem(
            icon = Icons.Outlined.Notifications,
            label = "Notifications",
            onClick = { }
        )

        // FAQ
        SettingsItem(
            icon = Icons.Outlined.HelpOutline,
            label = "FAQ",
            onClick = { }
        )

        // Resources
        SettingsItem(
            icon = Icons.Outlined.MenuBook,
            label = "Resources",
            onClick = { }
        )

        // General Campaign Rules
        SettingsItem(
            icon = Icons.Outlined.Description,
            label = "General Campaign Rules",
            showExternalLink = true,
            onClick = { }
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Logout
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onSignOut)
                .padding(horizontal = 20.dp, vertical = 14.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Icon(
                    imageVector = Icons.Outlined.Logout,
                    contentDescription = "Logout",
                    tint = RexoColors.Error,
                    modifier = Modifier.size(22.dp)
                )
                Text(
                    text = "Logout",
                    style = RexoTheme.typography.bodyLarge,
                    color = RexoColors.Error,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

@Composable
private fun SettingsItem(
    icon: ImageVector,
    label: String,
    trailingText: String? = null,
    badge: String? = null,
    showExternalLink: Boolean = false,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = RexoColors.TextPrimary,
            modifier = Modifier.size(22.dp)
        )

        Spacer(modifier = Modifier.width(12.dp))

        Text(
            text = label,
            style = RexoTheme.typography.bodyLarge,
            color = RexoColors.TextPrimary,
            modifier = Modifier.weight(1f)
        )

        // Badge (e.g., "Earn 10%")
        if (badge != null) {
            Surface(
                shape = RoundedCornerShape(6.dp),
                color = RexoColors.AccentOrange.copy(alpha = 0.1f)
            ) {
                Text(
                    text = badge,
                    style = RexoTheme.typography.labelSmall,
                    color = RexoColors.AccentOrange,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                )
            }
            Spacer(modifier = Modifier.width(8.dp))
        }

        // Trailing text (e.g., "English")
        if (trailingText != null) {
            Text(
                text = trailingText,
                style = RexoTheme.typography.bodyMedium,
                color = RexoColors.Gray400
            )
            Spacer(modifier = Modifier.width(8.dp))
        }

        // Right arrow or external link icon
        Icon(
            imageVector = if (showExternalLink) Icons.Outlined.OpenInNew else Icons.Outlined.ChevronRight,
            contentDescription = "Navigate",
            tint = RexoColors.Gray400,
            modifier = Modifier.size(20.dp)
        )
    }
}

/**
 * Get initials from a name (first letter of first and last name).
 */
private fun getInitials(name: String): String {
    val parts = name.trim().split(" ")
    return when {
        parts.size >= 2 -> "${parts.first().firstOrNull() ?: ""}${parts.last().firstOrNull() ?: ""}".uppercase()
        parts.isNotEmpty() -> (parts.first().firstOrNull()?.toString() ?: "?").uppercase()
        else -> "?"
    }
}

/**
 * Format created_at timestamp to a readable date (e.g., "Jan 2024").
 */
private fun formatMemberDate(createdAt: String): String {
    if (createdAt.isBlank()) return "Unknown"
    return try {
        // createdAt format from Supabase: "2024-01-15T10:30:00+00:00"
        val parts = createdAt.split("-")
        if (parts.size >= 2) {
            val year = parts[0]
            val month = when (parts[1]) {
                "01" -> "Jan"
                "02" -> "Feb"
                "03" -> "Mar"
                "04" -> "Apr"
                "05" -> "May"
                "06" -> "Jun"
                "07" -> "Jul"
                "08" -> "Aug"
                "09" -> "Sep"
                "10" -> "Oct"
                "11" -> "Nov"
                "12" -> "Dec"
                else -> parts[1]
            }
            "$month $year"
        } else {
            createdAt.take(10)
        }
    } catch (e: Exception) {
        "Unknown"
    }
}

/**
 * Format currency value (e.g., 15000.0 -> "15,000").
 */
private fun formatCurrency(amount: Double): String {
    return when {
        amount >= 1_000_000 -> String.format("%.1fM", amount / 1_000_000)
        amount >= 1_000 -> String.format("%,.0f", amount)
        else -> String.format("%.0f", amount)
    }
}
