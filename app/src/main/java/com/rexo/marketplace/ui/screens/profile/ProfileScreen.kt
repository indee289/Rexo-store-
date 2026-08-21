package com.rexo.marketplace.ui.screens.profile

import androidx.compose.animation.*
import androidx.compose.animation.core.*
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Profile Screen - User profile with KYC and stats
 * Features:
 * - Profile header with avatar
 * - KYC verification status
 * - Stats dashboard (campaigns, earnings, followers)
 * - Social links
 * - Profile settings
 * - Edit profile
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    onNavigateBack: () -> Unit = {},
    onNavigateToSettings: () -> Unit = {}
) {
    var isKycVerified by remember { mutableStateOf(false) }
    var showKycDialog by remember { mutableStateOf(false) }
    
    val userStats = remember {
        UserStats(
            totalCampaigns = 45,
            activeCampaigns = 12,
            completedCampaigns = 33,
            totalEarnings = 125000.0,
            thisMonthEarnings = 15200.0,
            followers = 45600,
            engagement = 4.2
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Profile",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(Icons.Outlined.Settings, contentDescription = "Settings")
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
            contentPadding = PaddingValues(bottom = 80.dp)
        ) {
            // Profile Header
            item {
                ProfileHeader(
                    name = "John Doe",
                    username = "@johndoe",
                    bio = "Tech enthusiast | Content creator | Passionate about innovation 🚀",
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 16.dp)
                )
            }
            
            // KYC Status
            item {
                KycStatusCard(
                    isVerified = isKycVerified,
                    onVerifyClick = { showKycDialog = true },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            // Stats Grid
            item {
                Text(
                    text = "Statistics",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            item {
                StatsGrid(
                    stats = userStats,
                    modifier = Modifier.padding(horizontal = 20.dp)
                )
            }
            
            // Earnings Card
            item {
                EarningsCard(
                    totalEarnings = userStats.totalEarnings,
                    thisMonthEarnings = userStats.thisMonthEarnings,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            // Social Links
            item {
                Text(
                    text = "Social Links",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            item {
                SocialLinksSection(
                    modifier = Modifier.padding(horizontal = 20.dp)
                )
            }
            
            // Profile Actions
            item {
                Text(
                    text = "Profile Management",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            item {
                ProfileActions(
                    onEditProfile = { /* TODO */ },
                    onChangePassword = { /* TODO */ },
                    onPrivacySettings = { /* TODO */ },
                    modifier = Modifier.padding(horizontal = 20.dp)
                )
            }
            
            // Logout Button
            item {
                OutlinedButton(
                    onClick = { /* TODO: Logout */ },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 24.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = Color(0xFFEF4444)
                    )
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Logout,
                        contentDescription = "Logout",
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Logout", style = RexoTheme.typography.titleSmall)
                }
            }
        }
    }
    
    // KYC Dialog
    if (showKycDialog) {
        KycDialog(
            onDismiss = { showKycDialog = false },
            onSubmit = {
                isKycVerified = true
                showKycDialog = false
            }
        )
    }
}

@Composable
fun ProfileHeader(
    name: String,
    username: String,
    bio: String,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Avatar
        Box {
            Surface(
                modifier = Modifier.size(100.dp),
                shape = CircleShape,
                color = RexoTheme.colorScheme.primaryContainer
            ) {
                Icon(
                    imageVector = Icons.Filled.Person,
                    contentDescription = "Profile picture",
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    tint = RexoTheme.colorScheme.onPrimaryContainer
                )
            }
            
            // Edit button
            Surface(
                modifier = Modifier
                    .size(32.dp)
                    .align(Alignment.BottomEnd),
                shape = CircleShape,
                color = RexoTheme.colorScheme.primary,
                onClick = { /* TODO: Change avatar */ }
            ) {
                Icon(
                    imageVector = Icons.Filled.CameraAlt,
                    contentDescription = "Edit avatar",
                    modifier = Modifier.padding(6.dp),
                    tint = RexoTheme.colorScheme.onPrimary
                )
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Name
        Text(
            text = name,
            style = RexoTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        
        // Username
        Text(
            text = username,
            style = RexoTheme.typography.bodyMedium,
            color = RexoTheme.colorScheme.primary
        )
        
        Spacer(modifier = Modifier.height(12.dp))
        
        // Bio
        Text(
            text = bio,
            style = RexoTheme.typography.bodyMedium,
            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Edit Profile Button
        OutlinedButton(
            onClick = { /* TODO */ },
            shape = RoundedCornerShape(12.dp)
        ) {
            Icon(
                imageVector = Icons.Outlined.Edit,
                contentDescription = "Edit",
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text("Edit Profile")
        }
    }
}

@Composable
fun KycStatusCard(
    isVerified: Boolean,
    onVerifyClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    FloatingGlassCard(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        backgroundColor = if (isVerified) {
            Color(0xFF10B981).copy(alpha = 0.1f)
        } else {
            Color(0xFFF59E0B).copy(alpha = 0.1f)
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = if (isVerified) Icons.Filled.VerifiedUser else Icons.Outlined.VerifiedUser,
                    contentDescription = "KYC Status",
                    modifier = Modifier.size(40.dp),
                    tint = if (isVerified) Color(0xFF10B981) else Color(0xFFF59E0B)
                )
                
                Column {
                    Text(
                        text = if (isVerified) "KYC Verified" else "KYC Pending",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = if (isVerified) Color(0xFF10B981) else Color(0xFFF59E0B)
                    )
                    Text(
                        text = if (isVerified) "Your account is verified" else "Complete verification to unlock features",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                }
            }
            
            if (!isVerified) {
                IconButton(onClick = onVerifyClick) {
                    Icon(
                        imageVector = Icons.Outlined.ChevronRight,
                        contentDescription = "Verify"
                    )
                }
            }
        }
    }
}

data class UserStats(
    val totalCampaigns: Int,
    val activeCampaigns: Int,
    val completedCampaigns: Int,
    val totalEarnings: Double,
    val thisMonthEarnings: Double,
    val followers: Int,
    val engagement: Double
)

@Composable
fun StatsGrid(
    stats: UserStats,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            StatItem(
                icon = Icons.Outlined.Campaign,
                label = "Total",
                value = stats.totalCampaigns.toString(),
                color = RexoTheme.colorScheme.primary,
                modifier = Modifier.weight(1f)
            )
            StatItem(
                icon = Icons.Outlined.Autorenew,
                label = "Active",
                value = stats.activeCampaigns.toString(),
                color = Color(0xFFF59E0B),
                modifier = Modifier.weight(1f)
            )
            StatItem(
                icon = Icons.Outlined.CheckCircle,
                label = "Completed",
                value = stats.completedCampaigns.toString(),
                color = Color(0xFF10B981),
                modifier = Modifier.weight(1f)
            )
        }
        
        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            StatItem(
                icon = Icons.Outlined.People,
                label = "Followers",
                value = formatNumber(stats.followers),
                color = RexoTheme.colorScheme.secondary,
                modifier = Modifier.weight(1f)
            )
            StatItem(
                icon = Icons.Outlined.TrendingUp,
                label = "Engagement",
                value = "${stats.engagement}%",
                color = Color(0xFF8B5CF6),
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
fun StatItem(
    icon: ImageVector,
    label: String,
    value: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    GlassSurface(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        backgroundColor = color.copy(alpha = 0.1f)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = color,
                modifier = Modifier.size(28.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = value,
                style = RexoTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = RexoTheme.colorScheme.onSurface
            )
            Text(
                text = label,
                style = RexoTheme.typography.bodySmall,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
        }
    }
}

@Composable
fun EarningsCard(
    totalEarnings: Double,
    thisMonthEarnings: Double,
    modifier: Modifier = Modifier
) {
    FloatingGlassCard(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        backgroundColor = Brush.horizontalGradient(
            colors = listOf(
                Color(0xFF10B981).copy(alpha = 0.15f),
                Color(0xFF059669).copy(alpha = 0.15f)
            )
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Total Earnings",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Icon(
                    imageVector = Icons.Outlined.AccountBalanceWallet,
                    contentDescription = "Earnings",
                    tint = Color(0xFF10B981)
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = "₹${String.format("%,.2f", totalEarnings)}",
                style = RexoTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF10B981)
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "This month: ₹${String.format("%,.2f", thisMonthEarnings)}",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                Icon(
                    imageVector = Icons.Outlined.TrendingUp,
                    contentDescription = "Trending up",
                    modifier = Modifier.size(16.dp),
                    tint = Color(0xFF10B981)
                )
            }
        }
    }
}

@Composable
fun SocialLinksSection(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        SocialLinkItem(
            platform = "Instagram",
            handle = "@johndoe",
            icon = Icons.Outlined.Camera,
            color = Color(0xFFE4405F)
        )
        SocialLinkItem(
            platform = "YouTube",
            handle = "@johndoevlogs",
            icon = Icons.Outlined.PlayCircle,
            color = Color(0xFFFF0000)
        )
        SocialLinkItem(
            platform = "Twitter",
            handle = "@johndoe",
            icon = Icons.Outlined.TagFaces,
            color = Color(0xFF1DA1F2)
        )
    }
}

@Composable
fun SocialLinkItem(
    platform: String,
    handle: String,
    icon: ImageVector,
    color: Color
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
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = CircleShape,
                    color = color.copy(alpha = 0.15f),
                    modifier = Modifier.size(40.dp)
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = platform,
                        modifier = Modifier.padding(10.dp),
                        tint = color
                    )
                }
                
                Column {
                    Text(
                        text = platform,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = handle,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            }
            
            IconButton(onClick = { /* TODO: Edit */ }) {
                Icon(
                    imageVector = Icons.Outlined.Edit,
                    contentDescription = "Edit",
                    tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                )
            }
        }
    }
}

@Composable
fun ProfileActions(
    onEditProfile: () -> Unit,
    onChangePassword: () -> Unit,
    onPrivacySettings: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        ProfileActionItem(
            icon = Icons.Outlined.Edit,
            title = "Edit Profile",
            subtitle = "Update your personal information",
            onClick = onEditProfile
        )
        ProfileActionItem(
            icon = Icons.Outlined.Lock,
            title = "Change Password",
            subtitle = "Update your password",
            onClick = onChangePassword
        )
        ProfileActionItem(
            icon = Icons.Outlined.Security,
            title = "Privacy & Security",
            subtitle = "Manage your privacy settings",
            onClick = onPrivacySettings
        )
    }
}

@Composable
fun ProfileActionItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit
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
                verticalAlignment = Alignment.CenterVertically
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
            
            Icon(
                imageVector = Icons.Outlined.ChevronRight,
                contentDescription = "Go",
                tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.4f)
            )
        }
    }
}

@Composable
fun KycDialog(
    onDismiss: () -> Unit,
    onSubmit: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                imageVector = Icons.Outlined.VerifiedUser,
                contentDescription = "KYC",
                tint = RexoTheme.colorScheme.primary,
                modifier = Modifier.size(48.dp)
            )
        },
        title = {
            Text(
                text = "KYC Verification",
                style = RexoTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Text(
                text = "Complete your KYC verification to unlock all features. You'll need to provide:\n\n• Government ID\n• Address proof\n• Selfie verification\n\nThis usually takes 2-3 business days.",
                style = RexoTheme.typography.bodyMedium
            )
        },
        confirmButton = {
            Button(
                onClick = onSubmit,
                shape = RoundedCornerShape(12.dp)
            ) {
                Text("Start Verification")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Later")
            }
        }
    )
}

fun formatNumber(num: Int): String {
    return when {
        num >= 1000000 -> String.format("%.1fM", num / 1000000.0)
        num >= 1000 -> String.format("%.1fK", num / 1000.0)
        else -> num.toString()
    }
}
