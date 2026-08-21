package com.rexo.marketplace.ui.screens.wallet

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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

/**
 * Wallet Analytics Screen
 * Features:
 * - Spending analytics
 * - Income breakdown
 * - Monthly trends
 * - Category wise spending
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WalletAnalyticsScreen(
    onNavigateBack: () -> Unit = {}
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Wallet Analytics",
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
            // Time Period Selector
            item {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("Week", "Month", "Year").forEach { period ->
                        FilterChip(
                            selected = period == "Month",
                            onClick = { /* TODO */ },
                            label = { Text(period) }
                        )
                    }
                }
            }
            
            // Income vs Expense
            item {
                IncomeExpenseCard(
                    income = 45000.0,
                    expense = 12000.0
                )
            }
            
            // Category Breakdown
            item {
                Text(
                    text = "Spending by Category",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            item {
                CategoryBreakdownCard(
                    categories = listOf(
                        CategorySpending("Campaign Fees", 5000.0, Color(0xFF6366F1)),
                        CategorySpending("Withdrawals", 4000.0, Color(0xFF10B981)),
                        CategorySpending("Shop Purchases", 2000.0, Color(0xFFF59E0B)),
                        CategorySpending("Other", 1000.0, Color(0xFFEF4444))
                    )
                )
            }
            
            // Monthly Trends
            item {
                Text(
                    text = "Monthly Trends",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            item {
                MonthlyTrendsCard(
                    months = listOf("Jan", "Feb", "Mar", "Apr", "May", "Jun"),
                    values = listOf(12000.0, 15000.0, 18000.0, 14000.0, 20000.0, 25000.0)
                )
            }
            
            // Top Transactions
            item {
                Text(
                    text = "Top Transactions",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            items(3) { index ->
                TopTransactionCard(
                    title = "Campaign Payment ${index + 1}",
                    amount = 5000.0 - (index * 1000),
                    date = "${index + 1} days ago"
                )
            }
        }
    }
}

@Composable
fun IncomeExpenseCard(
    income: Double,
    expense: Double
) {
    val savings = income - expense
    val savingsPercentage = (savings / income * 100).toInt()
    
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Text(
                text = "This Month",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Outlined.TrendingUp,
                            contentDescription = "Income",
                            tint = Color(0xFF10B981),
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Income",
                            style = RexoTheme.typography.bodySmall,
                            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                    Text(
                        text = "₹${String.format("%,.0f", income)}",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF10B981)
                    )
                }
                
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Outlined.TrendingDown,
                            contentDescription = "Expense",
                            tint = Color(0xFFEF4444),
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Expense",
                            style = RexoTheme.typography.bodySmall,
                            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                    Text(
                        text = "₹${String.format("%,.0f", expense)}",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFFEF4444)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            HorizontalDivider()
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Savings",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                    Text(
                        text = "₹${String.format("%,.0f", savings)}",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = RexoTheme.colorScheme.primary
                    )
                }
                
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = RexoTheme.colorScheme.primaryContainer
                ) {
                    Text(
                        text = "$savingsPercentage% saved",
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                        style = RexoTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = RexoTheme.colorScheme.onPrimaryContainer
                    )
                }
            }
        }
    }
}

data class CategorySpending(
    val name: String,
    val amount: Double,
    val color: Color
)

@Composable
fun CategoryBreakdownCard(
    categories: List<CategorySpending>
) {
    val total = categories.sumOf { it.amount }
    
    GlassSurface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            categories.forEach { category ->
                val percentage = (category.amount / total * 100).toInt()
                
                Column(
                    modifier = Modifier.padding(vertical = 8.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Surface(
                                modifier = Modifier.size(12.dp),
                                shape = RoundedCornerShape(2.dp),
                                color = category.color
                            ) {}
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = category.name,
                                style = RexoTheme.typography.bodyMedium
                            )
                        }
                        
                        Text(
                            text = "₹${String.format("%,.0f", category.amount)}",
                            style = RexoTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    LinearProgressIndicator(
                        progress = { percentage / 100f },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(8.dp),
                        color = category.color,
                        trackColor = category.color.copy(alpha = 0.2f)
                    )
                }
            }
        }
    }
}

@Composable
fun MonthlyTrendsCard(
    months: List<String>,
    values: List<Double>
) {
    val maxValue = values.maxOrNull() ?: 1.0
    
    GlassSurface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Bottom
            ) {
                months.zip(values).forEach { (month, value) ->
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "₹${(value / 1000).toInt()}k",
                            style = RexoTheme.typography.labelSmall,
                            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                        
                        Spacer(modifier = Modifier.height(4.dp))
                        
                        Surface(
                            modifier = Modifier
                                .width(32.dp)
                                .height((value / maxValue * 100).dp),
                            shape = RoundedCornerShape(topStart = 8.dp, topEnd = 8.dp),
                            color = RexoTheme.colorScheme.primary
                        ) {}
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Text(
                            text = month,
                            style = RexoTheme.typography.labelSmall,
                            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun TopTransactionCard(
    title: String,
    amount: Double,
    date: String
) {
    GlassSurface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = date,
                    style = RexoTheme.typography.bodySmall,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
            
            Text(
                text = "+₹${String.format("%,.0f", amount)}",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF10B981)
            )
        }
    }
}
