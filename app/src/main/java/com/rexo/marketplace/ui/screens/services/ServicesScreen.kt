package com.rexo.marketplace.ui.screens.services

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
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
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.data.repository.CreatorProfileDto
import com.rexo.marketplace.data.repository.UserRepository
import com.rexo.marketplace.data.repository.WalletFullDto
import com.rexo.marketplace.data.repository.WalletRepository
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable

/**
 * Services ViewModel - manages data for all service tools
 */
class ServicesViewModel(
    private val userRepository: UserRepository = UserRepository(),
    private val walletRepository: WalletRepository = WalletRepository()
) : ViewModel() {

    private val _creatorProfile = MutableStateFlow<CreatorProfileDto?>(null)
    val creatorProfile: StateFlow<CreatorProfileDto?> = _creatorProfile.asStateFlow()

    private val _wallet = MutableStateFlow<WalletFullDto?>(null)
    val wallet: StateFlow<WalletFullDto?> = _wallet.asStateFlow()

    private val _completedApplications = MutableStateFlow<List<CampaignApplicationDto>>(emptyList())
    val completedApplications: StateFlow<List<CampaignApplicationDto>> = _completedApplications.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _invoiceSaved = MutableStateFlow(false)
    val invoiceSaved: StateFlow<Boolean> = _invoiceSaved.asStateFlow()

    init {
        loadData()
    }

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                val userId = SupabaseClient.auth.currentUserOrNull()?.id
                if (userId != null) {
                    _creatorProfile.value = userRepository.getCreatorProfile(userId)
                    _wallet.value = walletRepository.getWallet()
                    loadApplications(userId)
                } else {
                    _error.value = "Please sign in to access services"
                }
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load data"
            } finally {
                _isLoading.value = false
            }
        }
    }

    private suspend fun loadApplications(userId: String) {
        try {
            val applications = withContext(Dispatchers.IO) {
                SupabaseClient.client.from("campaign_applications").select {
                    filter { eq("creator_id", userId) }
                }.decodeList<CampaignApplicationDto>()
            }
            _completedApplications.value = applications
        } catch (e: Exception) {
            _completedApplications.value = emptyList()
        }
    }

    fun saveInvoice(brandName: String, campaignTitle: String, amount: Double, date: String) {
        viewModelScope.launch {
            try {
                val userId = SupabaseClient.auth.currentUserOrNull()?.id ?: return@launch
                val invoice = InvoiceInsertDto(
                    id = "INV-${System.currentTimeMillis()}-${userId.take(8)}",
                    creator_id = userId,
                    brand_name = brandName,
                    campaign_title = campaignTitle,
                    amount = amount,
                    date = date,
                    status = "pending"
                )
                withContext(Dispatchers.IO) {
                    SupabaseClient.client.from("invoices").insert(invoice)
                }
                _invoiceSaved.value = true
            } catch (e: Exception) {
                _error.value = "Failed to save invoice: ${e.message}"
            }
        }
    }

    fun clearInvoiceSaved() {
        _invoiceSaved.value = false
    }
}

@Serializable
data class CampaignApplicationDto(
    val id: String = "",
    val campaign_id: String = "",
    val campaign_title: String = "",
    val brand_name: String = "",
    val creator_id: String = "",
    val status: String = "submitted",
    val fee_requested: Double = 0.0,
    val pitch: String? = null
)

@Serializable
data class InvoiceInsertDto(
    val id: String,
    val creator_id: String,
    val brand_name: String,
    val campaign_title: String,
    val amount: Double,
    val date: String,
    val status: String = "pending"
)

