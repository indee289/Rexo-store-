package com.rexo.marketplace.ui.screens.wallet

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

/**
 * Modern Wallet Screen with Fintech-style UI/UX
 * Features:
 * - 3D card design with gradient
 * - Balance reveal/hide animation
 * - Quick action buttons
 * - Transaction history with categories
 * - Pull-to-refresh
 * - Smooth animations
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WalletScreen(
    onNavigateBack: () -> Unit = {}
) {
    var balance by remember { mutableStateOf(15234.50) }
    var balanceVisible by remember { mutableStateOf(true) }
    var selectedTab by remember { mutableStateOf(0) }
    var showAddMoneyDialog by remember { mutableStateOf(false) }
    var showWithdrawDialog by remember { mutableStateOf(false) }
    
    val tabs = listOf("All", "Income", "Expense", "Pending")
    
    // Animated balance
    val animatedBalance by animateFloatAsState(
        targetValue = balance.toFloat(),
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "balance"
    )
    
    // Sample transactions
    val transactions = remember {
        listOf(
            Transaction("Campaign Payment", 5000.0, "Income", Date(), TransactionStatus.COMPLETED),
            Transaction("Brand Collaboration", 3500.0, "Income", Date(System.currentTimeMillis() - 86400000), TransactionStatus.COMPLETED),
            Transaction("Withdrawal to Bank", -2000.0, "Expense", Date(System.currentTimeMillis() - 172800000), TransactionStatus.COMPLETED),
            Transaction("Shop Purchase", -450.0, "Expense", Date(System.currentTimeMillis() - 259200000), TransactionStatus.COMPLETED),
            Transaction("Campaign Bonus", 1200.0, "Income", Date(System.currentTimeMillis() - 345600000), TransactionStatus.PENDING),
            Transaction("Affiliate Earning", 850.0, "Income", Date(System.currentTimeMillis() - 432000000), TransactionStatus.COMPLETED)
        )
    }
    
    val filteredTransactions = remember(selectedTab) {
        when (tabs[selectedTab]) {
            "Income" -> transactions.filter { it.amount > 0 }
            "Expense" -> transactions.filter { it.amount < 0 }
            "Pending" -> transactions.filter { it.status == TransactionStatus.PENDING }
            else -> transactions
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Wallet",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Outlined.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    IconButton(onClick = { /* TODO: Transaction history */ }) {
                        Icon(
                            imageVector = Icons.Outlined.History,
                            contentDescription = "History"
                        )
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
            // Wallet Card
            item {
                WalletCard(
                    balance = if (balanceVisible) animatedBalance.toDouble() else null,
                    onVisibilityToggle = { balanceVisible = !balanceVisible },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 16.dp)
                )
            }
            
            // Quick Actions
            item {
                QuickActions(
                    onAddMoney = { showAddMoneyDialog = true },
                    onWithdraw = { showWithdrawDialog = true },
                    onSend = { /* TODO */ },
                    onRequest = { /* TODO */ },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            // Statistics Cards
            item {
                StatisticsRow(
                    totalIncome = 12450.0,
                    totalExpense = 2450.0,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            // Tab Selector
            item {
                FilterTabs(
                    tabs = tabs,
                    selectedTab = selectedTab,
                    onTabSelected = { selectedTab = it },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            // Transactions Header
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Transactions",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    TextButton(onClick = { /* TODO: View all */ }) {
                        Text("View All")
                        Icon(
                            imageVector = Icons.Outlined.ChevronRight,
                            contentDescription = "View All",
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }
            
            // Transaction List
            items(filteredTransactions) { transaction ->
                TransactionItem(
                    transaction = transaction,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp)
                )
            }
            
            // Empty State
            if (filteredTransactions.isEmpty()) {
                item {
                    EmptyTransactions(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 40.dp)
                    )
                }
            }
        }
    }
    
    // Add Money Dialog
    if (showAddMoneyDialog) {
        AddMoneyDialog(
            onDismiss = { showAddMoneyDialog = false },
            onConfirm = { amount ->
                balance += amount
                showAddMoneyDialog = false
            }
        )
    }
    
    // Withdraw Dialog
    if (showWithdrawDialog) {
        WithdrawDialog(
            currentBalance = balance,
            onDismiss = { showWithdrawDialog = false },
            onConfirm = { amount ->
                balance -= amount
                showWithdrawDialog = false
            }
        )
    }
}

@Composable
fun WalletCard(
    balance: Double?,
    onVisibilityToggle: () -> Unit,
    modifier: Modifier = Modifier
) {
    val scale by animateFloatAsState(
        targetValue = if (balance != null) 1f else 0.98f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "card_scale"
    )
    
    FloatingGlassCard(
        modifier = modifier
            .fillMaxWidth()
            .scale(scale),
        shape = RoundedCornerShape(28.dp),
        backgroundColor = Brush.linearGradient(
            colors = listOf(
                RexoTheme.colorScheme.primary.copy(alpha = 0.9f),
                RexoTheme.colorScheme.secondary.copy(alpha = 0.9f),
                RexoTheme.colorScheme.tertiary.copy(alpha = 0.9f)
            )
        )
    ) {
        Column(
            modifier = Modifier.padding(28.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Available Balance",
                        style = RexoTheme.typography.bodyMedium,
                        color = Color.White.copy(alpha = 0.9f)
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    AnimatedContent(
                        targetState = balance,
                        transitionSpec = {
                            fadeIn() + scaleIn() togetherWith fadeOut() + scaleOut()
                        },
                        label = "balance"
                    ) { targetBalance ->
                        Text(
                            text = if (targetBalance != null) {
                                "₹${String.format("%,.2f", targetBalance)}"
                            } else {
                                "₹•••••••"
                            },
                            style = RexoTheme.typography.displayMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                }
                
                IconButton(
                    onClick = onVisibilityToggle,
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.2f))
                ) {
                    Icon(
                        imageVector = if (balance != null) Icons.Outlined.Visibility else Icons.Outlined.VisibilityOff,
                        contentDescription = "Toggle visibility",
                        tint = Color.White
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Account Type",
                        style = RexoTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.7f)
                    )
                    Text(
                        text = "Premium",
                        style = RexoTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                    )
                }
                
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "User ID",
                        style = RexoTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.7f)
                    )
                    Text(
                        text = "#RX12345",
                        style = RexoTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                    )
                }
            }
        }
    }
}

