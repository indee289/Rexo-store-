package com.rexo.marketplace.ui.screens.home

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.data.repository.UserRepository
import com.rexo.marketplace.data.repository.WalletFullDto
import com.rexo.marketplace.data.repository.WalletRepository
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.CampaignItem
import com.rexo.marketplace.ui.viewmodel.CampaignUiState
import com.rexo.marketplace.ui.viewmodel.CampaignViewModel
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import java.util.Calendar

/**
 * Home ViewModel - fetches user name, wallet balance, and quick stats
 */
class HomeViewModel(
    private val walletRepository: WalletRepository = WalletRepository(),
    private val userRepository: UserRepository = UserRepository()
) : ViewModel() {

    private val _userName = MutableStateFlow("")
    val userName: StateFlow<String> = _userName.asStateFlow()

    private val _wallet = MutableStateFlow<WalletFullDto?>(null)
    val wallet: StateFlow<WalletFullDto?> = _wallet.asStateFlow()

    private val _activeApplications = MutableStateFlow(0)
    val activeApplications: StateFlow<Int> = _activeApplications.asStateFlow()

    private val _completedCampaigns = MutableStateFlow(0)
    val completedCampaigns: StateFlow<Int> = _completedCampaigns.asStateFlow()

    private val _recentNotifications = MutableStateFlow<List<NotificationItemDto>>(emptyList())
    val recentNotifications: StateFlow<List<NotificationItemDto>> = _recentNotifications.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    init {
        loadHomeData()
    }

    private fun loadHomeData() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val authUser = SupabaseClient.auth.currentUserOrNull()
                val userId = authUser?.id

                // Get user name from metadata
                val name = authUser?.userMetadata?.get("full_name")?.toString()?.removeSurrounding("\"")
                    ?: authUser?.userMetadata?.get("name")?.toString()?.removeSurrounding("\"")
                    ?: authUser?.email?.substringBefore("@")
                    ?: "Creator"
                _userName.value = name

                // Get wallet
                _wallet.value = walletRepository.getWallet()

                // Get application stats
                if (userId != null) {
                    loadApplicationStats(userId)
                    loadRecentNotifications(userId)
                }
            } catch (_: Exception) {
                // Silently fail - home screen should still show
            } finally {
                _isLoading.value = false
            }
        }
    }

    private suspend fun loadApplicationStats(userId: String) {
        try {
            val applications = withContext(Dispatchers.IO) {
                SupabaseClient.client.from("campaign_applications").select {
                    filter { eq("creator_id", userId) }
                }.decodeList<HomeApplicationDto>()
            }
            _activeApplications.value = applications.count { it.status == "submitted" }
            _completedCampaigns.value = applications.count { it.status in listOf("approved", "paid", "completed") }
        } catch (_: Exception) {
            // Stats remain 0
        }
    }

    private suspend fun loadRecentNotifications(userId: String) {
        try {
            val notifications = withContext(Dispatchers.IO) {
                SupabaseClient.client.from("notifications").select {
                    filter { eq("user_id", userId) }
                }.decodeList<NotificationItemDto>()
            }
            _recentNotifications.value = notifications.take(5)
        } catch (_: Exception) {
            _recentNotifications.value = emptyList()
        }
    }
}

@Serializable
data class HomeApplicationDto(
    val id: String = "",
    val status: String = ""
)

@Serializable
data class NotificationItemDto(
    val id: String = "",
    val user_id: String = "",
    val title: String = "",
    val message: String = "",
    val type: String = "general",
    val is_read: Boolean = false,
    val created_at: String = ""
)

