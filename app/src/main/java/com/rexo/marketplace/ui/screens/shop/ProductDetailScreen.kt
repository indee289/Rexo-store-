package com.rexo.marketplace.ui.screens.shop

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.ShopViewModel

/**
 * Product Detail Screen
 * Full product view with image, description, price, and Add to Cart / Buy Now buttons.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductDetailScreen(
    productId: String,
    onNavigateBack: () -> Unit = {},
    onNavigateToCart: () -> Unit = {},
    viewModel: ShopViewModel
) {
    val uiState by viewModel.uiState.collectAsState()
    val product by viewModel.selectedProduct.collectAsState()
    var quantity by remember { mutableStateOf(1) }

    LaunchedEffect(productId) {
        viewModel.loadProductById(productId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Product Details") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToCart) {
                        Icon(Icons.Outlined.ShoppingCart, contentDescription = "Cart")
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
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = RexoColors.AccentOrange)
                }
            }
            uiState.error != null -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Outlined.ErrorOutline,
                            contentDescription = "Error",
                            modifier = Modifier.size(64.dp),
                            tint = RexoColors.Error
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = uiState.error ?: "Something went wrong",
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextSecondary
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = { viewModel.loadProductById(productId) }) {
                            Text("Retry")
                        }
                    }
                }
            }
            product == null -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Product not found",
                        style = RexoTheme.typography.bodyLarge,
                        color = RexoColors.TextSecondary
                    )
                }
            }
            else -> {
                val prod = product!!
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .verticalScroll(rememberScrollState())
                ) {
                    // Product Image
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(300.dp),
                        color = RexoColors.Gray100
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Outlined.Image,
                                contentDescription = prod.title,
                                modifier = Modifier.size(80.dp),
                                tint = RexoColors.Gray400
                            )
                        }
                    }

                    Column(
                        modifier = Modifier.padding(20.dp)
                    ) {
                        // Category
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = RexoColors.AccentOrange.copy(alpha = 0.1f)
                        ) {
                            Text(
                                text = prod.category,
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                                style = RexoTheme.typography.labelSmall,
                                color = RexoColors.AccentOrange,
                                fontWeight = FontWeight.Medium
                            )
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Title
                        Text(
                            text = prod.title,
                            style = RexoTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold
                        )

                        Spacer(modifier = Modifier.height(12.dp))

                        // Price
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            if (prod.discountPrice != null) {
                                Text(
                                    text = "\u20B9${String.format("%.0f", prod.discountPrice)}",
                                    style = RexoTheme.typography.headlineMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = RexoColors.AccentOrange
                                )
                                Text(
                                    text = "\u20B9${String.format("%.0f", prod.price)}",
                                    style = RexoTheme.typography.titleMedium,
                                    textDecoration = TextDecoration.LineThrough,
                                    color = RexoColors.TextSecondary
                                )
                                val discount = ((prod.price - prod.discountPrice) / prod.price * 100).toInt()
                                Surface(
                                    shape = RoundedCornerShape(6.dp),
                                    color = RexoColors.Success.copy(alpha = 0.1f)
                                ) {
                                    Text(
                                        text = "$discount% OFF",
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                        style = RexoTheme.typography.labelSmall,
                                        color = RexoColors.Success,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                            } else {
                                Text(
                                    text = "\u20B9${String.format("%.0f", prod.price)}",
                                    style = RexoTheme.typography.headlineMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = RexoColors.AccentOrange
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(16.dp))

                        // Stock Status
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = if (prod.stock > 0) Icons.Outlined.CheckCircle else Icons.Outlined.Cancel,
                                contentDescription = "Stock",
                                modifier = Modifier.size(20.dp),
                                tint = if (prod.stock > 0) RexoColors.Success else RexoColors.Error
                            )
                            Text(
                                text = if (prod.stock > 0) "In Stock (${prod.stock} available)" else "Out of Stock",
                                style = RexoTheme.typography.bodyMedium,
                                color = if (prod.stock > 0) RexoColors.Success else RexoColors.Error,
                                fontWeight = FontWeight.Medium
                            )
                        }

                        Spacer(modifier = Modifier.height(20.dp))

                        // Description
                        Text(
                            text = "Description",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = prod.description.ifEmpty { "No description available." },
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextSecondary
                        )

                        Spacer(modifier = Modifier.height(24.dp))

                        // Quantity Selector
                        if (prod.stock > 0) {
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
                                    Text(
                                        text = "Quantity",
                                        style = RexoTheme.typography.bodyLarge,
                                        fontWeight = FontWeight.Medium
                                    )

                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                                    ) {
                                        IconButton(
                                            onClick = { if (quantity > 1) quantity-- },
                                            modifier = Modifier.size(36.dp)
                                        ) {
                                            Surface(
                                                shape = RoundedCornerShape(8.dp),
                                                color = RexoColors.Gray100
                                            ) {
                                                Icon(
                                                    imageVector = Icons.Outlined.Remove,
                                                    contentDescription = "Decrease",
                                                    modifier = Modifier.padding(8.dp)
                                                )
                                            }
                                        }

                                        Text(
                                            text = quantity.toString(),
                                            style = RexoTheme.typography.titleMedium,
                                            fontWeight = FontWeight.Bold
                                        )

                                        IconButton(
                                            onClick = { if (quantity < prod.stock) quantity++ },
                                            modifier = Modifier.size(36.dp)
                                        ) {
                                            Surface(
                                                shape = RoundedCornerShape(8.dp),
                                                color = RexoColors.Gray100
                                            ) {
                                                Icon(
                                                    imageVector = Icons.Outlined.Add,
                                                    contentDescription = "Increase",
                                                    modifier = Modifier.padding(8.dp)
                                                )
                                            }
                                        }
                                    }
                                }
                            }

                            Spacer(modifier = Modifier.height(24.dp))

                            // Add to Cart Button
                            OutlinedButton(
                                onClick = {
                                    viewModel.addToCart(prod, quantity)
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(52.dp),
                                shape = RoundedCornerShape(12.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Outlined.ShoppingCart,
                                    contentDescription = "Add to Cart",
                                    modifier = Modifier.size(20.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "Add to Cart",
                                    style = RexoTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                            }

                            Spacer(modifier = Modifier.height(12.dp))

                            // Buy Now Button
                            Button(
                                onClick = {
                                    viewModel.addToCart(prod, quantity)
                                    onNavigateToCart()
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(52.dp),
                                shape = RoundedCornerShape(12.dp),
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = RexoColors.AccentOrange
                                )
                            ) {
                                Icon(
                                    imageVector = Icons.Outlined.ShoppingBag,
                                    contentDescription = "Buy Now",
                                    modifier = Modifier.size(20.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "Buy Now",
                                    style = RexoTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(32.dp))
                    }
                }
            }
        }
    }
}
