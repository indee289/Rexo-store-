package com.rexo.marketplace.ui.screens.home

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.CampaignItem
import com.rexo.marketplace.ui.viewmodel.CampaignUiState
import com.rexo.marketplace.ui.viewmodel.CampaignViewModel

/**
 * Discover Screen (Home)
 *
 * Clean white design with:
 * - "Discover" title at top left
 * - Notification bell icon at top right
 * - Search bar with placeholder
 * - Category filter chips (horizontal scrolling)
 * - Campaign count ("X of Y campaigns")
 * - Campaign cards with progress bars
 * - Proper loading/error/empty states
 *
 * No fake data - all content from Supabase via CampaignViewModel.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onNavigateToWallet: () -> Unit = {},
    onNavigateToCampaigns: () -> Unit = {},
    onNavigateToProfile: () -> Unit = {},
    onNavigateToNotifications: () -> Unit = {},
    campaignViewModel: CampaignViewModel? = null
) {
    // If no ViewModel is provided, show a placeholder
    // In production, the ViewModel will be injected via the NavGraph
    val viewModel = campaignViewModel

    val uiState by viewModel?.uiState?.collectAsState()
        ?: remember { mutableStateOf(CampaignUiState(isLoading = true)) }
    val campaigns by viewModel?.campaigns?.collectAsState()
        ?: remember { mutableStateOf(emptyList<CampaignItem>()) }
    val totalCount by viewModel?.totalCount?.collectAsState()
        ?: remember { mutableStateOf(0) }
    val filteredCount by viewModel?.filteredCount?.collectAsState()
        ?: remember { mutableStateOf(0) }
    val searchQuery by viewModel?.searchQuery?.collectAsState()
        ?: remember { mutableStateOf("") }
    val selectedCategory by viewModel?.selectedCategory?.collectAsState()
        ?: remember { mutableStateOf("All") }
    val categories by viewModel?.categories?.collectAsState()
        ?: remember { mutableStateOf(listOf("All", "Music", "Logo", "Clipping", "UGC")) }

    Scaffold(
        containerColor = Color.White
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(bottom = 80.dp)
        ) {
            // Header: "Discover" title + notification bell
            item {
                DiscoverHeader(
                    onNotificationClick = onNavigateToNotifications
                )
            }

            // Search bar
            item {
                SearchBar(
                    query = searchQuery,
                    onQueryChange = { viewModel?.updateSearchQuery(it) },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
                )
            }

            // Filter chips row
            item {
                FilterChipsRow(
                    categories = categories,
                    selectedCategory = selectedCategory,
                    onCategorySelected = { viewModel?.selectCategory(it) },
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            }

            // Campaign count
            item {
                CampaignCountText(
                    filteredCount = filteredCount,
                    totalCount = totalCount,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
                )
            }

            // Content based on state
            when {
                uiState.isLoading -> {
                    item {
                        LoadingState(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 48.dp)
                        )
                    }
                }

                uiState.error != null -> {
                    item {
                        ErrorState(
                            message = uiState.error ?: "Something went wrong",
                            onRetry = { viewModel?.loadCampaigns() },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 48.dp)
                        )
                    }
                }

                campaigns.isEmpty() -> {
                    item {
                        EmptyState(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 48.dp)
                        )
                    }
                }

                else -> {
                    items(campaigns, key = { it.id }) { campaign ->
                        CampaignCard(
                            campaign = campaign,
                            onClick = { onNavigateToCampaigns() },
                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun DiscoverHeader(
    onNotificationClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "Discover",
            style = RexoTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold,
            color = RexoColors.TextPrimary
        )

        IconButton(onClick = onNotificationClick) {
            Icon(
                imageVector = Icons.Outlined.Notifications,
                contentDescription = "Notifications",
                tint = RexoColors.TextPrimary
            )
        }
    }
}

@Composable
private fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    TextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = {
            Text(
                text = "Search for a campaign...",
                color = RexoColors.TextSecondary
            )
        },
        leadingIcon = {
            Icon(
                imageVector = Icons.Outlined.Search,
                contentDescription = "Search",
                tint = RexoColors.TextSecondary
            )
        },
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp)),
        colors = TextFieldDefaults.colors(
            unfocusedContainerColor = RexoColors.Gray100,
            focusedContainerColor = RexoColors.Gray100,
            unfocusedIndicatorColor = Color.Transparent,
            focusedIndicatorColor = Color.Transparent,
            cursorColor = RexoColors.AccentOrange
        ),
        shape = RoundedCornerShape(12.dp),
        singleLine = true
    )
}

@Composable
private fun FilterChipsRow(
    categories: List<String>,
    selectedCategory: String,
    onCategorySelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Filter icon button
        IconButton(
            onClick = { /* Filter options */ },
            modifier = Modifier.padding(start = 12.dp)
        ) {
            Icon(
                imageVector = Icons.Outlined.FilterList,
                contentDescription = "Filter",
                tint = RexoColors.TextPrimary
            )
        }

        // Horizontal scrolling category chips
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(end = 20.dp)
        ) {
            items(categories) { category ->
                val isSelected = category == selectedCategory

                FilterChip(
                    selected = isSelected,
                    onClick = { onCategorySelected(category) },
                    label = {
                        Text(
                            text = category,
                            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
                        )
                    },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = RexoColors.AccentOrange,
                        selectedLabelColor = Color.White,
                        containerColor = RexoColors.Gray100,
                        labelColor = RexoColors.TextPrimary
                    ),
                    border = null
                )
            }
        }
    }
}

