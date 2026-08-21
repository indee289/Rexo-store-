package com.rexo.marketplace.ui.screens.profile

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
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Saved Items Screen (Wishlist)
 * Features:
 * - Saved campaigns
 * - Saved products
 * - Remove from saved
 * - Quick apply/buy
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SavedItemsScreen(
    onNavigateBack: () -> Unit = {}
) {
    var selectedTab by remember { mutableStateOf("campaigns") }
    
    val savedCampaigns = remember {
        mutableStateListOf(
            SavedItem("1", "Tech Product Launch", "Campaign", "₹5,000", "Fashion"),
            SavedItem("2", "Summer Collection", "Campaign", "₹3,500", "Fashion"),
            SavedItem("3", "Food Review", "Campaign", "₹2,000", "Food")
        )
    }
    
    val savedProducts = remember {
        mutableStateListOf(
            SavedItem("4", "Premium Hoodie", "Product", "₹1,299", "Apparel"),
            SavedItem("5", "Phone Case", "Product", "₹499", "Accessories")
        )
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Saved Items",
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Tab Selector
            TabRow(
                selectedTabIndex = if (selectedTab == "campaigns") 0 else 1,
                containerColor = Color.Transparent
            ) {
                Tab(
                    selected = selectedTab == "campaigns",
                    onClick = { selectedTab = "campaigns" },
                    text = { Text("Campaigns (${savedCampaigns.size})") }
                )
                Tab(
                    selected = selectedTab == "products",
                    onClick = { selectedTab = "products" },
                    text = { Text("Products (${savedProducts.size})") }
                )
            }
            
            // Content
            val items = if (selectedTab == "campaigns") savedCampaigns else savedProducts
            
            if (items.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.BookmarkBorder,
                            contentDescription = "No saved items",
                            modifier = Modifier.size(80.dp),
                            tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "No saved ${if (selectedTab == "campaigns") "campaigns" else "products"}",
                            style = RexoTheme.typography.titleMedium,
                            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    }
                }
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(20.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(items) { item ->
                        SavedItemCard(
                            item = item,
                            onRemove = {
                                if (selectedTab == "campaigns") {
                                    savedCampaigns.remove(item)
                                } else {
                                    savedProducts.remove(item)
                                }
                            },
                            onAction = { /* TODO: Navigate to detail */ }
                        )
                    }
                }
            }
        }
    }
}

data class SavedItem(
    val id: String,
    val title: String,
    val type: String,
    val price: String,
    val category: String
)

@Composable
fun SavedItemCard(
    item: SavedItem,
    onRemove: () -> Unit,
    onAction: () -> Unit
) {
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Image Placeholder
            Surface(
                modifier = Modifier.size(80.dp),
                shape = RoundedCornerShape(12.dp),
                color = RexoTheme.colorScheme.primaryContainer
            ) {
                Icon(
                    imageVector = if (item.type == "Campaign") Icons.Outlined.Campaign else Icons.Outlined.ShoppingBag,
                    contentDescription = item.type,
                    modifier = Modifier.padding(20.dp),
                    tint = RexoTheme.colorScheme.primary
                )
            }
            
            // Details
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = Color(0xFF6366F1).copy(alpha = 0.15f)
                    ) {
                        Text(
                            text = item.category,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            style = RexoTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF6366F1)
                        )
                    }
                    
                    IconButton(
                        onClick = onRemove,
                        modifier = Modifier.size(24.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.BookmarkRemove,
                            contentDescription = "Remove",
                            tint = Color(0xFFEF4444)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = item.title,
                    style = RexoTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold
                )
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = item.price,
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF10B981)
                )
                
                Spacer(modifier = Modifier.height(12.dp))
                
                Button(
                    onClick = onAction,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text(if (item.type == "Campaign") "Apply Now" else "Buy Now")
                }
            }
        }
    }
}
