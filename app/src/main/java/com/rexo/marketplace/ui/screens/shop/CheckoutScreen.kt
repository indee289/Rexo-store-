package com.rexo.marketplace.ui.screens.shop

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.ShippingAddress
import com.rexo.marketplace.ui.viewmodel.ShopViewModel

/**
 * Checkout Screen
 * Delivery address form, payment method selection, and place order button.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CheckoutScreen(
    onNavigateBack: () -> Unit = {},
    onOrderPlaced: () -> Unit = {},
    viewModel: ShopViewModel
) {
    val uiState by viewModel.uiState.collectAsState()
    val cartItems by viewModel.cartItems.collectAsState()
    val cartTotal by viewModel.cartTotal.collectAsState()

    // Address form state
    var name by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    var city by remember { mutableStateOf("") }
    var state by remember { mutableStateOf("") }
    var pincode by remember { mutableStateOf("") }

    // Payment method
    var selectedPayment by remember { mutableStateOf("COD") }
    val paymentMethods = listOf(
        PaymentOption("Wallet Balance", "wallet", Icons.Outlined.AccountBalanceWallet),
        PaymentOption("UPI", "upi", Icons.Outlined.QrCode),
        PaymentOption("Cash on Delivery", "COD", Icons.Outlined.LocalAtm)
    )

    // Handle order success
    LaunchedEffect(uiState.showSuccess) {
        if (uiState.showSuccess && uiState.successMessage == "Order placed successfully!") {
            viewModel.clearSuccess()
            onOrderPlaced()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Checkout",
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
        if (cartItems.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        imageVector = Icons.Outlined.ShoppingCart,
                        contentDescription = "Empty cart",
                        modifier = Modifier.size(80.dp),
                        tint = RexoColors.Gray300
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Your cart is empty",
                        style = RexoTheme.typography.titleMedium,
                        color = RexoColors.TextSecondary
                    )
                }
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .verticalScroll(rememberScrollState())
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                // Delivery Address Section
                Text(
                    text = "Delivery Address",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )

                GlassSurface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        OutlinedTextField(
                            value = name,
                            onValueChange = { name = it },
                            label = { Text("Full Name") },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(10.dp),
                            singleLine = true
                        )

                        OutlinedTextField(
                            value = phone,
                            onValueChange = { phone = it },
                            label = { Text("Phone Number") },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(10.dp),
                            singleLine = true
                        )

                        OutlinedTextField(
                            value = address,
                            onValueChange = { address = it },
                            label = { Text("Address") },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(10.dp),
                            minLines = 2,
                            maxLines = 3
                        )

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            OutlinedTextField(
                                value = city,
                                onValueChange = { city = it },
                                label = { Text("City") },
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(10.dp),
                                singleLine = true
                            )
                            OutlinedTextField(
                                value = state,
                                onValueChange = { state = it },
                                label = { Text("State") },
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(10.dp),
                                singleLine = true
                            )
                        }

                        OutlinedTextField(
                            value = pincode,
                            onValueChange = { pincode = it },
                            label = { Text("Pincode") },
                            modifier = Modifier.fillMaxWidth(0.5f),
                            shape = RoundedCornerShape(10.dp),
                            singleLine = true
                        )
                    }
                }

                // Payment Method Section
                Text(
                    text = "Payment Method",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )

                GlassSurface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(modifier = Modifier.padding(8.dp)) {
                        paymentMethods.forEach { option ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .selectable(
                                        selected = selectedPayment == option.value,
                                        onClick = { selectedPayment = option.value },
                                        role = Role.RadioButton
                                    )
                                    .padding(horizontal = 12.dp, vertical = 14.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                RadioButton(
                                    selected = selectedPayment == option.value,
                                    onClick = null,
                                    colors = RadioButtonDefaults.colors(
                                        selectedColor = RexoColors.AccentOrange
                                    )
                                )
                                Icon(
                                    imageVector = option.icon,
                                    contentDescription = option.label,
                                    tint = if (selectedPayment == option.value) RexoColors.AccentOrange
                                    else RexoColors.TextSecondary
                                )
                                Text(
                                    text = option.label,
                                    style = RexoTheme.typography.bodyLarge,
                                    fontWeight = if (selectedPayment == option.value) FontWeight.Bold
                                    else FontWeight.Normal
                                )
                            }
                        }
                    }
                }

                // Order Summary
                Text(
                    text = "Order Summary",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )

                GlassSurface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        cartItems.forEach { item ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    text = "${item.name} x${item.quantity}",
                                    style = RexoTheme.typography.bodyMedium,
                                    color = RexoColors.TextSecondary,
                                    modifier = Modifier.weight(1f)
                                )
                                Text(
                                    text = "\u20B9${String.format("%,.2f", item.price * item.quantity)}",
                                    style = RexoTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                        HorizontalDivider()
                        Spacer(modifier = Modifier.height(12.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "Total",
                                style = RexoTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "\u20B9${String.format("%,.2f", cartTotal)}",
                                style = RexoTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = RexoColors.AccentOrange
                            )
                        }
                    }
                }

                // Error message
                if (uiState.error != null) {
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        color = RexoColors.Error.copy(alpha = 0.1f)
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.ErrorOutline,
                                contentDescription = "Error",
                                tint = RexoColors.Error,
                                modifier = Modifier.size(20.dp)
                            )
                            Text(
                                text = uiState.error ?: "",
                                style = RexoTheme.typography.bodySmall,
                                color = RexoColors.Error
                            )
                        }
                    }
                }

                // Place Order Button
                val isFormValid = name.isNotBlank() && phone.isNotBlank() &&
                    address.isNotBlank() && city.isNotBlank() && pincode.isNotBlank()

                Button(
                    onClick = {
                        val shippingAddr = ShippingAddress(
                            name = name,
                            phone = phone,
                            address = address,
                            city = city,
                            state = state,
                            pincode = pincode
                        )
                        viewModel.placeOrder(shippingAddr, selectedPayment)
                    },
                    enabled = isFormValid && !uiState.isProcessing,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = RexoColors.AccentOrange
                    )
                ) {
                    if (uiState.isProcessing) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = Color.White,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Icon(
                            imageVector = Icons.Outlined.CheckCircle,
                            contentDescription = "Place Order",
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Place Order",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))
            }
        }
    }
}

private data class PaymentOption(
    val label: String,
    val value: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector
)
