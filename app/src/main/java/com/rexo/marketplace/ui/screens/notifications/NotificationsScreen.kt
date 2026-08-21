package com.rexo.marketplace.ui.screens.notifications

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
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
import com.rexo.marketplace.data.repository.NotificationDto
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.NotificationViewModel

/**
 * Notifications Screen
 *
 * Clean white design showing real notifications from Supabase.
 * Features:
 * - Fetches from 'notifications' table where user_id = current user
 * - Notifications ordered by created_at DESC
 * - Mark as read on tap
 * - Mark all as read button
 * - Icon based on notification type
 * - Time ago format
 * - Proper loading/empty/error states
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationsScreen(
    onNavigateBack: () -> Unit = {},
    viewModel: NotificationViewModel? = null
) {
    val vm = viewModel

    val uiState by vm?.uiState?.collectAsState()
        ?: remember { mutableStateOf(com.rexo.marketplace.ui.viewmodel.NotificationUiState(isLoading = true)) }
    val notifications by vm?.notifications?.collectAsState()
        ?: remember { mutableStateOf(emptyList<NotificationDto>()) }

    val unreadCount = notifications.count { !it.is_read }

    Scaffold(
        containerColor = Color.White,
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "Notifications",
                            style = RexoTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.TextPrimary
                        )
                        if (unreadCount > 0) {
                            Text(
                                text = "$unreadCount unread",
                                style = RexoTheme.typography.bodySmall,
                                color = RexoColors.AccentOrange
                            )
                        }
                    }
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
                actions = {
                    if (unreadCount > 0) {
                        TextButton(onClick = { vm?.markAllAsRead() }) {
                            Text(
                                "Mark all read",
                                style = RexoTheme.typography.bodySmall,
                                color = RexoColors.AccentOrange
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = RexoColors.AccentOrange)
                }
            }

            uiState.error != null -> {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Outlined.ErrorOutline,
                        contentDescription = "Error",
                        modifier = Modifier.size(64.dp),
                        tint = RexoColors.Error
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Failed to load notifications",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = uiState.error ?: "",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    OutlinedButton(
                        onClick = { vm?.loadNotifications() },
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text("Retry")
                    }
                }
            }

            notifications.isEmpty() -> {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Outlined.NotificationsNone,
                        contentDescription = "No notifications",
                        modifier = Modifier.size(80.dp),
                        tint = RexoColors.Gray300
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "No notifications yet",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "You're all caught up!",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                }
            }

            else -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentPadding = PaddingValues(bottom = 80.dp)
                ) {
                    items(notifications) { notification ->
                        NotificationListItem(
                            notification = notification,
                            onClick = {
                                if (!notification.is_read) {
                                    vm?.markAsRead(notification.id)
                                }
                            }
                        )
                        HorizontalDivider(
                            modifier = Modifier.padding(horizontal = 20.dp),
                            color = RexoColors.CardBorder
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun NotificationListItem(
    notification: NotificationDto,
    onClick: () -> Unit
) {
    val (icon, iconColor) = getTypeIconAndColor(notification.type)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Icon
        Surface(
            shape = CircleShape,
            color = iconColor.copy(alpha = 0.1f),
            modifier = Modifier.size(44.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = notification.type,
                modifier = Modifier.padding(10.dp),
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
                    fontWeight = if (!notification.is_read) FontWeight.Bold else FontWeight.SemiBold,
                    color = RexoColors.TextPrimary,
                    modifier = Modifier.weight(1f)
                )

                if (!notification.is_read) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(RexoColors.AccentOrange)
                    )
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = notification.body,
                style = RexoTheme.typography.bodySmall,
                color = RexoColors.TextSecondary,
                maxLines = 2
            )

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = formatTimeAgo(notification.created_at),
                style = RexoTheme.typography.labelSmall,
                color = RexoColors.Gray400
            )
        }
    }
}

private fun getTypeIconAndColor(type: String): Pair<ImageVector, Color> {
    return when (type.lowercase()) {
        "campaign", "campaign_update" -> Icons.Outlined.Campaign to Color(0xFF6366F1)
        "payment", "payout" -> Icons.Outlined.Payments to RexoColors.Success
        "application", "approval" -> Icons.Outlined.CheckCircle to RexoColors.Success
        "warning", "alert" -> Icons.Outlined.Warning to RexoColors.Warning
        "system" -> Icons.Outlined.Settings to RexoColors.Gray500
        else -> Icons.Outlined.Notifications to RexoColors.AccentOrange
    }
}

/**
 * Format a timestamp string (ISO 8601) into a relative "time ago" format.
 */
private fun formatTimeAgo(timestamp: String?): String {
    if (timestamp.isNullOrBlank()) return ""
    return try {
        // Parse ISO timestamp (e.g., "2024-01-15T10:30:00+00:00")
        val dateStr = timestamp.replace("T", " ").take(19)
        val format = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault())
        format.timeZone = java.util.TimeZone.getTimeZone("UTC")
        val date = format.parse(dateStr) ?: return timestamp.take(10)
        val now = System.currentTimeMillis()
        val diff = now - date.time

        val minutes = diff / (1000 * 60)
        val hours = minutes / 60
        val days = hours / 24

        when {
            minutes < 1 -> "Just now"
            minutes < 60 -> "${minutes}m ago"
            hours < 24 -> "${hours}h ago"
            days < 7 -> "${days}d ago"
            days < 30 -> "${days / 7}w ago"
            else -> timestamp.take(10)
        }
    } catch (_: Exception) {
        timestamp.take(10)
    }
}