/**
 * Services Screen - Functional tools for creators
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ServicesScreen(
    onNavigateBack: () -> Unit = {}
) {
    var selectedTool by remember { mutableStateOf<String?>(null) }
    val viewModel = remember { ServicesViewModel() }

    Scaffold(
        containerColor = Color.White,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (selectedTool != null) selectedTool!! else "Services",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
                },
                navigationIcon = {
                    if (selectedTool != null) {
                        IconButton(onClick = { selectedTool = null }) {
                            Icon(
                                Icons.Outlined.ArrowBack,
                                contentDescription = "Back",
                                tint = RexoColors.TextPrimary
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        when (selectedTool) {
            "Media Kit" -> MediaKitContent(
                viewModel = viewModel,
                modifier = Modifier.padding(paddingValues)
            )
            "Rate Calculator" -> RateCalculatorContent(
                modifier = Modifier.padding(paddingValues)
            )
            "Analytics" -> AnalyticsDashboardContent(
                viewModel = viewModel,
                modifier = Modifier.padding(paddingValues)
            )
            "Invoice Generator" -> InvoiceGeneratorContent(
                viewModel = viewModel,
                modifier = Modifier.padding(paddingValues)
            )
            "Portfolio" -> PortfolioContent(
                viewModel = viewModel,
                modifier = Modifier.padding(paddingValues)
            )
            else -> ServiceToolsGrid(
                onToolSelected = { selectedTool = it },
                modifier = Modifier.padding(paddingValues)
            )
        }
    }
}

@Composable
private fun ServiceToolsGrid(
    onToolSelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val tools = listOf(
        ServiceTool("Media Kit", Icons.Outlined.Description, RexoColors.AccentOrange, "Generate your media kit"),
        ServiceTool("Rate Calculator", Icons.Outlined.Calculate, Color(0xFF14B8A6), "Calculate your rates"),
        ServiceTool("Analytics", Icons.Outlined.BarChart, Color(0xFF6366F1), "Track your performance"),
        ServiceTool("Invoice Generator", Icons.Outlined.Receipt, RexoColors.Success, "Create invoices"),
        ServiceTool("Portfolio", Icons.Outlined.Folder, Color(0xFFF59E0B), "Showcase your work")
    )

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(tools) { tool ->
            ServiceToolCard(
                tool = tool,
                onClick = { onToolSelected(tool.title) }
            )
        }
    }
}

private data class ServiceTool(
    val title: String,
    val icon: ImageVector,
    val color: Color,
    val description: String
)

@Composable
private fun ServiceToolCard(
    tool: ServiceTool,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        color = Color.White,
        shadowElevation = 1.dp,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Surface(
                shape = CircleShape,
                color = tool.color.copy(alpha = 0.1f),
                modifier = Modifier.size(48.dp)
            ) {
                Icon(
                    imageVector = tool.icon,
                    contentDescription = tool.title,
                    modifier = Modifier.padding(12.dp),
                    tint = tool.color
                )
            }

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = tool.title,
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = tool.description,
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.TextSecondary
                )
            }

            Icon(
                imageVector = Icons.Outlined.ChevronRight,
                contentDescription = "Open",
                tint = RexoColors.Gray400,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

// ─── MEDIA KIT ────────────────────────────────────────────────────────────────

@Composable
private fun MediaKitContent(
    viewModel: ServicesViewModel,
    modifier: Modifier = Modifier
) {
    val profile by viewModel.creatorProfile.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        if (isLoading) {
            Box(
                modifier = Modifier.fillMaxWidth().padding(48.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = RexoColors.AccentOrange)
            }
        } else if (error != null) {
            ErrorCard(message = error!!, onRetry = { viewModel.loadData() })
        } else if (profile == null) {
            EmptyCard(message = "No creator profile found. Complete your profile to generate a media kit.")
        } else {
            val p = profile!!
            // Header
            Text(
                text = "Your Media Kit",
                style = RexoTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            Text(
                text = "Share your creator stats with brands",
                style = RexoTheme.typography.bodyMedium,
                color = RexoColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Stats grid
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StatCard(
                    label = "Followers",
                    value = formatNumber(p.followers),
                    icon = Icons.Outlined.People,
                    color = RexoColors.AccentOrange,
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    label = "Engagement",
                    value = "${String.format("%.1f", p.engagement_rate)}%",
                    icon = Icons.Outlined.TrendingUp,
                    color = Color(0xFF6366F1),
                    modifier = Modifier.weight(1f)
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StatCard(
                    label = "Campaigns",
                    value = "${p.completed_campaigns}",
                    icon = Icons.Outlined.Campaign,
                    color = RexoColors.Success,
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    label = "Rating",
                    value = "${String.format("%.1f", p.rating)}/5",
                    icon = Icons.Outlined.Star,
                    color = Color(0xFFF59E0B),
                    modifier = Modifier.weight(1f)
                )
            }

            // Category
            if (p.category != null) {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = Color.White,
                    border = BorderStroke(1.dp, RexoColors.CardBorder)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            Icons.Outlined.Category,
                            contentDescription = null,
                            tint = RexoColors.AccentOrange
                        )
                        Column {
                            Text(
                                text = "Niche/Category",
                                style = RexoTheme.typography.bodySmall,
                                color = RexoColors.TextSecondary
                            )
                            Text(
                                text = p.category!!,
                                style = RexoTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = RexoColors.TextPrimary
                            )
                        }
                    }
                }
            }

            // Social handles
            if (p.instagram_handle != null || p.youtube_channel != null) {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = Color.White,
                    border = BorderStroke(1.dp, RexoColors.CardBorder)
                ) {
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Social Platforms",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.TextPrimary
                        )
                        if (p.instagram_handle != null) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Icon(
                                    Icons.Outlined.CameraAlt,
                                    contentDescription = "Instagram",
                                    tint = Color(0xFFE4405F),
                                    modifier = Modifier.size(20.dp)
                                )
                                Text(
                                    text = "@${p.instagram_handle}",
                                    style = RexoTheme.typography.bodyMedium,
                                    color = RexoColors.TextPrimary
                                )
                            }
                        }
                        if (p.youtube_channel != null) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Icon(
                                    Icons.Outlined.PlayCircle,
                                    contentDescription = "YouTube",
                                    tint = Color(0xFFFF0000),
                                    modifier = Modifier.size(20.dp)
                                )
                                Text(
                                    text = p.youtube_channel!!,
                                    style = RexoTheme.typography.bodyMedium,
                                    color = RexoColors.TextPrimary
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Share button
            Button(
                onClick = { /* Share intent - triggers platform share sheet */ },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = RexoColors.AccentOrange
                )
            ) {
                Icon(Icons.Outlined.Share, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Share Media Kit", fontWeight = FontWeight.Bold)
            }
        }
    }
}

