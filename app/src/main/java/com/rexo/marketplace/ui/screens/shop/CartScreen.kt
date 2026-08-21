package com.rexo.marketplace.ui.screens.shop

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.CartItemData
import com.rexo.marketplace.ui.viewmodel.ShopViewModel

/**
 * Cart Screen
 * Cart items list with quantity controls, total calculation, and checkout button.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CartScreen(
    onNavigateBack: () -> Unit = {},
    onCheckout: () -> Unit = {},
    viewModel: ShopViewModel
) {
    val cartItems by viewModel.cartItems.collectAsState()
    val cartTotal by viewModel.cartTotal.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Shopping Cart (${cartItems.size})",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (cartItems.isNotEmpty()) {
                        TextButton(onClick = { viewModel.clearCart() }) {
                            Text("Clear All", color = RexoColors.Error)
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        },
        bottomBar = {
            if (cartItems.isNotEmpty()) {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shadowElevation = 8.dp,
                    color = RexoTheme.colorScheme.surface
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(20.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "Total Amount",
                                style = RexoTheme.typography.bodySmall,
                                color = RexoColors.TextSecondary
                            )
                            Text(
                                text = "\u20B9${String.format("%,.2f", cartTotal)}",
                                style = RexoTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = RexoColors.AccentOrange
                            )
                        }

                        Button(
                            onClick = onCheckout,
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier.height(52.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = RexoColors.AccentOrange
                            )
                        ) {
                            Text(
                                text = "Proceed to Checkout",
                                modifier = Modifier.padding(horizontal = 16.dp),
                                style = RexoTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        }
    ) { paddingValues ->
        if (cartItems.isEmpty()) {
            // Empty Cart State
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Outlined.ShoppingCart,
                        contentDescription = "Empty Cart",
                        modifier = Modifier.size(100.dp),
                        tint = RexoColors.Gray300
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Text(
                        text = "Your cart is empty",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Add items to get started",
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Button(
                        onClick = onNavigateBack,
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = RexoColors.AccentOrange
                        )
                    ) {
                        Text("Continue Shopping")
                    }
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(cartItems, key = { it.id }) { item ->
                    CartItemCard(
                        item = item,
                        onQuantityChange = { newQty ->
                            viewModel.updateCartItemQuantity(item.id, newQty)
                        },
                        onRemove = {
                            viewModel.removeFromCart(item.id)
                        }
                    )
                }

                // Price breakdown
                item {
                    Spacer(modifier = Modifier.height(8.dp))
                    GlassSurface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text(
                                text = "Price Details",
                                style = RexoTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(12.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Subtotal", color = RexoColors.TextSecondary)
                                Text(
                                    "\u20B9${String.format("%,.2f", cartTotal)}",
                                    fontWeight = FontWeight.Medium
                                )
                            }

                            Spacer(modifier = Modifier.height(8.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("Delivery", color = RexoColors.TextSecondary)
                                Text(
                                    if (cartTotal >= 500) "FREE" else "\u20B940.00",
                                    fontWeight = FontWeight.Medium,
                                    color = if (cartTotal >= 500) RexoColors.Success else RexoColors.TextPrimary
                                )
                            }

                            Spacer(modifier = Modifier.height(12.dp))
                            HorizontalDivider()
                            Spacer(modifier = Modifier.height(12.dp))

                            val totalWithDelivery = if (cartTotal >= 500) cartTotal else cartTotal + 40.0
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    "Total",
                                    style = RexoTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    "\u20B9${String.format("%,.2f", totalWithDelivery)}",
                                    style = RexoTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = RexoColors.AccentOrange
                                )
                            }
                        }
                    }
                }

                // Spacer for bottom bar
                item {
                    Spacer(modifier = Modifier.height(80.dp))
                }
            }
        }
    }
}

@Composable
fun CartItemCard(
    item: CartItemData,
    onQuantityChange: (Int) -> Unit,
    onRemove: () -> Unit
) {
    GlassSurface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Product Image Placeholder
            Surface(
                modifier = Modifier.size(72.dp),
                shape = RoundedCornerShape(12.dp),
                color = RexoColors.Gray100
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Outlined.Image,
                        contentDescription = item.name,
                        modifier = Modifier.size(28.dp),
                        tint = RexoColors.Gray400
                    )
                }
            }

            // Product Details
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = item.name,
                        style = RexoTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.weight(1f)
                    )
                    IconButton(
                        onClick = onRemove,
                        modifier = Modifier.size(24.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Close,
                            contentDescription = "Remove",
                            tint = RexoColors.Error
                        )
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = "\u20B9${String.format("%,.2f", item.price)}",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.AccentOrange
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Quantity Controls
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    IconButton(
                        onClick = { if (item.quantity > 1) onQuantityChange(item.quantity - 1) },
                        modifier = Modifier.size(32.dp)
                    ) {
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = RexoColors.Gray100
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Remove,
                                contentDescription = "Decrease",
                                modifier = Modifier.padding(6.dp)
                            )
                        }
                    }

                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = RexoColors.AccentOrange.copy(alpha = 0.1f)
                    ) {
                        Text(
                            text = item.quantity.toString(),
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
                            style = RexoTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.AccentOrange
                        )
                    }

                    IconButton(
                        onClick = { onQuantityChange(item.quantity + 1) },
                        modifier = Modifier.size(32.dp)
                    ) {
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = RexoColors.Gray100
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Add,
                                contentDescription = "Increase",
                                modifier = Modifier.padding(6.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    Text(
                        text = "\u20B9${String.format("%,.2f", item.price * item.quantity)}",
                        style = RexoTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}
