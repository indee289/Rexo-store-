package com.rexo.marketplace.ui.screens.profile

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.ui.draw.clip
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
 * Profile Screen - Full-featured profile page
 * Shows user profile data from Supabase with:
 * - Profile header (avatar, name, handle, role badge, edit button)
 * - Stats row (earnings, campaigns, rating)
 * - Connected Accounts (Instagram, YouTube from creator_profiles)
 * - KYC Status (verification badge)
 * - Media Kit link
 * - Settings items (Language, Theme, Notifications, Privacy, Help, Logout)
 * All data from Supabase (users + creator_profiles tables).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    onNavigateBack: () -> Unit = {},
    onNavigateToSettings: () -> Unit = {},
    onNavigateToAdmin: () -> Unit = {},
    onNavigateToPrivacyPolicy: () -> Unit = {},
    onNavigateToWallet: () -> Unit = {},
    onNavigateToNotifications: () -> Unit = {},
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
                actions = {
                    IconButton(onClick = onNavigateToWallet) {
                        Icon(
                            Icons.Outlined.AccountBalanceWallet,
                            contentDescription = "Wallet",
                            tint = RexoColors.TextPrimary
                        )
                    }
                    IconButton(onClick = onNavigateToNotifications) {
                        Icon(
                            Icons.Outlined.Notifications,
                            contentDescription = "Notifications",
                            tint = RexoColors.TextPrimary
                        )
                    }
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
                    onNavigateToPrivacyPolicy = onNavigateToPrivacyPolicy,
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
    onNavigateToPrivacyPolicy: () -> Unit,
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 100.dp)
    ) {
        // Profile Avatar Section with role badge and edit button
        item {
            ProfileAvatarSection(user = user)
        }

        // Stats Row: Earnings, Campaigns, Rating
        item {
            StatsRow(
                wallet = wallet,
                creatorProfile = creatorProfile
            )
        }

        // Connected Accounts Section
        item {
            ConnectedAccountsSection(
                creatorProfile = creatorProfile,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
            )
        }

        // KYC Status Section
        item {
            KycStatusSection(
                isVerified = user.is_verified,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )
        }

        // Media Kit Section
        item {
            MediaKitSection(
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )
        }

        // Divider before settings
        item {
            HorizontalDivider(
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
                color = RexoColors.CardBorder
            )
        }

        // Settings List
        item {
            SettingsList(
                isAdmin = isAdmin,
                onNavigateToAdmin = onNavigateToAdmin,
                onNavigateToPrivacyPolicy = onNavigateToPrivacyPolicy,
                onSignOut = onSignOut
            )
        }
    }
}

