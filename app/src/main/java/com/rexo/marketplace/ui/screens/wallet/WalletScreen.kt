package com.rexo.marketplace.ui.screens.wallet

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rexo.marketplace.data.repository.TransactionDto
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.WalletViewModel
import java.text.SimpleDateFormat
import java.util.*

/**
 * Wallet Screen - Clean white minimal design
 * Shows real balance from Supabase 'wallets' table
 * Lists real transactions from Supabase 'transactions' table
 * Supports deposit and withdrawal operations
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WalletScreen(
    onNavigateBack: () -> Unit = {},
    walletViewModel: WalletViewModel = viewModel()
) {
    val uiState by walletViewModel.uiState.collectAsState()
    var selectedTab by remember { mutableStateOf(0) }
    var showAddMoneyDialog by remember { mutableStateOf(false) }
    var showWithdrawDialog by remember { mutableStateOf(false) }

    val tabs = listOf("All", "Income", "Expense", "Pending")

    // Filter transactions based on selected tab
    val filteredTransactions = remember(selectedTab, uiState.transactions) {
        when (tabs[selectedTab]) {
            "Income" -> uiState.transactions.filter {
                it.type.equals("credit", ignoreCase = true) ||
                    it.type.equals("earning", ignoreCase = true) ||
                    it.type.equals("payment", ignoreCase = true)
            }
            "Expense" -> uiState.transactions.filter {
                it.type.equals("debit", ignoreCase = true) ||
                    it.type.equals("withdrawal", ignoreCase = true)
            }
            "Pending" -> uiState.transactions.filter {
                it.status.equals("pending", ignoreCase = true)
            }
            else -> uiState.transactions
        }
    }

    // Show success snackbar
    LaunchedEffect(uiState.successMessage) {
        if (uiState.successMessage != null) {
            kotlinx.coroutines.delay(3000)
            walletViewModel.clearSuccess()
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
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        }
    ) { paddingValues ->
        when {
            uiState.isLoading -> {
                // Loading state
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        CircularProgressIndicator(
                            color = RexoColors.AccentOrange
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Loading wallet...",
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextSecondary
                        )
                    }
                }
            }

            uiState.error != null && uiState.wallet == null -> {
                // Error state
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(32.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.ErrorOutline,
                            contentDescription = "Error",
                            modifier = Modifier.size(64.dp),
                            tint = RexoColors.Error
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Something went wrong",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Could not load your wallet. Please try again.",
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextSecondary,
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(24.dp))
                        Button(
                            onClick = { walletViewModel.loadWalletData() },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = RexoColors.AccentOrange
                            )
                        ) {
                            Text("Retry")
                        }
                    }
                }
            }

            else -> {
                // Content
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentPadding = PaddingValues(bottom = 80.dp)
                ) {
                    // Balance Card
                    item {
                        BalanceCard(
                            availableBalance = uiState.wallet?.available_balance ?: 0.0,
                            escrowBalance = uiState.wallet?.escrow_balance ?: 0.0,
                            totalEarnings = uiState.wallet?.total_earnings ?: 0.0,
                            currency = uiState.wallet?.currency ?: "INR",
                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 16.dp)
                        )
                    }

                    // Quick Actions
                    item {
                        QuickActions(
                            onAddMoney = { showAddMoneyDialog = true },
                            onWithdraw = { showWithdrawDialog = true },
                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                        )
                    }

                    // Success message
                    if (uiState.successMessage != null) {
                        item {
                            GlassSurface(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 20.dp, vertical = 8.dp),
                                shape = RoundedCornerShape(12.dp),
                                backgroundColor = RexoColors.SuccessLight,
                                borderColor = RexoColors.Success
                            ) {
                                Row(
                                    modifier = Modifier.padding(16.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = Icons.Filled.CheckCircle,
                                        contentDescription = "Success",
                                        tint = RexoColors.Success,
                                        modifier = Modifier.size(20.dp)
                                    )
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Text(
                                        text = uiState.successMessage ?: "",
                                        style = RexoTheme.typography.bodyMedium,
                                        color = RexoColors.Success
                                    )
                                }
                            }
                        }
                    }

                    // Filter Tabs
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
                        Text(
                            text = "Transactions",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
                        )
                    }

                    // Transaction List
                    if (filteredTransactions.isEmpty()) {
                        item {
                            EmptyTransactions(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 40.dp)
                            )
                        }
                    } else {
                        items(filteredTransactions) { transaction ->
                            TransactionItem(
                                transaction = transaction,
                                modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp)
                            )
                        }
                    }
                }
            }
        }
    }

    // Add Money Dialog
    if (showAddMoneyDialog) {
        AddMoneyDialog(
            isProcessing = uiState.isProcessing,
            onDismiss = { showAddMoneyDialog = false },
            onConfirm = { amount, method ->
                walletViewModel.depositMoney(amount, method)
                showAddMoneyDialog = false
            }
        )
    }

    // Withdraw Dialog
    if (showWithdrawDialog) {
        WithdrawDialog(
            currentBalance = uiState.wallet?.available_balance ?: 0.0,
            isProcessing = uiState.isProcessing,
            onDismiss = { showWithdrawDialog = false },
            onConfirm = { amount, method, details ->
                walletViewModel.withdrawMoney(amount, method, details)
                showWithdrawDialog = false
            }
        )
    }
}

@Composable
private fun BalanceCard(
    availableBalance: Double,
    escrowBalance: Double,
    totalEarnings: Double,
    currency: String,
    modifier: Modifier = Modifier
) {
    val currencySymbol = if (currency == "INR") "₹" else "$"

    GlassSurface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(24.dp)
        ) {
            Text(
                text = "Available Balance",
                style = RexoTheme.typography.bodyMedium,
                color = RexoColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "$currencySymbol${String.format("%,.2f", availableBalance)}",
                style = RexoTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            Spacer(modifier = Modifier.height(20.dp))

            Divider(color = RexoColors.CardBorder)

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Pending",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                    Text(
                        text = "$currencySymbol${String.format("%,.2f", escrowBalance)}",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.Warning
                    )
                }

                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "Total Earnings",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                    Text(
                        text = "$currencySymbol${String.format("%,.2f", totalEarnings)}",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.Success
                    )
                }
            }
        }
    }
}

@Composable
private fun QuickActions(
    onAddMoney: () -> Unit,
    onWithdraw: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        QuickActionButton(
            icon = Icons.Outlined.Add,
            label = "Add Money",
            color = RexoColors.Success,
            onClick = onAddMoney,
            modifier = Modifier.weight(1f)
        )

        QuickActionButton(
            icon = Icons.Outlined.ArrowUpward,
            label = "Withdraw",
            color = RexoColors.AccentOrange,
            onClick = onWithdraw,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun QuickActionButton(
    icon: ImageVector,
    label: String,
    color: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    GlassSurface(
        modifier = modifier.clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Surface(
                shape = CircleShape,
                color = color.copy(alpha = 0.1f),
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
                color = RexoColors.TextPrimary,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun FilterTabs(
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
                targetValue = if (isSelected) RexoColors.AccentOrange else RexoColors.Gray100,
                animationSpec = tween(300),
                label = "tab_bg"
            )

            val contentColor by animateColorAsState(
                targetValue = if (isSelected) Color.White else RexoColors.TextSecondary,
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

@Composable
private fun TransactionItem(
    transaction: TransactionDto,
    modifier: Modifier = Modifier
) {
    val isCredit = transaction.type.equals("credit", ignoreCase = true) ||
        transaction.type.equals("earning", ignoreCase = true) ||
        transaction.type.equals("payment", ignoreCase = true)

    val amountColor = if (isCredit) RexoColors.Success else RexoColors.Error
    val iconTint = if (isCredit) RexoColors.Success else RexoColors.Error
    val iconBg = if (isCredit) RexoColors.SuccessLight else RexoColors.ErrorLight
    val icon = if (isCredit) Icons.Outlined.TrendingUp else Icons.Outlined.TrendingDown

    val formattedDate = remember(transaction.created_at) {
        try {
            val inputFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
            val outputFormat = SimpleDateFormat("MMM dd, hh:mm a", Locale.getDefault())
            val date = inputFormat.parse(transaction.created_at)
            if (date != null) outputFormat.format(date) else transaction.created_at
        } catch (e: Exception) {
            transaction.created_at.take(10)
        }
    }

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
                color = iconBg,
                modifier = Modifier.size(44.dp)
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = transaction.title,
                    modifier = Modifier.padding(10.dp),
                    tint = iconTint
                )
            }

            Spacer(modifier = Modifier.width(14.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = transaction.title.ifEmpty { transaction.type },
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = RexoColors.TextPrimary
                )

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = formattedDate,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )

                    // Status badge
                    if (!transaction.status.equals("completed", ignoreCase = true)) {
                        Spacer(modifier = Modifier.width(8.dp))
                        StatusBadge(status = transaction.status)
                    }
                }
            }

            Text(
                text = "${if (isCredit) "+" else "-"}₹${String.format("%,.2f", kotlin.math.abs(transaction.amount))}",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = amountColor
            )
        }
    }
}

@Composable
private fun StatusBadge(status: String) {
    val (bgColor, textColor) = when (status.lowercase()) {
        "pending" -> Pair(RexoColors.WarningLight, RexoColors.Warning)
        "failed" -> Pair(RexoColors.ErrorLight, RexoColors.Error)
        else -> Pair(RexoColors.Gray100, RexoColors.TextSecondary)
    }

    Surface(
        shape = RoundedCornerShape(4.dp),
        color = bgColor
    ) {
        Text(
            text = status.replaceFirstChar { it.uppercase() },
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
            style = RexoTheme.typography.labelSmall,
            color = textColor
        )
    }
}

@Composable
private fun EmptyTransactions(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Outlined.Receipt,
            contentDescription = "No transactions",
            modifier = Modifier.size(56.dp),
            tint = RexoColors.Gray300
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "No transactions yet",
            style = RexoTheme.typography.titleMedium,
            color = RexoColors.TextSecondary
        )

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = "Your transactions will appear here",
            style = RexoTheme.typography.bodySmall,
            color = RexoColors.Gray400
        )
    }
}

@Composable
private fun AddMoneyDialog(
    isProcessing: Boolean,
    onDismiss: () -> Unit,
    onConfirm: (Double, String) -> Unit
) {
    var amount by remember { mutableStateOf("") }
    var selectedMethod by remember { mutableStateOf("UPI") }

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
                        Text(
                            "₹",
                            style = RexoTheme.typography.titleMedium,
                            color = RexoColors.TextSecondary
                        )
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    enabled = !isProcessing
                )

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = "Payment Method",
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )

                Spacer(modifier = Modifier.height(8.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("UPI", "Bank", "Card").forEach { method ->
                        FilterChip(
                            selected = selectedMethod == method,
                            onClick = { selectedMethod = method },
                            label = { Text(method) },
                            enabled = !isProcessing
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    amount.toDoubleOrNull()?.let { onConfirm(it, selectedMethod) }
                },
                enabled = !isProcessing && amount.toDoubleOrNull() != null && (amount.toDoubleOrNull() ?: 0.0) > 0,
                colors = ButtonDefaults.buttonColors(
                    containerColor = RexoColors.AccentOrange
                )
            ) {
                if (isProcessing) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("Add Money")
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss, enabled = !isProcessing) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun WithdrawDialog(
    currentBalance: Double,
    isProcessing: Boolean,
    onDismiss: () -> Unit,
    onConfirm: (Double, String, String) -> Unit
) {
    var amount by remember { mutableStateOf("") }
    var selectedMethod by remember { mutableStateOf("UPI") }
    var payoutDetails by remember { mutableStateOf("") }

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
                    color = RexoColors.TextSecondary
                )

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = amount,
                    onValueChange = { amount = it.filter { char -> char.isDigit() || char == '.' } },
                    label = { Text("Amount") },
                    leadingIcon = {
                        Text(
                            "₹",
                            style = RexoTheme.typography.titleMedium,
                            color = RexoColors.TextSecondary
                        )
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    isError = amount.toDoubleOrNull()?.let { it > currentBalance } == true,
                    enabled = !isProcessing
                )

                if (amount.toDoubleOrNull()?.let { it > currentBalance } == true) {
                    Text(
                        text = "Insufficient balance",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.Error,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = "Payout Method",
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )

                Spacer(modifier = Modifier.height(8.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("UPI", "Bank", "PayPal").forEach { method ->
                        FilterChip(
                            selected = selectedMethod == method,
                            onClick = { selectedMethod = method },
                            label = { Text(method) },
                            enabled = !isProcessing
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = payoutDetails,
                    onValueChange = { payoutDetails = it },
                    label = {
                        Text(
                            when (selectedMethod) {
                                "UPI" -> "UPI ID"
                                "Bank" -> "Account Number"
                                else -> "PayPal Email"
                            }
                        )
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    enabled = !isProcessing
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    amount.toDoubleOrNull()?.let { onConfirm(it, selectedMethod, payoutDetails) }
                },
                enabled = !isProcessing &&
                    amount.toDoubleOrNull()?.let { it > 0 && it <= currentBalance } == true &&
                    payoutDetails.isNotBlank(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = RexoColors.AccentOrange
                )
            ) {
                if (isProcessing) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("Withdraw")
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss, enabled = !isProcessing) {
                Text("Cancel")
            }
        }
    )
}
