package com.rexo.marketplace.ui.screens.shop

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.LazyRow
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.ProductData
import com.rexo.marketplace.ui.viewmodel.ShopViewModel

/**
 * Shop Screen - Product catalog with search, category filters, and grid display.
 * Fetches real data from Supabase store_products table.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShopScreen(
    onNavigateBack: () -> Unit = {},
    onNavigateToProductDetail: (String) -> Unit = {},
    onNavigateToCart: () -> Unit = {},
    onNavigateToOrders: () -> Unit = {},
    viewModel: ShopViewModel
) {
    val uiState by viewModel.uiState.collectAsState()
    val products by viewModel.products.collectAsState()
    val categories by viewModel.categories.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()
    val selectedCategory by viewModel.selectedCategory.collectAsState()
    val cartCount by viewModel.cartCount.collectAsState()

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
                    IconButton(onClick = onNavigateToOrders) {
                        Icon(Icons.Outlined.Receipt, contentDescription = "My Orders")
                    }
                    IconButton(onClick = onNavigateToCart) {
                        BadgedBox(
                            badge = {
                                if (cartCount > 0) {
                                    Badge { Text("$cartCount") }
                                }
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Search Bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { viewModel.updateSearchQuery(it) },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 8.dp),
                placeholder = { Text("Search products...") },
                leadingIcon = {
                    Icon(Icons.Outlined.Search, contentDescription = "Search")
                },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { viewModel.updateSearchQuery("") }) {
                            Icon(Icons.Outlined.Close, contentDescription = "Clear")
                        }
                    }
                },
                shape = RoundedCornerShape(12.dp),
                singleLine = true
            )

            // Category Filter Chips
            LazyRow(
                contentPadding = PaddingValues(horizontal = 20.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(categories) { category ->
                    FilterChip(
                        selected = selectedCategory == category,
                        onClick = { viewModel.selectCategory(category) },
                        label = { Text(category) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = RexoColors.AccentOrange,
                            selectedLabelColor = Color.White
                        )
                    )
                }
            }

            // Content
            when {
                uiState.isLoading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = RexoColors.AccentOrange)
                    }
                }
                uiState.error != null -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
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
                            Button(onClick = { viewModel.loadProducts() }) {
                                Text("Retry")
                            }
                        }
                    }
                }
                products.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                imageVector = Icons.Outlined.ShoppingBag,
                                contentDescription = "No products",
                                modifier = Modifier.size(80.dp),
                                tint = RexoColors.Gray300
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                text = "No products found",
                                style = RexoTheme.typography.titleMedium,
                                color = RexoColors.TextSecondary
                            )
                        }
                    }
                }
                else -> {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(2),
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(20.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(products) { product ->
                            ProductCard(
                                product = product,
                                onProductClick = { onNavigateToProductDetail(product.id) },
                                onAddToCart = { viewModel.addToCart(product) }
                            )
                        }
                    }
                }
            }
        }
    }

    // Success snackbar
    if (uiState.showSuccess) {
        LaunchedEffect(uiState.showSuccess) {
            kotlinx.coroutines.delay(2000)
            viewModel.clearSuccess()
        }
    }
}

@Composable
fun ProductCard(
    product: ProductData,
    onProductClick: () -> Unit,
    onAddToCart: () -> Unit
) {
    GlassSurface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onProductClick() },
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
                color = RexoColors.Gray100
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Outlined.ShoppingBag,
                        contentDescription = product.title,
                        modifier = Modifier.size(40.dp),
                        tint = RexoColors.Gray400
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Category
            Text(
                text = product.category,
                style = RexoTheme.typography.labelSmall,
                color = RexoColors.AccentOrange
            )

            // Title
            Text(
                text = product.title,
                style = RexoTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(modifier = Modifier.height(6.dp))

            // Price
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                if (product.discountPrice != null) {
                    Text(
                        text = "\u20B9${String.format("%.0f", product.discountPrice)}",
                        style = RexoTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.Success
                    )
                    Text(
                        text = "\u20B9${String.format("%.0f", product.price)}",
                        style = RexoTheme.typography.bodySmall,
                        textDecoration = TextDecoration.LineThrough,
                        color = RexoColors.TextSecondary
                    )
                } else {
                    Text(
                        text = "\u20B9${String.format("%.0f", product.price)}",
                        style = RexoTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.Success
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Stock badge + Add to cart
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Stock badge
                Surface(
                    shape = RoundedCornerShape(6.dp),
                    color = if (product.stock > 0) RexoColors.Success.copy(alpha = 0.1f)
                    else RexoColors.Error.copy(alpha = 0.1f)
                ) {
                    Text(
                        text = if (product.stock > 0) "In Stock" else "Out of Stock",
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = RexoTheme.typography.labelSmall,
                        color = if (product.stock > 0) RexoColors.Success else RexoColors.Error,
                        fontWeight = FontWeight.Medium
                    )
                }

                // Add to cart button
                if (product.stock > 0) {
                    IconButton(
                        onClick = onAddToCart,
                        modifier = Modifier.size(32.dp)
                    ) {
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = RexoColors.AccentOrange
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Add,
                                contentDescription = "Add to cart",
                                modifier = Modifier.padding(6.dp),
                                tint = Color.White
                            )
                        }
                    }
                }
            }
        }
    }
}