@Composable
private fun ProfileAvatarSection(user: UserDto) {
    val displayName = user.name ?: user.email.substringBefore("@")

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
                    Text(
                        text = getInitials(displayName),
                        style = RexoTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
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
            text = displayName,
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

        Spacer(modifier = Modifier.height(6.dp))

        // Role badge
        Surface(
            shape = RoundedCornerShape(8.dp),
            color = when (user.role) {
                "admin" -> RexoColors.AccentOrange.copy(alpha = 0.1f)
                "brand" -> Color(0xFF6366F1).copy(alpha = 0.1f)
                else -> RexoColors.Success.copy(alpha = 0.1f)
            }
        ) {
            Text(
                text = user.role.replaceFirstChar { it.uppercase() },
                style = RexoTheme.typography.labelMedium,
                fontWeight = FontWeight.SemiBold,
                color = when (user.role) {
                    "admin" -> RexoColors.AccentOrange
                    "brand" -> Color(0xFF6366F1)
                    else -> RexoColors.Success
                },
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp)
            )
        }

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
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 8.dp),
        shape = RoundedCornerShape(16.dp),
        color = Color.White,
        shadowElevation = 1.dp,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 20.dp, horizontal = 16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            StatColumn(
                value = "\u20B9${formatCurrency(wallet?.total_earnings ?: 0.0)}",
                label = "Total Earnings"
            )
            StatDivider()
            StatColumn(
                value = (creatorProfile?.completed_campaigns ?: 0).toString(),
                label = "Campaigns"
            )
            StatDivider()
            StatColumn(
                value = "${creatorProfile?.rating ?: 0.0}",
                label = "Rating"
            )
        }
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
        Spacer(modifier = Modifier.height(2.dp))
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
private fun ConnectedAccountsSection(
    creatorProfile: CreatorProfileDto?,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        color = Color.White,
        shadowElevation = 1.dp,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Connected Accounts",
                style = RexoTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Instagram
            SocialAccountRow(
                icon = Icons.Outlined.CameraAlt,
                platform = "Instagram",
                handle = creatorProfile?.instagram_handle,
                color = Color(0xFFE4405F)
            )

            Spacer(modifier = Modifier.height(10.dp))

            // YouTube
            SocialAccountRow(
                icon = Icons.Outlined.PlayCircle,
                platform = "YouTube",
                handle = creatorProfile?.youtube_channel,
                color = Color(0xFFFF0000)
            )

            // Follower stats if available
            if (creatorProfile != null && creatorProfile.followers > 0) {
                Spacer(modifier = Modifier.height(12.dp))
                HorizontalDivider(color = RexoColors.CardBorder)
                Spacer(modifier = Modifier.height(12.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text(
                            text = formatFollowerCount(creatorProfile.followers),
                            style = RexoTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.TextPrimary
                        )
                        Text(
                            text = "Followers",
                            style = RexoTheme.typography.bodySmall,
                            color = RexoColors.TextSecondary
                        )
                    }
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = "${creatorProfile.engagement_rate}%",
                            style = RexoTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.Success
                        )
                        Text(
                            text = "Engagement Rate",
                            style = RexoTheme.typography.bodySmall,
                            color = RexoColors.TextSecondary
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SocialAccountRow(
    icon: ImageVector,
    platform: String,
    handle: String?,
    color: Color
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            shape = CircleShape,
            color = color.copy(alpha = 0.1f),
            modifier = Modifier.size(36.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = platform,
                modifier = Modifier.padding(8.dp),
                tint = color
            )
        }

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = platform,
                style = RexoTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = RexoColors.TextPrimary
            )
            Text(
                text = if (handle.isNullOrBlank()) "Not connected" else handle,
                style = RexoTheme.typography.bodySmall,
                color = if (handle.isNullOrBlank()) RexoColors.Gray400 else RexoColors.TextSecondary
            )
        }

        if (handle.isNullOrBlank()) {
            Surface(
                shape = RoundedCornerShape(8.dp),
                color = RexoColors.AccentOrange.copy(alpha = 0.1f)
            ) {
                Text(
                    text = "Connect",
                    style = RexoTheme.typography.labelSmall,
                    color = RexoColors.AccentOrange,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                )
            }
        } else {
            Icon(
                imageVector = Icons.Filled.CheckCircle,
                contentDescription = "Connected",
                tint = RexoColors.Success,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun KycStatusSection(
    isVerified: Boolean,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        color = if (isVerified) RexoColors.Success.copy(alpha = 0.05f) else RexoColors.Warning.copy(alpha = 0.05f),
        border = BorderStroke(
            1.dp,
            if (isVerified) RexoColors.Success.copy(alpha = 0.2f) else RexoColors.Warning.copy(alpha = 0.2f)
        )
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = CircleShape,
                color = if (isVerified) RexoColors.Success.copy(alpha = 0.1f) else RexoColors.Warning.copy(alpha = 0.1f),
                modifier = Modifier.size(40.dp)
            ) {
                Icon(
                    imageVector = if (isVerified) Icons.Filled.VerifiedUser else Icons.Outlined.Shield,
                    contentDescription = "KYC Status",
                    modifier = Modifier.padding(8.dp),
                    tint = if (isVerified) RexoColors.Success else RexoColors.Warning
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "KYC Status",
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = RexoColors.TextPrimary
                )
                Text(
                    text = if (isVerified) "Verified" else "Pending verification",
                    style = RexoTheme.typography.bodySmall,
                    color = if (isVerified) RexoColors.Success else RexoColors.Warning
                )
            }

            Surface(
                shape = RoundedCornerShape(8.dp),
                color = if (isVerified) RexoColors.Success.copy(alpha = 0.1f) else RexoColors.Warning.copy(alpha = 0.1f)
            ) {
                Text(
                    text = if (isVerified) "Verified" else "Pending",
                    style = RexoTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isVerified) RexoColors.Success else RexoColors.Warning,
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                )
            }
        }
    }
}

@Composable
private fun MediaKitSection(
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .clickable { /* TODO: Generate/share media kit */ },
        shape = RoundedCornerShape(16.dp),
        color = RexoColors.TextPrimary
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = CircleShape,
                color = Color.White.copy(alpha = 0.15f),
                modifier = Modifier.size(40.dp)
            ) {
                Icon(
                    imageVector = Icons.Outlined.Description,
                    contentDescription = "Media Kit",
                    modifier = Modifier.padding(8.dp),
                    tint = Color.White
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Media Kit",
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White
                )
                Text(
                    text = "Generate and share your media kit",
                    style = RexoTheme.typography.bodySmall,
                    color = Color.White.copy(alpha = 0.7f)
                )
            }

            Icon(
                imageVector = Icons.Outlined.Share,
                contentDescription = "Share",
                tint = Color.White.copy(alpha = 0.7f),
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun SettingsList(
    isAdmin: Boolean,
    onNavigateToAdmin: () -> Unit,
    onNavigateToPrivacyPolicy: () -> Unit,
    onSignOut: () -> Unit
) {
    Column(
        modifier = Modifier.padding(top = 4.dp)
    ) {
        // Admin Panel - Only visible for admin role users
        if (isAdmin) {
            SettingsItem(
                icon = Icons.Outlined.AdminPanelSettings,
                label = "Admin Panel",
                onClick = onNavigateToAdmin
            )
        }

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

        // Privacy Policy
        SettingsItem(
            icon = Icons.Outlined.Policy,
            label = "Privacy Policy",
            onClick = onNavigateToPrivacyPolicy
        )

        // Help / FAQ
        SettingsItem(
            icon = Icons.Outlined.HelpOutline,
            label = "Help & Support",
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

/**
 * Format follower count (e.g., 45600 -> "45.6K").
 */
private fun formatFollowerCount(count: Int): String {
    return when {
        count >= 1_000_000 -> String.format("%.1fM", count / 1_000_000.0)
        count >= 1_000 -> String.format("%.1fK", count / 1_000.0)
        else -> count.toString()
    }
}
