package com.rexo.marketplace.ui.screens.admin

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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme
import java.text.SimpleDateFormat
import java.util.*

/**
 * Trust & Safety Dashboard
 * Features:
 * - KYC approval queue
 * - User verification
 * - Content moderation
 * - Fraud detection
 * - Dispute resolution
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TrustSafetyDashboard(
    onNavigateBack: () -> Unit = {}
) {
    var selectedTab by remember { mutableStateOf("kyc") }
    
    val kycQueue = remember {
        listOf(
            KYCRequest("1", "Rahul Sharma", "Creator", Date(), "pending"),
            KYCRequest("2", "Priya Patel", "Brand", Date(), "pending"),
            KYCRequest("3", "Amit Kumar", "Creator", Date(), "under_review")
        )
    }
    
    val moderationQueue = remember {
        listOf(
            ModerationItem("1", "Reported Campaign", "Spam content", "campaign", Date()),
            ModerationItem("2", "User Report", "Fake profile", "user", Date())
        )
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Trust & Safety",
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Stats Overview
            LazyColumn(
                contentPadding = PaddingValues(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        StatCard(
                            title = "Pending KYC",
                            value = "12",
                            icon = Icons.Outlined.Person,
                            color = Color(0xFFF59E0B),
                            modifier = Modifier.weight(1f)
                        )
                        
                        StatCard(
                            title = "Reports",
                            value = "5",
                            icon = Icons.Outlined.Report,
                            color = Color(0xFFEF4444),
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
                
                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        StatCard(
                            title = "Disputes",
                            value = "3",
                            icon = Icons.Outlined.Gavel,
                            color = Color(0xFF6366F1),
                            modifier = Modifier.weight(1f)
                        )
                        
                        StatCard(
                            title = "Suspended",
                            value = "2",
                            icon = Icons.Outlined.Block,
                            color = Color(0xFF8B5CF6),
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
                
                // Tab Selector
                item {
                    ScrollableTabRow(
                        selectedTabIndex = when(selectedTab) {
                            "kyc" -> 0
                            "moderation" -> 1
                            "disputes" -> 2
                            else -> 0
                        },
                        containerColor = Color.Transparent,
                        edgePadding = 0.dp
                    ) {
                        Tab(
                            selected = selectedTab == "kyc",
                            onClick = { selectedTab = "kyc" },
                            text = { Text("KYC Queue") }
                        )
                        Tab(
                            selected = selectedTab == "moderation",
                            onClick = { selectedTab = "moderation" },
                            text = { Text("Moderation") }
                        )
                        Tab(
                            selected = selectedTab == "disputes",
                            onClick = { selectedTab = "disputes" },
                            text = { Text("Disputes") }
                        )
                    }
                }
                
                // Content based on selected tab
                when (selectedTab) {
                    "kyc" -> {
                        items(kycQueue) { kyc ->
                            KYCRequestCard(
                                request = kyc,
                                onApprove = { /* TODO */ },
                                onReject = { /* TODO */ }
                            )
                        }
                    }
                    "moderation" -> {
                        items(moderationQueue) { item ->
                            ModerationCard(
                                item = item,
                                onResolve = { /* TODO */ }
                            )
                        }
                    }
                    "disputes" -> {
                        item {
                            GlassSurface(
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(16.dp)
                            ) {
                                Column(
                                    modifier = Modifier.padding(40.dp),
                                    horizontalAlignment = Alignment.CenterHorizontally
                                ) {
                                    Icon(
                                        imageVector = Icons.Outlined.Gavel,
                                        contentDescription = null,
                                        modifier = Modifier.size(64.dp),
                                        tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                                    )
                                    Spacer(modifier = Modifier.height(16.dp))
                                    Text(
                                        text = "No active disputes",
                                        style = RexoTheme.typography.titleMedium,
                                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

data class KYCRequest(
    val id: String,
    val userName: String,
    val userType: String,
    val submittedAt: Date,
    val status: String
)

data class ModerationItem(
    val id: String,
    val title: String,
    val reason: String,
    val type: String,
    val reportedAt: Date
)

@Composable
fun StatCard(
    title: String,
    value: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: Color,
    modifier: Modifier = Modifier
) {
    FloatingGlassCard(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        backgroundColor = color.copy(alpha = 0.1f)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                tint = color,
                modifier = Modifier.size(24.dp)
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = value,
                style = RexoTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = color
            )
            
            Text(
                text = title,
                style = RexoTheme.typography.bodySmall,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
        }
    }
}

@Composable
fun KYCRequestCard(
    request: KYCRequest,
    onApprove: () -> Unit,
    onReject: () -> Unit
) {
    val dateFormat = remember { SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()) }
    
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
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
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(
                        shape = CircleShape,
                        color = RexoTheme.colorScheme.primaryContainer
                    ) {
                        Text(
                            text = request.userName.first().toString(),
                            modifier = Modifier.padding(12.dp),
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = RexoTheme.colorScheme.onPrimaryContainer
                        )
                    }
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    Column {
                        Text(
                            text = request.userName,
                            style = RexoTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = request.userType,
                            style = RexoTheme.typography.bodySmall,
                            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    }
                }
                
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = Color(0xFFF59E0B).copy(alpha = 0.15f)
                ) {
                    Text(
                        text = request.status.replace("_", " ").uppercase(),
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = RexoTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFFF59E0B)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = "Submitted on ${dateFormat.format(request.submittedAt)}",
                style = RexoTheme.typography.bodySmall,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onReject,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = Color(0xFFEF4444)
                    )
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Close,
                        contentDescription = "Reject",
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Reject")
                }
                
                Button(
                    onClick = { /* TODO: Review details */ },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF6366F1)
                    )
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Visibility,
                        contentDescription = "Review",
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Review")
                }
                
                Button(
                    onClick = onApprove,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF10B981)
                    )
                ) {
                    Icon(
                        imageVector = Icons.Outlined.CheckCircle,
                        contentDescription = "Approve",
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Approve")
                }
            }
        }
    }
}

@Composable
fun ModerationCard(
    item: ModerationItem,
    onResolve: () -> Unit
) {
    val dateFormat = remember { SimpleDateFormat("MMM dd, HH:mm", Locale.getDefault()) }
    val typeColor = when(item.type) {
        "campaign" -> Color(0xFF6366F1)
        "user" -> Color(0xFFEF4444)
        else -> Color(0xFFF59E0B)
    }
    
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
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
                    color = typeColor.copy(alpha = 0.15f)
                ) {
                    Text(
                        text = item.type.uppercase(),
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        style = RexoTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = typeColor
                    )
                }
                
                Text(
                    text = dateFormat.format(item.reportedAt),
                    style = RexoTheme.typography.bodySmall,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = item.title,
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = item.reason,
                style = RexoTheme.typography.bodyMedium,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = { /* TODO: Dismiss */ },
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Dismiss")
                }
                
                Button(
                    onClick = onResolve,
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(
                        imageVector = Icons.Outlined.CheckCircle,
                        contentDescription = "Resolve",
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Review")
                }
            }
        }
    }
}