@Composable
private fun CampaignCountText(
    filteredCount: Int,
    totalCount: Int,
    modifier: Modifier = Modifier
) {
    Text(
        text = "$filteredCount of $totalCount campaigns",
        style = RexoTheme.typography.bodyMedium,
        color = RexoColors.TextSecondary,
        modifier = modifier
    )
}

@Composable
private fun CampaignCard(
    campaign: CampaignItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val slotsRatio = if (campaign.slots > 0) {
        campaign.filledSlots.toFloat() / campaign.slots.toFloat()
    } else 0f

    val progressColor = when {
        slotsRatio < 0.5f -> RexoColors.Success
        slotsRatio < 0.8f -> RexoColors.Warning
        else -> RexoColors.Error
    }

    val progressPercentage = (slotsRatio * 100).toInt()

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        color = Color.White,
        shadowElevation = 1.dp,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top
            ) {
                // Left: Brand icon area with category badge
                Box(
                    modifier = Modifier.size(56.dp)
                ) {
                    // Rounded square with first letter of brand
                    Surface(
                        modifier = Modifier.size(56.dp),
                        shape = RoundedCornerShape(12.dp),
                        color = RexoColors.Gray100
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(
                                text = campaign.brandName.firstOrNull()?.uppercase() ?: "?",
                                style = RexoTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = RexoColors.AccentOrange
                            )
                        }
                    }

                    // Category badge on the icon
                    Surface(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .offset(y = 6.dp),
                        shape = RoundedCornerShape(4.dp),
                        color = RexoColors.AccentOrange
                    ) {
                        Text(
                            text = campaign.category,
                            style = RexoTheme.typography.labelSmall,
                            color = Color.White,
                            modifier = Modifier.padding(horizontal = 4.dp, vertical = 1.dp),
                            fontSize = 9.sp,
                            maxLines = 1
                        )
                    }
                }

                Spacer(modifier = Modifier.width(12.dp))

                // Middle: Campaign info
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    // Campaign title
                    Text(
                        text = campaign.title,
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    // Platform icons row
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Instagram icon
                        Icon(
                            imageVector = Icons.Outlined.CameraAlt,
                            contentDescription = "Instagram",
                            modifier = Modifier.size(14.dp),
                            tint = RexoColors.Gray400
                        )
                        // TikTok icon (using music note as substitute)
                        Icon(
                            imageVector = Icons.Outlined.MusicNote,
                            contentDescription = "TikTok",
                            modifier = Modifier.size(14.dp),
                            tint = RexoColors.Gray400
                        )
                        // YouTube icon (using play as substitute)
                        Icon(
                            imageVector = Icons.Outlined.PlayCircle,
                            contentDescription = "YouTube",
                            modifier = Modifier.size(14.dp),
                            tint = RexoColors.Gray400
                        )
                        // X icon (using tag as substitute)
                        Icon(
                            imageVector = Icons.Outlined.Tag,
                            contentDescription = "X",
                            modifier = Modifier.size(14.dp),
                            tint = RexoColors.Gray400
                        )
                    }
                }

                // Bookmark icon at top-right
                IconButton(
                    onClick = { /* Bookmark */ },
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Outlined.BookmarkBorder,
                        contentDescription = "Bookmark",
                        tint = RexoColors.Gray400,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Progress bar
            LinearProgressIndicator(
                progress = { slotsRatio.coerceIn(0f, 1f) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp)),
                color = progressColor,
                trackColor = RexoColors.Gray200
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Budget info row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "$progressPercentage% / \$${formatBudget(campaign.payoutPerCreator)}",
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.TextSecondary
                )

                Text(
                    text = "\$${formatBudget(campaign.budget)} / target",
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.TextSecondary
                )
            }
        }
    }
}

@Composable
private fun LoadingState(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        CircularProgressIndicator(
            color = RexoColors.AccentOrange,
            modifier = Modifier.size(40.dp)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Loading campaigns...",
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary
        )
    }
}

@Composable
private fun ErrorState(
    message: String,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Outlined.Error,
            contentDescription = "Error",
            modifier = Modifier.size(48.dp),
            tint = RexoColors.Error
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = message,
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(
            onClick = onRetry,
            colors = ButtonDefaults.buttonColors(
                containerColor = RexoColors.AccentOrange
            ),
            shape = RoundedCornerShape(8.dp)
        ) {
            Text("Retry")
        }
    }
}

@Composable
private fun EmptyState(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Outlined.Campaign,
            contentDescription = "No campaigns",
            modifier = Modifier.size(48.dp),
            tint = RexoColors.Gray300
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "No campaigns found",
            style = RexoTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = RexoColors.TextPrimary
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "Try adjusting your search or filters",
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary
        )
    }
}

/**
 * Format a budget value with commas for display.
 */
private fun formatBudget(amount: Double): String {
    return String.format("%,.0f", amount)
}
