package com.rexo.marketplace.ui.screens.shop

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Shop Screen - Product catalog and orders
 * Features:
 * - Product grid
 * - Add to cart
 * - View orders
 * - Product details
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShopScreen(
    onNavigateBack: () -> Unit = {}
) {
    val products = remember {
        listOf(
            Product("1", "Rexo T-Shirt", 499.0, "Clothing"),
            Product("2", "Rexo Hoodie", 1299.0, "Clothing"),
            Product("3", "Rexo Cap", 349.0, "Accessories"),
            Product("4", "Rexo Mug", 249.0, "Accessories"),
            Product("5", "Rexo Stickers Pack", 99.0, "Accessories"),
            Product("6", "Rexo Notebook", 199.0, "Stationery")
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Shop",
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
                    IconButton(onClick = { /* TODO: Cart */ }) {
                        BadgedBox(
                            badge = {
                                Badge { Text("3") }
                            }
                        ) {
                            Icon(Icons.Outlined.ShoppingCart, contentDescription = "Cart")
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        }
    ) { paddingValues ->
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(20.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(products) { product ->
                ProductCard(
                    product = product,
                    onAddToCart = { /* TODO */ }
                )
            }
        }
    }
}

data class Product(
    val id: String,
    val name: String,
    val price: Double,
    val category: String
)

@Composable
fun ProductCard(
    product: Product,
    onAddToCart: () -> Unit
) {
    FloatingGlassCard(
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            // Product Image Placeholder
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(1f),
                shape = RoundedCornerShape(12.dp),
                color = RexoTheme.colorScheme.primaryContainer
            ) {
                Icon(
                    imageVector = Icons.Outlined.ShoppingBag,
                    contentDescription = product.name,
                    modifier = Modifier.padding(32.dp)
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = product.category,
                style = RexoTheme.typography.labelSmall,
                color = RexoTheme.colorScheme.primary
            )
            
            Text(
                text = product.name,
                style = RexoTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "₹${String.format("%.0f", product.price)}",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF10B981)
                )
                
                IconButton(
                    onClick = onAddToCart,
                    modifier = Modifier.size(32.dp)
                ) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = RexoTheme.colorScheme.primary
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Add,
                            contentDescription = "Add to cart",
                            modifier = Modifier.padding(6.dp),
                            tint = RexoTheme.colorScheme.onPrimary
                        )
                    }
                }
            }
        }
    }
}
