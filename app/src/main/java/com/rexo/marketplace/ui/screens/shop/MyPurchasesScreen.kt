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
import com.rexo.marketplace.ui.viewmodel.OrderData
import com.rexo.marketplace.ui.viewmodel.ShopViewModel

/**
 * My Purchases / Orders Screen
 * Shows orders from Supabase with status timeline.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyPurchasesScreen(
    onNavigateBack: () -> Unit = {},
    viewModel: ShopViewModel
) {
    val uiState by viewModel.uiState.collectAsState()
    val orders by viewModel.orders.collectAsState()
    var selectedTab by remember { mutableStateOf("all") }
    var expandedOrderId by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        viewModel.loadOrders()
    }

    val filteredOrders = when (selectedTab) {
        "active" -> orders.filter { it.status in listOf("placed", "confirmed", "shipped") }
        "delivered" -> orders.filter { it.status == "delivered" }
        "cancelled" -> orders.filter { it.status == "cancelled" }
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
                selectedTabIndex = when (selectedTab) {
                    "all" -> 0; "active" -> 1; "delivered" -> 2; "cancelled" -> 3; else -> 0
                },
                containerColor = Color.Transparent,
                edgePadding = 20.dp
            ) {
                Tab(
                    selected = selectedTab == "all",
                    onClick = { selectedTab = "all" },
                    text = { Text("All") }
                )
                Tab(
                    selected = selectedTab == "active",
                    onClick = { selectedTab = "active" },
                    text = { Text("Active") }
                )
                Tab(
                    selected = selectedTab == "delivered",
                    onClick = { selectedTab = "delivered" },
                    text = { Text("Delivered") }
                )
                Tab(
                    selected = selectedTab == "cancelled",
                    onClick = { selectedTab = "cancelled" },
                    text = { Text("Cancelled") }
                )
            }

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
                            Button(onClick = { viewModel.loadOrders() }) {
                                Text("Retry")
                            }
                        }
                    }
                }
                filteredOrders.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                imageVector = Icons.Outlined.ShoppingBag,
                                contentDescription = "No orders",
                                modifier = Modifier.size(80.dp),
                                tint = RexoColors.Gray300
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                text = "No orders found",
                                style = RexoTheme.typography.titleMedium,
                                color = RexoColors.TextSecondary
                            )
                        }
                    }
                }
                else -> {
                    LazyColumn(
                        contentPadding = PaddingValues(20.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(filteredOrders, key = { it.id }) { order ->
                            OrderCard(
                                order = order,
                                isExpanded = expandedOrderId == order.id,
                                onToggleExpand = {
                                    expandedOrderId = if (expandedOrderId == order.id) null else order.id
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun OrderCard(
    order: OrderData,
    isExpanded: Boolean,
    onToggleExpand: () -> Unit
) {
    val statusColor = when (order.status) {
        "placed" -> RexoColors.Warning
        "confirmed" -> Color(0xFF6366F1)
        "shipped" -> Color(0xFF3B82F6)
        "delivered" -> RexoColors.Success
        "cancelled" -> RexoColors.Error
        else -> RexoColors.TextSecondary
    }

    val statusIcon = when (order.status) {
        "placed" -> Icons.Outlined.Schedule
        "confirmed" -> Icons.Outlined.CheckCircle
        "shipped" -> Icons.Outlined.LocalShipping
        "delivered" -> Icons.Outlined.Done
        "cancelled" -> Icons.Outlined.Cancel
        else -> Icons.Outlined.Info
    }

    GlassSurface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Order ${order.id.take(16)}",
                        style = RexoTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                    if (order.createdAt.isNotEmpty()) {
                        Text(
                            text = order.createdAt.take(10),
                            style = RexoTheme.typography.bodySmall,
                            color = RexoColors.TextSecondary
                        )
                    }
                }

                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = statusColor.copy(alpha = 0.1f)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = statusIcon,
                            contentDescription = order.status,
                            modifier = Modifier.size(14.dp),
                            tint = statusColor
                        )
                        Text(
                            text = order.status.replaceFirstChar { it.uppercase() },
                            style = RexoTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = statusColor
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Items summary
            order.items.take(2).forEach { item ->
                Text(
                    text = item,
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoColors.TextSecondary
                )
            }
            if (order.items.size > 2) {
                Text(
                    text = "+${order.items.size - 2} more items",
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.AccentOrange
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Total
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Total",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoColors.TextSecondary
                )
                Text(
                    text = "\u20B9${String.format("%,.2f", order.total)}",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.AccentOrange
                )
            }

            // Expand/collapse for timeline
            Spacer(modifier = Modifier.height(8.dp))
            TextButton(
                onClick = onToggleExpand,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = if (isExpanded) "Hide Details" else "View Details",
                    color = RexoColors.AccentOrange
                )
                Icon(
                    imageVector = if (isExpanded) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore,
                    contentDescription = "Toggle",
                    tint = RexoColors.AccentOrange
                )
            }

            // Order Timeline (expanded)
            if (isExpanded) {
                Spacer(modifier = Modifier.height(8.dp))
                OrderTimeline(currentStatus = order.status)

                if (order.shippingAddress.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = "Shipping Address",
                        style = RexoTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = order.shippingAddress,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                }

                if (order.paymentMethod.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Payment: ${order.paymentMethod.uppercase()}",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                }
            }
        }
    }
}

@Composable
fun OrderTimeline(currentStatus: String) {
    val statuses = listOf("placed", "confirmed", "shipped", "delivered")
    val currentIndex = statuses.indexOf(currentStatus)

    Column(verticalArrangement = Arrangement.spacedBy(0.dp)) {
        statuses.forEachIndexed { index, status ->
            val isCompleted = index <= currentIndex
            val isCurrent = index == currentIndex
            val color = when {
                isCompleted -> RexoColors.Success
                else -> RexoColors.Gray300
            }

            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(vertical = 6.dp)
            ) {
                // Dot indicator
                Surface(
                    modifier = Modifier.size(if (isCurrent) 16.dp else 12.dp),
                    shape = RoundedCornerShape(50),
                    color = color
                ) {}

                Spacer(modifier = Modifier.width(12.dp))

                Text(
                    text = status.replaceFirstChar { it.uppercase() },
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = if (isCurrent) FontWeight.Bold else FontWeight.Normal,
                    color = if (isCompleted) RexoColors.TextPrimary else RexoColors.TextSecondary
                )

                if (isCompleted && !isCurrent) {
                    Spacer(modifier = Modifier.width(8.dp))
                    Icon(
                        imageVector = Icons.Outlined.Check,
                        contentDescription = "Done",
                        modifier = Modifier.size(16.dp),
                        tint = RexoColors.Success
                    )
                }
            }
        }
    }
}
