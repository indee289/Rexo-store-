package com.rexo.marketplace.ui.screens.home

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme
import kotlinx.coroutines.delay

/**
 * Modern Home Dashboard Screen with completely new UI/UX
 * Features:
 * - Hero section with wallet balance
 * - Role switcher chip
 * - Stats cards with animated counters
 * - Featured campaigns carousel
 * - Quick actions grid
 * - Activity feed
 * - Floating action button
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onNavigateToWallet: () -> Unit = {},
    onNavigateToCampaigns: () -> Unit = {},
    onNavigateToProfile: () -> Unit = {}
) {
    var selectedRole by remember { mutableStateOf("Creator") }
    var walletBalance by remember { mutableStateOf(15234.50) }
    var pendingEarnings by remember { mutableStateOf(2450.00) }
    var activeCampaigns by remember { mutableStateOf(12) }
    var completedTasks by remember { mutableStateOf(45) }
    
    val roles = listOf("Creator", "Brand", "Admin")
    
    // Animated balance
    val animatedBalance by animateFloatAsState(
        targetValue = walletBalance.toFloat(),
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "balance"
    )
    
    Scaffold(
        topBar = {
            HomeTopBar(
                onProfileClick = onNavigateToProfile,
                onNotificationClick = { /* TODO */ }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { /* TODO: Create campaign */ },
                containerColor = RexoTheme.colorScheme.primary,
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier.size(64.dp)
            ) {
                Icon(
                    imageVector = Icons.Filled.Add,
                    contentDescription = "Create Campaign",
                    modifier = Modifier.size(28.dp)
                )
            }
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(bottom = 80.dp)
        ) {
            // Hero Section - Wallet Balance
            item {
                WalletBalanceHero(
                    balance = animatedBalance.toDouble(),
                    pendingEarnings = pendingEarnings,
                    onWalletClick = onNavigateToWallet,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 16.dp)
                )
            }
            
            // Role Switcher
            item {
                RoleSwitcher(
                    roles = roles,
                    selectedRole = selectedRole,
                    onRoleSelected = { selectedRole = it },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            // Stats Cards
            item {
                StatsSection(
                    activeCampaigns = activeCampaigns,
                    completedTasks = completedTasks,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            // Section Title
            item {
                Text(
                    text = "Featured Campaigns",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            // Featured Campaigns Carousel
            item {
                FeaturedCampaignsCarousel(
                    campaigns = listOf(
                        CampaignPreview("Tech Product Launch", 5000.0, "Instagram", 15),
                        CampaignPreview("Fashion Brand Collab", 3500.0, "YouTube", 8),
                        CampaignPreview("Food Review Series", 2000.0, "TikTok", 20)
                    ),
                    onCampaignClick = { onNavigateToCampaigns() }
                )
            }
            
            // Quick Actions
            item {
                Text(
                    text = "Quick Actions",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            item {
                QuickActionsGrid(
                    actions = listOf(
                        QuickAction("Browse", Icons.Outlined.Search, RexoTheme.colorScheme.primary),
                        QuickAction("Apply", Icons.Outlined.Send, RexoTheme.colorScheme.secondary),
                        QuickAction("Wallet", Icons.Outlined.AccountBalanceWallet, RexoTheme.colorScheme.tertiary),
                        QuickAction("Shop", Icons.Outlined.ShoppingCart, Color(0xFFF59E0B))
                    ),
                    onActionClick = { action ->
                        when (action.title) {
                            "Browse" -> onNavigateToCampaigns()
                            "Wallet" -> onNavigateToWallet()
                            else -> { /* TODO */ }
                        }
                    },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            // Activity Feed
            item {
                Text(
                    text = "Recent Activity",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            items(5) { index ->
                ActivityItem(
                    title = when (index) {
                        0 -> "Campaign Payment Received"
                        1 -> "New Campaign Available"
                        2 -> "Application Approved"
                        3 -> "Withdrawal Processed"
                        else -> "KYC Verified"
                    },
                    subtitle = "${index + 1} hours ago",
                    icon = when (index) {
                        0 -> Icons.Outlined.Payments
                        1 -> Icons.Outlined.Campaign
                        2 -> Icons.Outlined.CheckCircle
                        3 -> Icons.Outlined.CreditCard
                        else -> Icons.Outlined.VerifiedUser
                    },
                    iconColor = when (index % 4) {
                        0 -> RexoTheme.colorScheme.primary
                        1 -> RexoTheme.colorScheme.secondary
                        2 -> Color(0xFF10B981)
                        else -> Color(0xFFF59E0B)
                    },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp)
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeTopBar(
    onProfileClick: () -> Unit,
    onNotificationClick: () -> Unit
) {
    TopAppBar(
        title = {
            Column {
                Text(
                    text = "Good Morning",
                    style = RexoTheme.typography.bodySmall,
                    color = RexoTheme.colorScheme.onBackground.copy(alpha = 0.7f)
                )
                Text(
                    text = "John Doe",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }
        },
        actions = {
            // Notification Bell with Badge
            Box {
                IconButton(onClick = onNotificationClick) {
                    Icon(
                        imageVector = Icons.Outlined.Notifications,
                        contentDescription = "Notifications"
                    )
                }
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .align(Alignment.TopEnd)
                        .offset(x = (-8).dp, y = 8.dp)
                        .clip(CircleShape)
                        .background(RexoTheme.colorScheme.error)
                )
            }
            
            // Profile Avatar
            IconButton(onClick = onProfileClick) {
                Surface(
                    shape = CircleShape,
                    color = RexoTheme.colorScheme.primaryContainer,
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Filled.Person,
                        contentDescription = "Profile",
                        modifier = Modifier.padding(6.dp),
                        tint = RexoTheme.colorScheme.onPrimaryContainer
                    )
                }
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = Color.Transparent
        )
    )
}

@Composable
fun WalletBalanceHero(
    balance: Double,
    pendingEarnings: Double,
    onWalletClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    FloatingGlassCard(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onWalletClick),
        shape = RoundedCornerShape(24.dp),
        backgroundColor = Brush.horizontalGradient(
            colors = listOf(
                RexoTheme.colorScheme.primary.copy(alpha = 0.15f),
                RexoTheme.colorScheme.secondary.copy(alpha = 0.15f)
            )
        )
    ) {
        Column(
            modifier = Modifier.padding(24.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Total Balance",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                
                Icon(
                    imageVector = Icons.Outlined.AccountBalanceWallet,
                    contentDescription = "Wallet",
                    tint = RexoTheme.colorScheme.primary
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "₹${String.format("%,.2f", balance)}",
                style = RexoTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold,
                color = RexoTheme.colorScheme.onSurface
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Pending",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Text(
                        text = "₹${String.format("%,.2f", pendingEarnings)}",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFFF59E0B)
                    )
                }
                
                Button(
                    onClick = onWalletClick,
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = RexoTheme.colorScheme.primary
                    )
                ) {
                    Icon(
                        imageVector = Icons.Outlined.ArrowForward,
                        contentDescription = "View Wallet",
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("View Wallet")
                }
            }
        }
    }
}

@Composable
fun RoleSwitcher(
    roles: List<String>,
    selectedRole: String,
    onRoleSelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(roles) { role ->
            val isSelected = role == selectedRole
            
            val backgroundColor by animateColorAsState(
                targetValue = if (isSelected) RexoTheme.colorScheme.primary else RexoTheme.colorScheme.surfaceVariant,
                animationSpec = tween(300),
                label = "role_bg"
            )
            
            val contentColor by animateColorAsState(
                targetValue = if (isSelected) RexoTheme.colorScheme.onPrimary else RexoTheme.colorScheme.onSurfaceVariant,
                animationSpec = tween(300),
                label = "role_content"
            )
            
            val scale by animateFloatAsState(
                targetValue = if (isSelected) 1f else 0.95f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioMediumBouncy,
                    stiffness = Spring.StiffnessMedium
                ),
                label = "role_scale"
            )
            
            Surface(
                modifier = Modifier
                    .scale(scale)
                    .clip(RoundedCornerShape(16.dp))
                    .clickable { onRoleSelected(role) },
                color = backgroundColor,
                shape = RoundedCornerShape(16.dp),
                tonalElevation = if (isSelected) 4.dp else 0.dp
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = when (role) {
                            "Creator" -> Icons.Outlined.Person
                            "Brand" -> Icons.Outlined.Store
                            else -> Icons.Outlined.AdminPanelSettings
                        },
                        contentDescription = role,
                        tint = contentColor,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = role,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                        color = contentColor
                    )
                }
            }
        }
    }
}

@Composable
fun StatsSection(
    activeCampaigns: Int,
    completedTasks: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        StatCard(
            title = "Active",
            value = activeCampaigns.toString(),
            icon = Icons.Outlined.Campaign,
            color = RexoTheme.colorScheme.primary,
            modifier = Modifier.weight(1f)
        )
        
        StatCard(
            title = "Completed",
            value = completedTasks.toString(),
            icon = Icons.Outlined.CheckCircle,
            color = Color(0xFF10B981),
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
fun StatCard(
    title: String,
    value: String,
    icon: ImageVector,
    color: Color,
    modifier: Modifier = Modifier
) {
    GlassSurface(
        modifier = modifier,
        shape = RoundedCornerShape(20.dp),
        backgroundColor = color.copy(alpha = 0.1f)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                tint = color,
                modifier = Modifier.size(28.dp)
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = value,
                style = RexoTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = RexoTheme.colorScheme.onSurface
            )
            
            Text(
                text = title,
                style = RexoTheme.typography.bodySmall,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
        }
    }
}

data class CampaignPreview(
    val title: String,
    val budget: Double,
    val platform: String,
    val applicants: Int
)

@Composable
fun FeaturedCampaignsCarousel(
    campaigns: List<CampaignPreview>,
    onCampaignClick: (CampaignPreview) -> Unit
) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 20.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        items(campaigns) { campaign ->
            CampaignCard(
                campaign = campaign,
                onClick = { onCampaignClick(campaign) }
            )
        }
    }
}

@Composable
fun CampaignCard(
    campaign: CampaignPreview,
    onClick: () -> Unit
) {
    FloatingGlassCard(
        modifier = Modifier
            .width(280.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = RexoTheme.colorScheme.primaryContainer
                ) {
                    Text(
                        text = campaign.platform,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        style = RexoTheme.typography.labelSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoTheme.colorScheme.onPrimaryContainer
                    )
                }
                
                Text(
                    text = "₹${String.format("%,.0f", campaign.budget)}",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF10B981)
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = campaign.title,
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                maxLines = 2,
                color = RexoTheme.colorScheme.onSurface
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Outlined.People,
                    contentDescription = "Applicants",
                    modifier = Modifier.size(16.dp),
                    tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "${campaign.applicants} applicants",
                    style = RexoTheme.typography.bodySmall,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
        }
    }
}

data class QuickAction(
    val title: String,
    val icon: ImageVector,
    val color: Color
)

@Composable
fun QuickActionsGrid(
    actions: List<QuickAction>,
    onActionClick: (QuickAction) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        actions.forEach { action ->
            QuickActionButton(
                action = action,
                onClick = { onActionClick(action) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
fun QuickActionButton(
    action: QuickAction,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val scale by remember { mutableStateOf(Animatable(1f)) }
    
    GlassSurface(
        modifier = modifier
            .aspectRatio(1f)
            .scale(scale.value)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(20.dp),
        backgroundColor = action.color.copy(alpha = 0.1f)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = action.icon,
                contentDescription = action.title,
                modifier = Modifier.size(32.dp),
                tint = action.color
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = action.title,
                style = RexoTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = RexoTheme.colorScheme.onSurface
            )
        }
    }
}

@Composable
fun ActivityItem(
    title: String,
    subtitle: String,
    icon: ImageVector,
    iconColor: Color,
    modifier: Modifier = Modifier
) {
    GlassSurface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = CircleShape,
                color = iconColor.copy(alpha = 0.15f),
                modifier = Modifier.size(48.dp)
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    modifier = Modifier.padding(12.dp),
                    tint = iconColor
                )
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = RexoTheme.colorScheme.onSurface
                )
                Text(
                    text = subtitle,
                    style = RexoTheme.typography.bodySmall,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
            
            Icon(
                imageVector = Icons.Outlined.ChevronRight,
                contentDescription = "View",
                tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.4f)
            )
        }
    }
}