// ─── RATE CALCULATOR ──────────────────────────────────────────────────────────

@Composable
private fun RateCalculatorContent(
    modifier: Modifier = Modifier
) {
    var followersInput by remember { mutableStateOf("") }
    var engagementInput by remember { mutableStateOf("") }
    var selectedPlatform by remember { mutableStateOf("Instagram") }
    var calculatedRate by remember { mutableStateOf<Double?>(null) }

    val platforms = listOf("Instagram", "YouTube", "TikTok")
    val platformMultipliers = mapOf(
        "Instagram" to 1.5,
        "YouTube" to 2.0,
        "TikTok" to 1.2
    )

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "Rate Calculator",
            style = RexoTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold,
            color = RexoColors.TextPrimary
        )

        Text(
            text = "Calculate your suggested rate based on industry standards",
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Followers input
        OutlinedTextField(
            value = followersInput,
            onValueChange = { followersInput = it.filter { c -> c.isDigit() } },
            label = { Text("Followers Count") },
            placeholder = { Text("e.g. 50000") },
            leadingIcon = {
                Icon(Icons.Outlined.People, contentDescription = null, tint = RexoColors.AccentOrange)
            },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = RexoColors.AccentOrange,
                cursorColor = RexoColors.AccentOrange
            ),
            singleLine = true
        )

        // Engagement rate input
        OutlinedTextField(
            value = engagementInput,
            onValueChange = { engagementInput = it.filter { c -> c.isDigit() || c == '.' } },
            label = { Text("Engagement Rate (%)") },
            placeholder = { Text("e.g. 3.5") },
            leadingIcon = {
                Icon(Icons.Outlined.TrendingUp, contentDescription = null, tint = Color(0xFF6366F1))
            },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = RexoColors.AccentOrange,
                cursorColor = RexoColors.AccentOrange
            ),
            singleLine = true
        )

        // Platform selector
        Text(
            text = "Platform",
            style = RexoTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = RexoColors.TextPrimary
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            platforms.forEach { platform ->
                FilterChip(
                    selected = selectedPlatform == platform,
                    onClick = { selectedPlatform = platform },
                    label = { Text(platform) },
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

        Spacer(modifier = Modifier.height(8.dp))

        // Calculate button
        Button(
            onClick = {
                val followers = followersInput.toDoubleOrNull() ?: 0.0
                val engagement = engagementInput.toDoubleOrNull() ?: 0.0
                val multiplier = platformMultipliers[selectedPlatform] ?: 1.0
                calculatedRate = (followers / 1000.0) * engagement * multiplier
            },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = RexoColors.AccentOrange
            ),
            enabled = followersInput.isNotBlank() && engagementInput.isNotBlank()
        ) {
            Icon(Icons.Outlined.Calculate, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text("Calculate Rate", fontWeight = FontWeight.Bold)
        }

        // Results
        if (calculatedRate != null) {
            Spacer(modifier = Modifier.height(8.dp))

            Surface(
                shape = RoundedCornerShape(16.dp),
                color = RexoColors.AccentOrange.copy(alpha = 0.05f),
                border = BorderStroke(1.dp, RexoColors.AccentOrange.copy(alpha = 0.2f))
            ) {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Suggested Rates",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )

                    RateRow("Per Post", calculatedRate!!)
                    RateRow("Per Reel/Short", calculatedRate!! * 1.3)
                    RateRow("Per Video", calculatedRate!! * 2.5)

                    Spacer(modifier = Modifier.height(4.dp))

                    Text(
                        text = "Based on: ${formatNumber(followersInput.toIntOrNull() ?: 0)} followers, ${engagementInput}% engagement, $selectedPlatform (${platformMultipliers[selectedPlatform]}x multiplier)",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                }
            }
        }
    }
}

@Composable
private fun RateRow(label: String, amount: Double) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary
        )
        Text(
            text = "\u20B9${String.format("%,.0f", amount)}",
            style = RexoTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = RexoColors.AccentOrange
        )
    }
}

