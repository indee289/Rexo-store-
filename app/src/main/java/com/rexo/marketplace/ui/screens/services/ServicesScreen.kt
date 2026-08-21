package com.rexo.marketplace.ui.screens.services

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Services Screen - Tools and utilities for creators
 * Shows available services/tools that creators can use.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ServicesScreen(
    onNavigateBack: () -> Unit = {}
) {
    val services = remember {
        listOf(
            ServiceItem("Media Kit", Icons.Outlined.Description, RexoColors.AccentOrange, "Generate your media kit"),
            ServiceItem("Analytics", Icons.Outlined.BarChart, Color(0xFF6366F1), "Track your performance"),
            ServiceItem("Invoice", Icons.Outlined.Receipt, RexoColors.Success, "Create and send invoices"),
            ServiceItem("Contracts", Icons.Outlined.Assignment, Color(0xFFEC4899), "Manage brand contracts"),
            ServiceItem("Rate Card", Icons.Outlined.Sell, Color(0xFF14B8A6), "Set your pricing"),
            ServiceItem("Portfolio", Icons.Outlined.Folder, Color(0xFFF59E0B), "Showcase your work")
        )
    }

    Scaffold(
        containerColor = Color.White,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Services",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White
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
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            items(services) { service ->
                ServiceCard(service = service)
            }
        }
    }
}

private data class ServiceItem(
    val title: String,
    val icon: ImageVector,
    val color: Color,
    val description: String
)

@Composable
private fun ServiceCard(service: ServiceItem) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { /* TODO: Navigate to service */ },
        shape = RoundedCornerShape(16.dp),
        color = Color.White,
        shadowElevation = 1.dp,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Surface(
                shape = CircleShape,
                color = service.color.copy(alpha = 0.1f),
                modifier = Modifier.size(52.dp)
            ) {
                Icon(
                    imageVector = service.icon,
                    contentDescription = service.title,
                    modifier = Modifier.padding(14.dp),
                    tint = service.color
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = service.title,
                style = RexoTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = RexoColors.TextPrimary,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = service.description,
                style = RexoTheme.typography.bodySmall,
                color = RexoColors.TextSecondary,
                textAlign = TextAlign.Center,
                maxLines = 2
            )
        }
    }
}
