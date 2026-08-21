package com.rexo.marketplace.ui.screens.notifications

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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme
import java.text.SimpleDateFormat
import java.util.*

/**
 * Notifications Screen - View all notifications
 * Features:
 * - Filter tabs (All, Campaigns, Payments, Updates)
 * - Notification cards with icons
 * - Mark as read functionality
 * - Time formatting
 * - Empty state
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationsScreen(
    onNavigateBack: () -> Unit = {}
) {
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("All", "Campaigns", "Payments", "Updates")
    
    val notifications = remember {
        listOf(
            NotificationItem(
                id = "1",
                title = "Campaign Payment Received",
                message = "You received ₹5,000 for Tech Product Launch campaign",
                type = NotificationType.PAYMENT,
                timestamp = Date(System.currentTimeMillis() - 3600000),
                isRead = false
            ),
            NotificationItem(
                id = "2",
                title = "New Campaign Available",
                message = "Fashion Brand Collaboration campaign matches your profile",
                type = NotificationType.CAMPAIGN,
                timestamp = Date(System.currentTimeMillis() - 7200000),
                isRead = false
            ),
            NotificationItem(
                id = "3",
                title = "Application Approved",
                message = "Your application for Gaming Tournament campaign was approved!",
                type = NotificationType.CAMPAIGN,
                timestamp = Date(System.currentTimeMillis() - 86400000),
                isRead = true
            ),
            NotificationItem(
                id = "4",
                title = "Withdrawal Processed",
                message = "Your withdrawal of ₹10,000 has been processed successfully",
                type = NotificationType.PAYMENT,
                timestamp = Date(System.currentTimeMillis() - 172800000),
                isRead = true
            ),
            NotificationItem(
                id = "5",
                title = "Profile Update",
                message = "Your KYC verification has been approved",
                type = NotificationType.UPDATE,
                timestamp = Date(System.currentTimeMillis() - 259200000),
                isRead = true
            ),
            NotificationItem(
                id = "6",
                title = "Campaign Deadline Reminder",
                message = "Food Review Series campaign deadline is in 2 days",
                type = NotificationType.CAMPAIGN,
                timestamp = Date(System.currentTimeMillis() - 345600000),
                isRead = true
            )
        )
    }
    
    val filteredNotifications = remember(selectedTab) {
        when (tabs[selectedTab]) {
            "Campaigns" -> notifications.filter { it.type == NotificationType.CAMPAIGN }
            "Payments" -> notifications.filter { it.type == NotificationType.PAYMENT }
            "Updates" -> notifications.filter { it.type == NotificationType.UPDATE }
            else -> notifications
        }
    }
    
    val unreadCount = notifications.count { !it.isRead }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "Notifications",
                            style = RexoTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold
                        )
                        if (unreadCount > 0) {
                            Text(
                                text = "$unreadCount unread",
                                style = RexoTheme.typography.bodySmall,
                                color = RexoTheme.colorScheme.primary
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (unreadCount > 0) {
                        TextButton(onClick = { /* TODO: Mark all as read */ }) {
                            Text("Mark all read", style = RexoTheme.typography.bodySmall)
                        }
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
            // Filter Tabs
            item {
                NotificationTabs(
                    tabs = tabs,
                    selectedTab = selectedTab,
                    onTabSelected = { selectedTab = it },
                    modifier = Modifier.padding(vertical = 12.dp)
                )
            }
            
            // Notifications List
            items(filteredNotifications) { notification ->
                NotificationCard(
                    notification = notification,
                    onClick = { /* TODO: Handle click */ },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp)
                )
            }
            
            // Empty State
            if (filteredNotifications.isEmpty()) {
                item {
                    EmptyNotifications(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 60.dp)
                    )
                }
            }
        }
    }
}

data class NotificationItem(
    val id: String,
    val title: String,
    val message: String,
    val type: NotificationType,
    val timestamp: Date,
    val isRead: Boolean
)

enum class NotificationType {
    CAMPAIGN, PAYMENT, UPDATE
}

@Composable
fun NotificationTabs(
    tabs: List<String>,
    selectedTab: Int,
    onTabSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyRow(
        modifier = modifier,
        contentPadding = PaddingValues(horizontal = 20.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        itemsIndexed(tabs) { index, tab ->
            val isSelected = index == selectedTab
            
            val backgroundColor by animateColorAsState(
                targetValue = if (isSelected) RexoTheme.colorScheme.primary else RexoTheme.colorScheme.surfaceVariant,
                animationSpec = tween(300),
                label = "tab_bg"
            )
            
            FilterChip(
                selected = isSelected,
                onClick = { onTabSelected(index) },
                label = {
                    Text(
                        text = tab,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                    )
                },
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = backgroundColor,
                    containerColor = backgroundColor
                )
            )
        }
    }
}

@Composable
fun NotificationCard(
    notification: NotificationItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val dateFormat = remember { SimpleDateFormat("MMM dd, hh:mm a", Locale.getDefault()) }
    val (icon, iconColor) = getNotificationIconAndColor(notification.type)
    
    GlassSurface(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        backgroundColor = if (!notification.isRead) {
            RexoTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
        } else {
            RexoTheme.colorScheme.surface.copy(alpha = 0.5f)
        }
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Icon
            Surface(
                shape = CircleShape,
                color = iconColor.copy(alpha = 0.15f),
                modifier = Modifier.size(48.dp)
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = notification.type.name,
                    modifier = Modifier.padding(12.dp),
                    tint = iconColor
                )
            }
            
            // Content
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = notification.title,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = if (!notification.isRead) FontWeight.Bold else FontWeight.SemiBold,
                        modifier = Modifier.weight(1f)
                    )
                    
                    if (!notification.isRead) {
                        Box(
                            modifier = Modifier
                                .size(10.dp)
                                .clip(CircleShape)
                                .background(RexoTheme.colorScheme.primary)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = notification.message,
                    style = RexoTheme.typography.bodySmall,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = dateFormat.format(notification.timestamp),
                    style = RexoTheme.typography.labelSmall,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                )
            }
        }
    }
}

fun getNotificationIconAndColor(type: NotificationType): Pair<ImageVector, Color> {
    return when (type) {
        NotificationType.CAMPAIGN -> Icons.Outlined.Campaign to Color(0xFF6366F1)
        NotificationType.PAYMENT -> Icons.Outlined.Payments to Color(0xFF10B981)
        NotificationType.UPDATE -> Icons.Outlined.Info to Color(0xFFF59E0B)
    }
}

@Composable
fun EmptyNotifications(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Outlined.NotificationsNone,
            contentDescription = "No notifications",
            modifier = Modifier.size(80.dp),
            tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.3f)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "No notifications",
            style = RexoTheme.typography.titleMedium,
            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        )
        
        Text(
            text = "You're all caught up!",
            style = RexoTheme.typography.bodySmall,
            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.5f)
        )
    }
}