// ─── ANALYTICS DASHBOARD ──────────────────────────────────────────────────────

@Composable
private fun AnalyticsDashboardContent(
    viewModel: ServicesViewModel,
    modifier: Modifier = Modifier
) {
    val wallet by viewModel.wallet.collectAsState()
    val applications by viewModel.completedApplications.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()

    val completedCount = applications.count { it.status in listOf("approved", "paid", "completed") }
    val activeCount = applications.count { it.status == "submitted" }
    val totalEarnings = wallet?.total_earnings ?: 0.0

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        if (isLoading) {
            Box(
                modifier = Modifier.fillMaxWidth().padding(48.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = RexoColors.AccentOrange)
            }
        } else if (error != null) {
            ErrorCard(message = error!!, onRetry = { viewModel.loadData() })
        } else {
            Text(
                text = "Analytics Dashboard",
                style = RexoTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            Text(
                text = "Your performance overview",
                style = RexoTheme.typography.bodyMedium,
                color = RexoColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Earnings card
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = RexoColors.AccentOrange.copy(alpha = 0.05f),
                border = BorderStroke(1.dp, RexoColors.AccentOrange.copy(alpha = 0.2f))
            ) {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(20.dp)
                ) {
                    Text(
                        text = "Total Earnings",
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "\u20B9${String.format("%,.2f", totalEarnings)}",
                        style = RexoTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.AccentOrange
                    )
                }
            }

            // Stats row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StatCard(
                    label = "Completed",
                    value = "$completedCount",
                    icon = Icons.Outlined.CheckCircle,
                    color = RexoColors.Success,
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    label = "Active",
                    value = "$activeCount",
                    icon = Icons.Outlined.Pending,
                    color = Color(0xFF6366F1),
                    modifier = Modifier.weight(1f)
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StatCard(
                    label = "Available",
                    value = "\u20B9${String.format("%,.0f", wallet?.available_balance ?: 0.0)}",
                    icon = Icons.Outlined.AccountBalanceWallet,
                    color = RexoColors.AccentOrange,
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    label = "Withdrawn",
                    value = "\u20B9${String.format("%,.0f", wallet?.total_withdrawn ?: 0.0)}",
                    icon = Icons.Outlined.Savings,
                    color = Color(0xFFF59E0B),
                    modifier = Modifier.weight(1f)
                )
            }

            // Campaign performance
            if (applications.isNotEmpty()) {
                Text(
                    text = "Campaign Breakdown",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )

                val statusGroups = applications.groupBy { it.status }
                statusGroups.forEach { (status, items) ->
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = status.replaceFirstChar { it.uppercase() },
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextPrimary
                        )
                        Text(
                            text = "${items.size}",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.AccentOrange
                        )
                    }
                    LinearProgressIndicator(
                        progress = { items.size.toFloat() / applications.size.toFloat() },
                        modifier = Modifier.fillMaxWidth().height(4.dp),
                        color = when (status) {
                            "paid", "completed", "approved" -> RexoColors.Success
                            "submitted" -> Color(0xFF6366F1)
                            "rejected" -> RexoColors.Error
                            else -> RexoColors.Gray400
                        },
                        trackColor = RexoColors.Gray200
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
        }
    }
}