@Composable
fun QuickActions(
    onAddMoney: () -> Unit,
    onWithdraw: () -> Unit,
    onSend: () -> Unit,
    onRequest: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        QuickActionButton(
            icon = Icons.Outlined.Add,
            label = "Add Money",
            color = Color(0xFF10B981),
            onClick = onAddMoney,
            modifier = Modifier.weight(1f)
        )
        
        QuickActionButton(
            icon = Icons.Outlined.ArrowUpward,
            label = "Withdraw",
            color = RexoTheme.colorScheme.primary,
            onClick = onWithdraw,
            modifier = Modifier.weight(1f)
        )
        
        QuickActionButton(
            icon = Icons.Outlined.Send,
            label = "Send",
            color = RexoTheme.colorScheme.secondary,
            onClick = onSend,
            modifier = Modifier.weight(1f)
        )
        
        QuickActionButton(
            icon = Icons.Outlined.CallReceived,
            label = "Request",
            color = Color(0xFFF59E0B),
            onClick = onRequest,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
fun QuickActionButton(
    icon: ImageVector,
    label: String,
    color: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    GlassSurface(
        modifier = modifier.clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        backgroundColor = color.copy(alpha = 0.1f)
    ) {
        Column(
            modifier = Modifier.padding(vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Surface(
                shape = CircleShape,
                color = color.copy(alpha = 0.15f),
                modifier = Modifier.size(48.dp)
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = label,
                    modifier = Modifier.padding(12.dp),
                    tint = color
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = label,
                style = RexoTheme.typography.bodySmall,
                fontWeight = FontWeight.Medium,
                color = RexoTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
fun StatisticsRow(
    totalIncome: Double,
    totalExpense: Double,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        StatCard(
            title = "Total Income",
            amount = totalIncome,
            icon = Icons.Outlined.TrendingUp,
            color = Color(0xFF10B981),
            isPositive = true,
            modifier = Modifier.weight(1f)
        )
        
        StatCard(
            title = "Total Expense",
            amount = totalExpense,
            icon = Icons.Outlined.TrendingDown,
            color = Color(0xFFEF4444),
            isPositive = false,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
fun StatCard(
    title: String,
    amount: Double,
    icon: ImageVector,
    color: Color,
    isPositive: Boolean,
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
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    tint = color,
                    modifier = Modifier.size(24.dp)
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = title,
                style = RexoTheme.typography.bodySmall,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
            
            Text(
                text = "${if (isPositive) "+" else ""}₹${String.format("%,.0f", amount)}",
                style = RexoTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = color
            )
        }
    }
}

@Composable
fun FilterTabs(
    tabs: List<String>,
    selectedTab: Int,
    onTabSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        tabs.forEachIndexed { index, tab ->
            val isSelected = index == selectedTab
            
            val backgroundColor by animateColorAsState(
                targetValue = if (isSelected) RexoTheme.colorScheme.primary else RexoTheme.colorScheme.surfaceVariant,
                animationSpec = tween(300),
                label = "tab_bg"
            )
            
            val contentColor by animateColorAsState(
                targetValue = if (isSelected) RexoTheme.colorScheme.onPrimary else RexoTheme.colorScheme.onSurfaceVariant,
                animationSpec = tween(300),
                label = "tab_content"
            )
            
            Surface(
                modifier = Modifier.clickable { onTabSelected(index) },
                color = backgroundColor,
                shape = RoundedCornerShape(12.dp)
            ) {
                Text(
                    text = tab,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                    color = contentColor
                )
            }
        }
    }
}

enum class TransactionStatus {
    COMPLETED, PENDING, FAILED
}

data class Transaction(
    val title: String,
    val amount: Double,
    val category: String,
    val date: Date,
    val status: TransactionStatus
)

@Composable
fun TransactionItem(
    transaction: Transaction,
    modifier: Modifier = Modifier
) {
    val dateFormat = remember { SimpleDateFormat("MMM dd, hh:mm a", Locale.getDefault()) }
    val isPositive = transaction.amount > 0
    
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
                color = if (isPositive) Color(0xFF10B981).copy(alpha = 0.15f) else Color(0xFFEF4444).copy(alpha = 0.15f),
                modifier = Modifier.size(48.dp)
            ) {
                Icon(
                    imageVector = if (isPositive) Icons.Outlined.TrendingUp else Icons.Outlined.TrendingDown,
                    contentDescription = transaction.title,
                    modifier = Modifier.padding(12.dp),
                    tint = if (isPositive) Color(0xFF10B981) else Color(0xFFEF4444)
                )
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = transaction.title,
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = RexoTheme.colorScheme.onSurface
                )
                
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = dateFormat.format(transaction.date),
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    
                    if (transaction.status == TransactionStatus.PENDING) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Surface(
                            shape = RoundedCornerShape(4.dp),
                            color = Color(0xFFF59E0B).copy(alpha = 0.15f)
                        ) {
                            Text(
                                text = "Pending",
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                style = RexoTheme.typography.labelSmall,
                                color = Color(0xFFF59E0B)
                            )
                        }
                    }
                }
            }
            
            Text(
                text = "${if (isPositive) "+" else ""}₹${String.format("%,.2f", Math.abs(transaction.amount))}",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = if (isPositive) Color(0xFF10B981) else Color(0xFFEF4444)
            )
        }
    }
}

