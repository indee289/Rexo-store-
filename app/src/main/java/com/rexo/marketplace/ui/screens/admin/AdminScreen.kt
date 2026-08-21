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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Admin Center Screen - Admin dashboard
 * Features:
 * - KYC approval queue
 * - Deposit/Withdrawal management
 * - User moderation
 * - Campaign oversight
 * - System stats
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminScreen(
    onNavigateBack: () -> Unit = {}
) {
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("Overview", "KYC", "Transactions", "Users")
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Admin Center",
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
            contentPadding = PaddingValues(bottom = 80.dp)
        ) {
            // Admin Stats
            item {
                AdminStatsSection(
                    modifier = Modifier.padding(20.dp)
                )
            }
            
            // Pending KYC Approvals
            item {
                SectionHeader(
                    title = "Pending KYC Approvals",
                    count = 8,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            items(3) { index ->
                KycApprovalCard(
                    userName = "User ${index + 1}",
                    email = "user${index + 1}@example.com",
                    submittedDate = "2 days ago",
                    onApprove = { /* TODO */ },
                    onReject = { /* TODO */ },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp)
                )
            }
            
            // Pending Withdrawals
            item {
                SectionHeader(
                    title = "Pending Withdrawals",
                    count = 5,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            items(2) { index ->
                WithdrawalRequestCard(
                    userName = "Creator ${index + 1}",
                    amount = (5000 + index * 1000).toDouble(),
                    requestDate = "${index + 1} hours ago",
                    onApprove = { /* TODO */ },
                    onReject = { /* TODO */ },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp)
                )
            }
            
            // Quick Actions
            item {
                Text(
                    text = "Quick Actions",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            item {
                AdminQuickActions(
                    modifier = Modifier.padding(horizontal = 20.dp)
                )
            }
        }
    }
}

@Composable
fun AdminStatsSection(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = "System Statistics",
            style = RexoTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        
        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            AdminStatCard(
                icon = Icons.Outlined.People,
                label = "Total Users",
                value = "2,458",
                color = RexoTheme.colorScheme.primary,
                modifier = Modifier.weight(1f)
            )
            AdminStatCard(
                icon = Icons.Outlined.Campaign,
                label = "Campaigns",
                value = "156",
                color = Color(0xFFF59E0B),
                modifier = Modifier.weight(1f)
            )
        }
        
        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            AdminStatCard(
                icon = Icons.Outlined.Pending,
                label = "Pending KYC",
                value = "8",
                color = Color(0xFFEF4444),
                modifier = Modifier.weight(1f)
            )
            AdminStatCard(
                icon = Icons.Outlined.Payments,
                label = "Withdrawals",
                value = "5",
                color = Color(0xFF10B981),
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
fun AdminStatCard(
    icon: ImageVector,
    label: String,
    value: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    FloatingGlassCard(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        backgroundColor = color.copy(alpha = 0.1f)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = color,
                modifier = Modifier.size(32.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = value,
                style = RexoTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
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
fun SectionHeader(
    title: String,
    count: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = RexoTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        Surface(
            shape = CircleShape,
            color = RexoTheme.colorScheme.primaryContainer
        ) {
            Text(
                text = count.toString(),
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                style = RexoTheme.typography.labelMedium,
                fontWeight = FontWeight.Bold,
                color = RexoTheme.colorScheme.onPrimaryContainer
            )
        }
    }
}

@Composable
fun KycApprovalCard(
    userName: String,
    email: String,
    submittedDate: String,
    onApprove: () -> Unit,
    onReject: () -> Unit,
    modifier: Modifier = Modifier
) {
    GlassSurface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = userName,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = email,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Text(
                        text = "Submitted $submittedDate",
                        style = RexoTheme.typography.labelSmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                }
                
                Surface(
                    shape = CircleShape,
                    color = RexoTheme.colorScheme.primaryContainer,
                    modifier = Modifier.size(48.dp)
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Person,
                        contentDescription = userName,
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
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
                    onClick = onApprove,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF10B981)
                    )
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Check,
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
fun WithdrawalRequestCard(
    userName: String,
    amount: Double,
    requestDate: String,
    onApprove: () -> Unit,
    onReject: () -> Unit,
    modifier: Modifier = Modifier
) {
    GlassSurface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = userName,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "₹${String.format("%,.2f", amount)}",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF10B981)
                    )
                    Text(
                        text = "Requested $requestDate",
                        style = RexoTheme.typography.labelSmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                }
                
                Icon(
                    imageVector = Icons.Outlined.AccountBalanceWallet,
                    contentDescription = "Withdrawal",
                    modifier = Modifier.size(40.dp),
                    tint = Color(0xFF10B981)
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onReject,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = Color(0xFFEF4444)
                    )
                ) {
                    Text("Reject")
                }
                
                Button(
                    onClick = onApprove,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Process")
                }
            }
        }
    }
}

@Composable
fun AdminQuickActions(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        AdminActionItem(
            icon = Icons.Outlined.Group,
            title = "Manage Users",
            onClick = { /* TODO */ }
        )
        AdminActionItem(
            icon = Icons.Outlined.Campaign,
            title = "Moderate Campaigns",
            onClick = { /* TODO */ }
        )
        AdminActionItem(
            icon = Icons.Outlined.BarChart,
            title = "View Analytics",
            onClick = { /* TODO */ }
        )
        AdminActionItem(
            icon = Icons.Outlined.Report,
            title = "View Reports",
            onClick = { /* TODO */ }
        )
    }
}

@Composable
fun AdminActionItem(
    icon: ImageVector,
    title: String,
    onClick: () -> Unit
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
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    tint = RexoTheme.colorScheme.primary
                )
                Text(
                    text = title,
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }
            
            IconButton(onClick = onClick) {
                Icon(
                    imageVector = Icons.Outlined.ChevronRight,
                    contentDescription = "Go"
                )
            }
        }
    }
}