// ─── INVOICE GENERATOR ────────────────────────────────────────────────────────

@Composable
private fun InvoiceGeneratorContent(
    viewModel: ServicesViewModel,
    modifier: Modifier = Modifier
) {
    var brandName by remember { mutableStateOf("") }
    var campaignTitle by remember { mutableStateOf("") }
    var amount by remember { mutableStateOf("") }
    var date by remember { mutableStateOf("") }

    val invoiceSaved by viewModel.invoiceSaved.collectAsState()
    val error by viewModel.error.collectAsState()

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "Invoice Generator",
            style = RexoTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold,
            color = RexoColors.TextPrimary
        )

        Text(
            text = "Create and save invoices for brand collaborations",
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary
        )

        Spacer(modifier = Modifier.height(8.dp))

        OutlinedTextField(
            value = brandName,
            onValueChange = { brandName = it },
            label = { Text("Brand Name") },
            placeholder = { Text("e.g. Nike") },
            leadingIcon = {
                Icon(Icons.Outlined.Business, contentDescription = null, tint = RexoColors.AccentOrange)
            },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = RexoColors.AccentOrange,
                cursorColor = RexoColors.AccentOrange
            ),
            singleLine = true
        )

        OutlinedTextField(
            value = campaignTitle,
            onValueChange = { campaignTitle = it },
            label = { Text("Campaign Title") },
            placeholder = { Text("e.g. Summer Collection Launch") },
            leadingIcon = {
                Icon(Icons.Outlined.Campaign, contentDescription = null, tint = Color(0xFF6366F1))
            },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = RexoColors.AccentOrange,
                cursorColor = RexoColors.AccentOrange
            ),
            singleLine = true
        )

        OutlinedTextField(
            value = amount,
            onValueChange = { amount = it.filter { c -> c.isDigit() || c == '.' } },
            label = { Text("Amount (\u20B9)") },
            placeholder = { Text("e.g. 5000") },
            leadingIcon = {
                Icon(Icons.Outlined.CurrencyRupee, contentDescription = null, tint = RexoColors.Success)
            },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = RexoColors.AccentOrange,
                cursorColor = RexoColors.AccentOrange
            ),
            singleLine = true
        )

        OutlinedTextField(
            value = date,
            onValueChange = { date = it },
            label = { Text("Date") },
            placeholder = { Text("e.g. 2025-01-15") },
            leadingIcon = {
                Icon(Icons.Outlined.CalendarToday, contentDescription = null, tint = Color(0xFFF59E0B))
            },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = RexoColors.AccentOrange,
                cursorColor = RexoColors.AccentOrange
            ),
            singleLine = true
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Save button
        Button(
            onClick = {
                val amountVal = amount.toDoubleOrNull() ?: 0.0
                viewModel.saveInvoice(brandName, campaignTitle, amountVal, date)
            },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = RexoColors.AccentOrange
            ),
            enabled = brandName.isNotBlank() && campaignTitle.isNotBlank() && amount.isNotBlank() && date.isNotBlank()
        ) {
            Icon(Icons.Outlined.Save, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text("Save Invoice", fontWeight = FontWeight.Bold)
        }

        // Success message
        if (invoiceSaved) {
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = RexoColors.SuccessLight
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        Icons.Outlined.CheckCircle,
                        contentDescription = null,
                        tint = RexoColors.Success
                    )
                    Text(
                        text = "Invoice saved successfully!",
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.Success
                    )
                }
            }

            LaunchedEffect(invoiceSaved) {
                kotlinx.coroutines.delay(3000)
                viewModel.clearInvoiceSaved()
            }
        }

        // Error message
        if (error != null) {
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = RexoColors.ErrorLight
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        Icons.Outlined.Error,
                        contentDescription = null,
                        tint = RexoColors.Error
                    )
                    Text(
                        text = error!!,
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoColors.Error
                    )
                }
            }
        }

        // Invoice preview
        if (brandName.isNotBlank() || campaignTitle.isNotBlank()) {
            Text(
                text = "Preview",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            Surface(
                shape = RoundedCornerShape(12.dp),
                color = Color.White,
                border = BorderStroke(1.dp, RexoColors.CardBorder)
            ) {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "INVOICE",
                        style = RexoTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.AccentOrange
                    )
                    HorizontalDivider(color = RexoColors.CardBorder)
                    InvoiceRow("Brand", brandName)
                    InvoiceRow("Campaign", campaignTitle)
                    InvoiceRow("Amount", if (amount.isNotBlank()) "\u20B9$amount" else "-")
                    InvoiceRow("Date", date.ifBlank { "-" })
                    InvoiceRow("Status", "Pending")
                }
            }
        }
    }
}