@Composable
fun EmptyTransactions(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Outlined.Receipt,
            contentDescription = "No transactions",
            modifier = Modifier.size(64.dp),
            tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.3f)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "No transactions yet",
            style = RexoTheme.typography.titleMedium,
            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddMoneyDialog(
    onDismiss: () -> Unit,
    onConfirm: (Double) -> Unit
) {
    var amount by remember { mutableStateOf("") }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "Add Money",
                style = RexoTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column {
                OutlinedTextField(
                    value = amount,
                    onValueChange = { amount = it.filter { char -> char.isDigit() || char == '.' } },
                    label = { Text("Amount") },
                    leadingIcon = {
                        Text("₹", style = RexoTheme.typography.titleMedium)
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    amount.toDoubleOrNull()?.let { onConfirm(it) }
                },
                enabled = amount.toDoubleOrNull() != null && amount.toDouble() > 0
            ) {
                Text("Add Money")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WithdrawDialog(
    currentBalance: Double,
    onDismiss: () -> Unit,
    onConfirm: (Double) -> Unit
) {
    var amount by remember { mutableStateOf("") }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "Withdraw Money",
                style = RexoTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column {
                Text(
                    text = "Available: ₹${String.format("%,.2f", currentBalance)}",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                
                Spacer(modifier = Modifier.height(12.dp))
                
                OutlinedTextField(
                    value = amount,
                    onValueChange = { amount = it.filter { char -> char.isDigit() || char == '.' } },
                    label = { Text("Amount") },
                    leadingIcon = {
                        Text("₹", style = RexoTheme.typography.titleMedium)
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    isError = amount.toDoubleOrNull()?.let { it > currentBalance } == true
                )
                
                if (amount.toDoubleOrNull()?.let { it > currentBalance } == true) {
                    Text(
                        text = "Insufficient balance",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.error,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    amount.toDoubleOrNull()?.let { onConfirm(it) }
                },
                enabled = amount.toDoubleOrNull()?.let { it > 0 && it <= currentBalance } == true
            ) {
                Text("Withdraw")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
