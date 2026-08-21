package com.rexo.marketplace.ui.screens.wallet

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Deposit & Withdrawal Screen
 * Features:
 * - Add money to wallet
 * - Withdraw to bank account
 * - Payment method selection
 * - Transaction preview
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DepositWithdrawalScreen(
    initialTab: String = "deposit",
    onNavigateBack: () -> Unit = {}
) {
    var selectedTab by remember { mutableStateOf(initialTab) }
    var amount by remember { mutableStateOf("") }
    var selectedMethod by remember { mutableStateOf("UPI") }
    var upiId by remember { mutableStateOf("") }
    var accountNumber by remember { mutableStateOf("") }
    var ifscCode by remember { mutableStateOf("") }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (selectedTab == "deposit") "Add Money" else "Withdraw Money",
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
            // Tab Selector
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    FilterChip(
                        selected = selectedTab == "deposit",
                        onClick = { selectedTab = "deposit" },
                        label = { Text("Deposit") },
                        leadingIcon = {
                            Icon(
                                Icons.Outlined.Add,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                        },
                        modifier = Modifier.weight(1f)
                    )
                    FilterChip(
                        selected = selectedTab == "withdraw",
                        onClick = { selectedTab = "withdraw" },
                        label = { Text("Withdraw") },
                        leadingIcon = {
                            Icon(
                                Icons.Outlined.Remove,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                        },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
            
            // Amount Input
            item {
                FloatingGlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(20.dp)
                    ) {
                        Text(
                            text = "Enter Amount",
                            style = RexoTheme.typography.labelLarge,
                            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        OutlinedTextField(
                            value = amount,
                            onValueChange = { amount = it },
                            modifier = Modifier.fillMaxWidth(),
                            placeholder = { Text("₹ 0") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            textStyle = RexoTheme.typography.displaySmall.copy(fontWeight = FontWeight.Bold),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = RexoTheme.colorScheme.primary,
                                unfocusedBorderColor = RexoTheme.colorScheme.outline.copy(alpha = 0.3f)
                            )
                        )
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        // Quick Amount Buttons
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            listOf("500", "1000", "2000", "5000").forEach { quickAmount ->
                                OutlinedButton(
                                    onClick = { amount = quickAmount },
                                    modifier = Modifier.weight(1f),
                                    contentPadding = PaddingValues(8.dp)
                                ) {
                                    Text("₹$quickAmount", style = RexoTheme.typography.labelSmall)
                                }
                            }
                        }
                    }
                }
            }
            
            // Payment Method Selection
            item {
                Text(
                    text = if (selectedTab == "deposit") "Payment Method" else "Withdrawal Method",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            if (selectedTab == "deposit") {
                // Deposit Methods
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        PaymentMethodCard(
                            title = "UPI",
                            description = "Pay via Google Pay, PhonePe, Paytm",
                            icon = Icons.Outlined.AccountBalance,
                            selected = selectedMethod == "UPI",
                            onClick = { selectedMethod = "UPI" }
                        )
                        
                        PaymentMethodCard(
                            title = "Debit/Credit Card",
                            description = "Visa, Mastercard, Rupay",
                            icon = Icons.Outlined.CreditCard,
                            selected = selectedMethod == "Card",
                            onClick = { selectedMethod = "Card" }
                        )
                        
                        PaymentMethodCard(
                            title = "Net Banking",
                            description = "All major banks supported",
                            icon = Icons.Outlined.AccountBalance,
                            selected = selectedMethod == "NetBanking",
                            onClick = { selectedMethod = "NetBanking" }
                        )
                    }
                }
                
                // UPI ID Input
                if (selectedMethod == "UPI") {
                    item {
                        GlassSurface(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp)
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                OutlinedTextField(
                                    value = upiId,
                                    onValueChange = { upiId = it },
                                    modifier = Modifier.fillMaxWidth(),
                                    label = { Text("UPI ID") },
                                    placeholder = { Text("example@upi") },
                                    leadingIcon = {
                                        Icon(Icons.Outlined.AlternateEmail, contentDescription = null)
                                    }
                                )
                            }
                        }
                    }
                }
            } else {
                // Withdrawal Methods
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        PaymentMethodCard(
                            title = "Bank Account",
                            description = "Direct transfer to your account",
                            icon = Icons.Outlined.AccountBalance,
                            selected = selectedMethod == "Bank",
                            onClick = { selectedMethod = "Bank" }
                        )
                        
                        PaymentMethodCard(
                            title = "UPI",
                            description = "Transfer to UPI ID",
                            icon = Icons.Outlined.AccountBalance,
                            selected = selectedMethod == "UPI",
                            onClick = { selectedMethod = "UPI" }
                        )
                    }
                }
                
                // Bank Account Details
                if (selectedMethod == "Bank") {
                    item {
                        GlassSurface(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp)
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp),
                                verticalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                OutlinedTextField(
                                    value = accountNumber,
                                    onValueChange = { accountNumber = it },
                                    modifier = Modifier.fillMaxWidth(),
                                    label = { Text("Account Number") },
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                                )
                                
                                OutlinedTextField(
                                    value = ifscCode,
                                    onValueChange = { ifscCode = it },
                                    modifier = Modifier.fillMaxWidth(),
                                    label = { Text("IFSC Code") }
                                )
                            }
                        }
                    }
                }
                
                // UPI Details
                if (selectedMethod == "UPI") {
                    item {
                        GlassSurface(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp)
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                OutlinedTextField(
                                    value = upiId,
                                    onValueChange = { upiId = it },
                                    modifier = Modifier.fillMaxWidth(),
                                    label = { Text("UPI ID") },
                                    placeholder = { Text("example@upi") }
                                )
                            }
                        }
                    }
                }
            }
            
            // Transaction Summary
            if (amount.isNotEmpty() && amount.toDoubleOrNull() != null) {
                item {
                    TransactionSummaryCard(
                        amount = amount.toDouble(),
                        fees = if (selectedTab == "withdraw") 10.0 else 0.0,
                        isDeposit = selectedTab == "deposit"
                    )
                }
            }
            
            // Action Button
            item {
                Button(
                    onClick = { /* TODO: Process transaction */ },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    enabled = amount.isNotEmpty() && 
                             amount.toDoubleOrNull() != null &&
                             amount.toDouble() > 0,
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Text(
                        text = if (selectedTab == "deposit") "Add Money" else "Withdraw Money",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
fun PaymentMethodCard(
    title: String,
    description: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    selected: Boolean,
    onClick: () -> Unit
) {
    GlassSurface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        borderColor = if (selected) RexoTheme.colorScheme.primary else Color.Transparent
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = if (selected) 
                        RexoTheme.colorScheme.primaryContainer 
                    else 
                        RexoTheme.colorScheme.surfaceVariant
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = title,
                        modifier = Modifier.padding(12.dp),
                        tint = if (selected) 
                            RexoTheme.colorScheme.primary 
                        else 
                            RexoTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                Spacer(modifier = Modifier.width(16.dp))
                
                Column {
                    Text(
                        text = title,
                        style = RexoTheme.typography.bodyLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = description,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            }
            
            if (selected) {
                Icon(
                    imageVector = Icons.Outlined.CheckCircle,
                    contentDescription = "Selected",
                    tint = RexoTheme.colorScheme.primary
                )
            }
        }
    }
}

@Composable
fun TransactionSummaryCard(
    amount: Double,
    fees: Double,
    isDeposit: Boolean
) {
    val total = if (isDeposit) amount else amount - fees
    
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        backgroundColor = RexoTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Text(
                text = "Transaction Summary",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Amount",
                    style = RexoTheme.typography.bodyMedium
                )
                Text(
                    text = "₹${String.format("%,.2f", amount)}",
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }
            
            if (fees > 0) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Processing Fee",
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Text(
                        text = "- ₹${String.format("%,.2f", fees)}",
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            HorizontalDivider()
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = if (isDeposit) "You'll receive" else "You'll get",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "₹${String.format("%,.2f", total)}",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = if (isDeposit) Color(0xFF10B981) else RexoTheme.colorScheme.primary
                )
            }
        }
    }
}
