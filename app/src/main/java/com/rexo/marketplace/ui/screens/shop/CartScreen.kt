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
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Shopping Cart Screen
 * Features:
 * - Cart item management
 * - Quantity adjustment
 * - Price calculation
 * - Checkout process
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CartScreen(
    onNavigateBack: () -> Unit = {},
    onCheckout: () -> Unit = {}
) {
    var cartItems by remember {
        mutableStateOf(
            listOf(
                CartItem("1", "Premium Hoodie", 1299.0, 2, "https://example.com/hoodie.jpg"),
                CartItem("2", "Phone Case", 499.0, 1, "https://example.com/case.jpg"),
                CartItem("3", "Laptop Sticker Pack", 299.0, 3, "https://example.com/stickers.jpg")
            )
        )
    }
    
    val subtotal = cartItems.sumOf { it.price * it.quantity }
    val delivery = if (subtotal > 500) 0.0 else 40.0
    val discount = if (subtotal > 1000) subtotal * 0.1 else 0.0
    val total = subtotal + delivery - discount
    
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
                        TextButton(onClick = { cartItems = emptyList() }) {
                            Text("Clear All")
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
                CheckoutBottomBar(
                    total = total,
                    onCheckout = onCheckout
                )
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
                        modifier = Modifier.size(120.dp),
                        tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Text(
                        text = "Your cart is empty",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "Add items to get started",
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Button(
                        onClick = onNavigateBack,
                        shape = RoundedCornerShape(12.dp)
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
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Cart Items
                items(cartItems) { item ->
                    CartItemCard(
                        item = item,
                        onQuantityChange = { newQuantity ->
                            cartItems = cartItems.map {
                                if (it.id == item.id) it.copy(quantity = newQuantity) else it
                            }
                        },
                        onRemove = {
                            cartItems = cartItems.filter { it.id != item.id }
                        }
                    )
                }
                
                // Price Breakdown
                item {
                    PriceBreakdownCard(
                        subtotal = subtotal,
                        delivery = delivery,
                        discount = discount,
                        total = total
                    )
                }
                
                // Spacer for bottom bar
                item {
                    Spacer(modifier = Modifier.height(80.dp))
                }
            }
        }
    }
}

data class CartItem(
    val id: String,
    val name: String,
    val price: Double,
    val quantity: Int,
    val imageUrl: String
)

@Composable
fun CartItemCard(
    item: CartItem,
    onQuantityChange: (Int) -> Unit,
    onRemove: () -> Unit
) {
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Product Image Placeholder
            Surface(
                modifier = Modifier.size(80.dp),
                shape = RoundedCornerShape(12.dp),
                color = RexoTheme.colorScheme.surfaceVariant
            ) {
                Icon(
                    imageVector = Icons.Outlined.Image,
                    contentDescription = item.name,
                    modifier = Modifier.padding(20.dp),
                    tint = RexoTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                )
            }
            
            // Product Details
            Column(
                modifier = Modifier.weight(1f)
            ) {
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
                            tint = Color(0xFFEF4444)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = "₹${String.format("%,.2f", item.price)}",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = RexoTheme.colorScheme.primary
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
                            color = RexoTheme.colorScheme.surfaceVariant
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
                        color = RexoTheme.colorScheme.primaryContainer
                    ) {
                        Text(
                            text = item.quantity.toString(),
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 6.dp),
                            style = RexoTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    
                    IconButton(
                        onClick = { onQuantityChange(item.quantity + 1) },
                        modifier = Modifier.size(32.dp)
                    ) {
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = RexoTheme.colorScheme.primaryContainer
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
                        text = "₹${String.format("%,.2f", item.price * item.quantity)}",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
fun PriceBreakdownCard(
    subtotal: Double,
    delivery: Double,
    discount: Double,
    total: Double
) {
    GlassSurface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Text(
                text = "Price Details",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            PriceRow(label = "Subtotal", value = subtotal)
            PriceRow(label = "Delivery", value = delivery, highlight = delivery == 0.0)
            if (discount > 0) {
                PriceRow(label = "Discount", value = -discount, isDiscount = true)
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            Divider()
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Total",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "₹${String.format("%,.2f", total)}",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = RexoTheme.colorScheme.primary
                )
            }
            
            if (delivery > 0) {
                Spacer(modifier = Modifier.height(12.dp))
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = Color(0xFF10B981).copy(alpha = 0.1f)
                ) {
                    Text(
                        text = "Add ₹${String.format("%.0f", 500 - subtotal)} more for FREE delivery!",
                        modifier = Modifier.padding(12.dp),
                        style = RexoTheme.typography.bodySmall,
                        fontWeight = FontWeight.Medium,
                        color = Color(0xFF10B981)
                    )
                }
            }
        }
    }
}

@Composable
fun PriceRow(
    label: String,
    value: Double,
    highlight: Boolean = false,
    isDiscount: Boolean = false
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = RexoTheme.typography.bodyMedium,
            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
        Text(
            text = if (value == 0.0 && highlight) 
                "FREE" 
            else 
                "${if (isDiscount) "-" else ""}₹${String.format("%,.2f", kotlin.math.abs(value))}",
            style = RexoTheme.typography.bodyMedium,
            fontWeight = if (highlight || isDiscount) FontWeight.Bold else FontWeight.Normal,
            color = when {
                highlight -> Color(0xFF10B981)
                isDiscount -> Color(0xFF10B981)
                else -> RexoTheme.colorScheme.onSurface
            },
            textDecoration = if (isDiscount && value > 0) TextDecoration.LineThrough else null
        )
    }
}

@Composable
fun CheckoutBottomBar(
    total: Double,
    onCheckout: () -> Unit
) {
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
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
                Text(
                    text = "₹${String.format("%,.2f", total)}",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = RexoTheme.colorScheme.primary
                )
            }
            
            Button(
                onClick = onCheckout,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.height(56.dp)
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