/**
 * Discover Screen (Home)
 *
 * Enriched with:
 * - Hero welcome card with time-based greeting
 * - Wallet balance badge
 * - Quick stats row
 * - Featured campaigns section
 * - Recent activity
 * - Original search/filter/campaign list
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
    val viewModel = campaignViewModel
    val homeViewModel = remember { HomeViewModel() }

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

    val userName by homeViewModel.userName.collectAsState()
    val wallet by homeViewModel.wallet.collectAsState()
    val activeApplications by homeViewModel.activeApplications.collectAsState()
    val completedCampaigns by homeViewModel.completedCampaigns.collectAsState()
    val recentNotifications by homeViewModel.recentNotifications.collectAsState()
    val homeLoading by homeViewModel.isLoading.collectAsState()

    Scaffold(
        containerColor = Color.White
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(bottom = 80.dp)
        ) {
            // Header with wallet badge
            item {
                HomeHeader(
                    walletBalance = wallet?.available_balance ?: 0.0,
                    onNotificationClick = onNavigateToNotifications,
                    onWalletClick = onNavigateToWallet
                )
            }

            // Hero welcome card
            item {
                WelcomeCard(
                    userName = userName,
                    onWalletClick = onNavigateToWallet,
                    onCampaignsClick = onNavigateToCampaigns,
                    onProfileClick = onNavigateToProfile
                )
            }

            // Quick stats row
            item {
                QuickStatsRow(
                    activeApplications = activeApplications,
                    totalEarnings = wallet?.total_earnings ?: 0.0,
                    completedCampaigns = completedCampaigns,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
                )
            }

            // Featured campaigns section
            if (campaigns.isNotEmpty()) {
                item {
                    FeaturedCampaignsSection(
                        campaigns = campaigns.take(3),
                        onCampaignClick = { onNavigateToCampaigns() },
                        modifier = Modifier.padding(vertical = 8.dp)
                    )
                }
            }

            // Recent activity
            if (recentNotifications.isNotEmpty()) {
                item {
                    RecentActivitySection(
                        notifications = recentNotifications,
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
                    )
                }
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
private fun HomeHeader(
    walletBalance: Double,
    onNotificationClick: () -> Unit,
    onWalletClick: () -> Unit
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

        Row(
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Wallet balance badge
            Surface(
                modifier = Modifier.clickable(onClick = onWalletClick),
                shape = RoundedCornerShape(20.dp),
                color = RexoColors.AccentOrange.copy(alpha = 0.1f)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Icon(
                        Icons.Outlined.AccountBalanceWallet,
                        contentDescription = "Wallet",
                        tint = RexoColors.AccentOrange,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        text = "\u20B9${String.format("%,.0f", walletBalance)}",
                        style = RexoTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.AccentOrange
                    )
                }
            }

            IconButton(onClick = onNotificationClick) {
                Icon(
                    imageVector = Icons.Outlined.Notifications,
                    contentDescription = "Notifications",
                    tint = RexoColors.TextPrimary
                )
            }
        }
    }
}

@Composable
private fun WelcomeCard(
    userName: String,
    onWalletClick: () -> Unit,
    onCampaignsClick: () -> Unit,
    onProfileClick: () -> Unit
) {
    val greeting = remember {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        when {
            hour < 12 -> "Good Morning"
            hour < 17 -> "Good Afternoon"
            else -> "Good Evening"
        }
    }

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 4.dp),
        shape = RoundedCornerShape(16.dp),
        color = RexoColors.AccentOrange.copy(alpha = 0.05f),
        border = BorderStroke(1.dp, RexoColors.AccentOrange.copy(alpha = 0.15f))
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "$greeting,",
                style = RexoTheme.typography.bodyMedium,
                color = RexoColors.TextSecondary
            )
            Text(
                text = userName.ifBlank { "Creator" },
                style = RexoTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            // Quick action buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                QuickActionButton(
                    icon = Icons.Outlined.AccountBalanceWallet,
                    label = "Wallet",
                    onClick = onWalletClick,
                    modifier = Modifier.weight(1f)
                )
                QuickActionButton(
                    icon = Icons.Outlined.Campaign,
                    label = "Campaigns",
                    onClick = onCampaignsClick,
                    modifier = Modifier.weight(1f)
                )
                QuickActionButton(
                    icon = Icons.Outlined.Person,
                    label = "Profile",
                    onClick = onProfileClick,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun QuickActionButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier.clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = RexoColors.AccentOrange,
                modifier = Modifier.size(22.dp)
            )
            Text(
                text = label,
                style = RexoTheme.typography.labelSmall,
                color = RexoColors.TextPrimary
            )
        }
    }
}

@Composable
private fun QuickStatsRow(
    activeApplications: Int,
    totalEarnings: Double,
    completedCampaigns: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        MiniStatCard(
            label = "Active",
            value = "$activeApplications",
            color = Color(0xFF6366F1),
            modifier = Modifier.weight(1f)
        )
        MiniStatCard(
            label = "Earnings",
            value = "\u20B9${String.format("%,.0f", totalEarnings)}",
            color = RexoColors.AccentOrange,
            modifier = Modifier.weight(1f)
        )
        MiniStatCard(
            label = "Completed",
            value = "$completedCampaigns",
            color = RexoColors.Success,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun MiniStatCard(
    label: String,
    value: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        color = color.copy(alpha = 0.05f),
        border = BorderStroke(1.dp, color.copy(alpha = 0.15f))
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = value,
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = color
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = label,
                style = RexoTheme.typography.labelSmall,
                color = RexoColors.TextSecondary
            )
        }
    }
}

@Composable
private fun FeaturedCampaignsSection(
    campaigns: List<CampaignItem>,
    onCampaignClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Trending Campaigns",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )
            TextButton(onClick = onCampaignClick) {
                Text(
                    text = "See All",
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.AccentOrange
                )
            }
        }

        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            contentPadding = PaddingValues(horizontal = 20.dp)
        ) {
            items(campaigns, key = { it.id }) { campaign ->
                FeaturedCampaignCard(
                    campaign = campaign,
                    onClick = onCampaignClick
                )
            }
        }
    }
}

@Composable
private fun FeaturedCampaignCard(
    campaign: CampaignItem,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .width(220.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(
            modifier = Modifier.padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = RexoColors.AccentOrange.copy(alpha = 0.1f),
                    modifier = Modifier.size(36.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            text = campaign.brandName.firstOrNull()?.uppercase() ?: "?",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.AccentOrange
                        )
                    }
                }
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = campaign.brandName,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            Text(
                text = campaign.title,
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = campaign.category,
                    style = RexoTheme.typography.labelSmall,
                    color = RexoColors.AccentOrange
                )
                Text(
                    text = "\u20B9${String.format("%,.0f", campaign.budget)}",
                    style = RexoTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.Success
                )
            }
        }
    }
}

@Composable
private fun RecentActivitySection(
    notifications: List<NotificationItemDto>,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = "Recent Activity",
            style = RexoTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = RexoColors.TextPrimary
        )

        notifications.forEach { notification ->
            Surface(
                shape = RoundedCornerShape(8.dp),
                color = if (notification.is_read) Color.White else RexoColors.Gray50,
                border = BorderStroke(1.dp, RexoColors.CardBorder)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Surface(
                        shape = CircleShape,
                        color = RexoColors.AccentOrange.copy(alpha = 0.1f),
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(
                            imageVector = when (notification.type) {
                                "campaign" -> Icons.Outlined.Campaign
                                "payment" -> Icons.Outlined.Payment
                                "chat" -> Icons.Outlined.Chat
                                else -> Icons.Outlined.Notifications
                            },
                            contentDescription = null,
                            tint = RexoColors.AccentOrange,
                            modifier = Modifier.padding(6.dp)
                        )
                    }

                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = notification.title,
                            style = RexoTheme.typography.bodySmall,
                            fontWeight = FontWeight.SemiBold,
                            color = RexoColors.TextPrimary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        Text(
                            text = notification.message,
                            style = RexoTheme.typography.labelSmall,
                            color = RexoColors.TextSecondary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            }
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
                Box(
                    modifier = Modifier.size(56.dp)
                ) {
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

                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = campaign.title,
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.CameraAlt,
                            contentDescription = "Instagram",
                            modifier = Modifier.size(14.dp),
                            tint = RexoColors.Gray400
                        )
                        Icon(
                            imageVector = Icons.Outlined.MusicNote,
                            contentDescription = "TikTok",
                            modifier = Modifier.size(14.dp),
                            tint = RexoColors.Gray400
                        )
                        Icon(
                            imageVector = Icons.Outlined.PlayCircle,
                            contentDescription = "YouTube",
                            modifier = Modifier.size(14.dp),
                            tint = RexoColors.Gray400
                        )
                        Icon(
                            imageVector = Icons.Outlined.Tag,
                            contentDescription = "X",
                            modifier = Modifier.size(14.dp),
                            tint = RexoColors.Gray400
                        )
                    }
                }

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

private fun formatBudget(amount: Double): String {
    return String.format("%,.0f", amount)
}