@Composable
private fun InvoiceRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary
        )
        Text(
            text = value,
            style = RexoTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
            color = RexoColors.TextPrimary
        )
    }
}

// ─── PORTFOLIO ────────────────────────────────────────────────────────────────

@Composable
private fun PortfolioContent(
    viewModel: ServicesViewModel,
    modifier: Modifier = Modifier
) {
    val applications by viewModel.completedApplications.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()

    val completedWork = applications.filter { it.status in listOf("approved", "paid", "completed") }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(20.dp)
    ) {
        Text(
            text = "Portfolio",
            style = RexoTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold,
            color = RexoColors.TextPrimary
        )

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = "Your completed campaigns and work",
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary
        )

        Spacer(modifier = Modifier.height(16.dp))

        if (isLoading) {
            Box(
                modifier = Modifier.fillMaxWidth().padding(48.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = RexoColors.AccentOrange)
            }
        } else if (error != null) {
            ErrorCard(message = error!!, onRetry = { viewModel.loadData() })
        } else if (completedWork.isEmpty()) {
            EmptyCard(message = "No completed campaigns yet. Apply to campaigns to build your portfolio.")
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.weight(1f)
            ) {
                items(completedWork) { application ->
                    PortfolioCard(application = application)
                }
            }
        }
    }
}

@Composable
private fun PortfolioCard(application: CampaignApplicationDto) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Brand initial
            Surface(
                shape = RoundedCornerShape(8.dp),
                color = RexoColors.AccentOrange.copy(alpha = 0.1f),
                modifier = Modifier.size(44.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = application.brand_name.firstOrNull()?.uppercase() ?: "?",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.AccentOrange
                    )
                }
            }

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = application.campaign_title,
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = application.brand_name,
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.TextSecondary
                )
            }

            Surface(
                shape = RoundedCornerShape(6.dp),
                color = RexoColors.SuccessLight
            ) {
                Text(
                    text = application.status.replaceFirstChar { it.uppercase() },
                    style = RexoTheme.typography.labelSmall,
                    color = RexoColors.Success,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                )
            }
        }
    }
}

// ─── SHARED COMPOSABLES ───────────────────────────────────────────────────────

@Composable
private fun StatCard(
    label: String,
    value: String,
    icon: ImageVector,
    color: Color,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(24.dp)
            )
            Text(
                text = value,
                style = RexoTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )
            Text(
                text = label,
                style = RexoTheme.typography.bodySmall,
                color = RexoColors.TextSecondary
            )
        }
    }
}

@Composable
private fun ErrorCard(message: String, onRetry: () -> Unit) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = RexoColors.ErrorLight
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                Icons.Outlined.Error,
                contentDescription = null,
                tint = RexoColors.Error,
                modifier = Modifier.size(40.dp)
            )
            Text(
                text = message,
                style = RexoTheme.typography.bodyMedium,
                color = RexoColors.Error,
                textAlign = TextAlign.Center
            )
            Button(
                onClick = onRetry,
                colors = ButtonDefaults.buttonColors(containerColor = RexoColors.AccentOrange),
                shape = RoundedCornerShape(8.dp)
            ) {
                Text("Retry")
            }
        }
    }
}

@Composable
private fun EmptyCard(message: String) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = RexoColors.Gray50
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                Icons.Outlined.Info,
                contentDescription = null,
                tint = RexoColors.Gray400,
                modifier = Modifier.size(40.dp)
            )
            Text(
                text = message,
                style = RexoTheme.typography.bodyMedium,
                color = RexoColors.TextSecondary,
                textAlign = TextAlign.Center
            )
        }
    }
}

private fun formatNumber(number: Int): String {
    return when {
        number >= 1_000_000 -> String.format("%.1fM", number / 1_000_000.0)
        number >= 1_000 -> String.format("%.1fK", number / 1_000.0)
        else -> number.toString()
    }
}
