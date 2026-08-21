package com.rexo.marketplace.ui.screens.wallet

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
 * Escrow Management Screen
 * Features:
 * - Campaign payments in escrow
 * - Release tracking
 * - Dispute management
 * - Escrow history
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EscrowManagementScreen(
    onNavigateBack: () -> Unit = {}
) {
    val escrowItems = remember {
        listOf(
            EscrowItem(
                "1",
                "Tech Product Launch",
                5000.0,
                EscrowStatus.HELD,
                Date(System.currentTimeMillis() + 7 * 86400000),
                "Brand XYZ"
            ),
            EscrowItem(
                "2",
                "Fashion Campaign",
                3500.0,
                EscrowStatus.PENDING_RELEASE,
                Date(System.currentTimeMillis() + 3 * 86400000),
                "StyleHub"
            ),
            EscrowItem(
                "3",
                "Food Review",
                2000.0,
                EscrowStatus.COMPLETED,
                Date(System.currentTimeMillis() - 2 * 86400000),
                "Foodie Network"
            )
        )
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Escrow Management",
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
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Escrow Summary
            item {
                EscrowSummaryCard(
                    totalHeld = 10500.0,
                    pendingRelease = 3500.0,
                    activeEscrows = 2
                )
            }
            
            // Filter Tabs
            item {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("All", "Held", "Pending", "Completed").forEach { status ->
                        FilterChip(
                            selected = status == "All",
                            onClick = { /* TODO */ },
                            label = { Text(status) }
                        )
                    }
                }
            }
            
            // Escrow Items
            items(escrowItems) { item ->
                EscrowCard(
                    escrowItem = item,
                    onRelease = { /* TODO */ },
                    onDispute = { /* TODO */ }
                )
            }
        }
    }
}

data class EscrowItem(
    val id: String,
    val campaignName: String,
    val amount: Double,
    val status: EscrowStatus,
    val releaseDate: Date,
    val brandName: String
)

enum class EscrowStatus {
    HELD, PENDING_RELEASE, COMPLETED, DISPUTED
}

@Composable
fun EscrowSummaryCard(
    totalHeld: Double,
    pendingRelease: Double,
    activeEscrows: Int
) {
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        backgroundColor = Color(0xFFF59E0B).copy(alpha = 0.1f)
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
                    text = "Total in Escrow",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Icon(
                    imageVector = Icons.Outlined.Security,
                    contentDescription = "Escrow",
                    tint = Color(0xFFF59E0B)
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = "₹${String.format("%,.2f", totalHeld)}",
                style = RexoTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold,
                color = Color(0xFFF59E0B)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Pending Release",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Text(
                        text = "₹${String.format("%,.0f", pendingRelease)}",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }
                
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "Active",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Text(
                        text = "$activeEscrows escrows",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
fun EscrowCard(
    escrowItem: EscrowItem,
    onRelease: () -> Unit,
    onDispute: () -> Unit
) {
    val dateFormat = remember { SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()) }
    val statusColor = when (escrowItem.status) {
        EscrowStatus.HELD -> Color(0xFFF59E0B)
        EscrowStatus.PENDING_RELEASE -> Color(0xFF6366F1)
        EscrowStatus.COMPLETED -> Color(0xFF10B981)
        EscrowStatus.DISPUTED -> Color(0xFFEF4444)
    }
    
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = statusColor.copy(alpha = 0.15f)
                ) {
                    Text(
                        text = escrowItem.status.name.replace("_", " "),
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        style = RexoTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = statusColor
                    )
                }
                
                Icon(
                    imageVector = Icons.Outlined.Security,
                    contentDescription = "Escrow",
                    tint = statusColor
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Campaign Name
            Text(
                text = escrowItem.campaignName,
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = "by ${escrowItem.brandName}",
                style = RexoTheme.typography.bodySmall,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Amount & Date
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Amount",
                        style = RexoTheme.typography.labelSmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Text(
                        text = "₹${String.format("%,.2f", escrowItem.amount)}",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = statusColor
                    )
                }
                
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = if (escrowItem.status == EscrowStatus.COMPLETED) "Released on" else "Release on",
                        style = RexoTheme.typography.labelSmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Text(
                        text = dateFormat.format(escrowItem.releaseDate),
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
            
            // Actions
            if (escrowItem.status == EscrowStatus.PENDING_RELEASE) {
                Spacer(modifier = Modifier.height(16.dp))
                
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = onDispute,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = Color(0xFFEF4444)
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Report,
                            contentDescription = "Dispute",
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Dispute")
                    }
                    
                    Button(
                        onClick = onRelease,
                        modifier = Modifier.weight(1f)
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
}
