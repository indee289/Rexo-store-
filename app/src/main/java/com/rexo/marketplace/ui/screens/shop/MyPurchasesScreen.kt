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
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme
import java.text.SimpleDateFormat
import java.util.*

/**
 * My Purchases Screen
 * Features:
 * - Order history
 * - Order tracking
 * - Reorder functionality
 * - Order details
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyPurchasesScreen(
    onNavigateBack: () -> Unit = {}
) {
    var selectedTab by remember { mutableStateOf("all") }
    
    val orders = remember {
        listOf(
            Order(
                "ORD001",
                listOf("Premium Hoodie", "Phone Case"),
                1798.0,
                OrderStatus.DELIVERED,
                Date(System.currentTimeMillis() - 5 * 86400000)
            ),
            Order(
                "ORD002",
                listOf("Laptop Sticker Pack"),
                299.0,
                OrderStatus.IN_TRANSIT,
                Date(System.currentTimeMillis() - 2 * 86400000)
            ),
            Order(
                "ORD003",
                listOf("T-Shirt", "Cap"),
                1099.0,
                OrderStatus.PROCESSING,
                Date(System.currentTimeMillis() - 86400000)
            ),
            Order(
                "ORD004",
                listOf("Coffee Mug"),
                399.0,
                OrderStatus.CANCELLED,
                Date(System.currentTimeMillis() - 10 * 86400000)
            )
        )
    }
    
    val filteredOrders = when (selectedTab) {
        "active" -> orders.filter { 
            it.status == OrderStatus.PROCESSING || it.status == OrderStatus.IN_TRANSIT 
        }
        "completed" -> orders.filter { it.status == OrderStatus.DELIVERED }
        "cancelled" -> orders.filter { it.status == OrderStatus.CANCELLED }
        else -> orders
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "My Orders",
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
            // Filter Tabs
            ScrollableTabRow(
                selectedTabIndex = when(selectedTab) {
                    "all" -> 0
                    "active" -> 1
                    "completed" -> 2
                    "cancelled" -> 3
                    else -> 0
                },
                containerColor = Color.Transparent,
                edgePadding = 20.dp
            ) {
                Tab(
                    selected = selectedTab == "all",
                    onClick = { selectedTab = "all" },
                    text = { Text("All (${orders.size})") }
                )
                Tab(
                    selected = selectedTab == "active",
                    onClick = { selectedTab = "active" },
                    text = { 
                        Text("Active (${orders.count { 
                            it.status == OrderStatus.PROCESSING || it.status == OrderStatus.IN_TRANSIT 
                        }})")
                    }
                )
                Tab(
                    selected = selectedTab == "completed",
                    onClick = { selectedTab = "completed" },
                    text = { Text("Completed (${orders.count { it.status == OrderStatus.DELIVERED }})") }
                )
                Tab(
                    selected = selectedTab == "cancelled",
                    onClick = { selectedTab = "cancelled" },
                    text = { Text("Cancelled (${orders.count { it.status == OrderStatus.CANCELLED }})") }
                )
            }
            
            // Orders List
            if (filteredOrders.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.ShoppingBag,
                            contentDescription = "No orders",
                            modifier = Modifier.size(80.dp),
                            tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "No orders found",
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
                    items(filteredOrders) { order ->
                        OrderCard(
                            order = order,
                            onTrackOrder = { /* TODO */ },
                            onReorder = { /* TODO */ },
                            onViewDetails = { /* TODO */ }
                        )
                    }
                }
            }
        }
    }
}

data class Order(
    val id: String,
    val items: List<String>,
    val total: Double,
    val status: OrderStatus,
    val date: Date
)

enum class OrderStatus {
    PROCESSING, IN_TRANSIT, DELIVERED, CANCELLED
}

@Composable
fun OrderCard(
    order: Order,
    onTrackOrder: () -> Unit,
    onReorder: () -> Unit,
    onViewDetails: () -> Unit
) {
    val dateFormat = remember { SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()) }
    
    val (statusColor, statusIcon) = when (order.status) {
        OrderStatus.PROCESSING -> Pair(Color(0xFFF59E0B), Icons.Outlined.Schedule)
        OrderStatus.IN_TRANSIT -> Pair(Color(0xFF6366F1), Icons.Outlined.LocalShipping)
        OrderStatus.DELIVERED -> Pair(Color(0xFF10B981), Icons.Outlined.CheckCircle)
        OrderStatus.CANCELLED -> Pair(Color(0xFFEF4444), Icons.Outlined.Cancel)
    }
    
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Order ${order.id}",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = dateFormat.format(order.date),
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
                
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = statusColor.copy(alpha = 0.15f)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = statusIcon,
                            contentDescription = order.status.name,
                            modifier = Modifier.size(16.dp),
                            tint = statusColor
                        )
                        Text(
                            text = order.status.name.replace("_", " "),
                            style = RexoTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = statusColor
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Items
            GlassSurface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            ) {
                Column(
                    modifier = Modifier.padding(12.dp)
                ) {
                    order.items.take(2).forEach { item ->
                        Row(
                            modifier = Modifier.padding(vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.CheckCircle,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = RexoTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = item,
                                style = RexoTheme.typography.bodyMedium
                            )
                        }
                    }
                    
                    if (order.items.size > 2) {
                        Text(
                            text = "+${order.items.size - 2} more items",
                            style = RexoTheme.typography.bodySmall,
                            color = RexoTheme.colorScheme.primary,
                            modifier = Modifier.padding(start = 24.dp, top = 4.dp)
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Total
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Total Amount",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                Text(
                    text = "₹${String.format("%,.2f", order.total)}",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = RexoTheme.colorScheme.primary
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Actions
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                when (order.status) {
                    OrderStatus.PROCESSING, OrderStatus.IN_TRANSIT -> {
                        OutlinedButton(
                            onClick = onViewDetails,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("View Details")
                        }
                        Button(
                            onClick = onTrackOrder,
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.LocationOn,
                                contentDescription = "Track",
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Track Order")
                        }
                    }
                    OrderStatus.DELIVERED -> {
                        OutlinedButton(
                            onClick = onViewDetails,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("View Details")
                        }
                        Button(
                            onClick = onReorder,
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Refresh,
                                contentDescription = "Reorder",
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Reorder")
                        }
                    }
                    OrderStatus.CANCELLED -> {
                        OutlinedButton(
                            onClick = onViewDetails,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("View Details")
                        }
                        Button(
                            onClick = onReorder,
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.ShoppingCart,
                                contentDescription = "Buy Again",
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Buy Again")
                        }
                    }
                }
            }
        }
    }
}
