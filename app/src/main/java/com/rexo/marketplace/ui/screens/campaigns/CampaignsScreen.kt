package com.rexo.marketplace.ui.screens.campaigns

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
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
import androidx.compose.ui.window.Dialog
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme
import java.text.SimpleDateFormat
import java.util.*

/**
 * Campaigns Screen - Browse and apply to campaigns
 * Features:
 * - Search bar with filters
 * - Platform chips (Instagram, YouTube, TikTok, etc.)
 * - Campaign cards with details
 * - Apply modal/dialog
 * - Status badges
 * - Budget display
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CampaignsScreen(
    onNavigateBack: () -> Unit = {}
) {
    var searchQuery by remember { mutableStateOf("") }
    var selectedPlatform by remember { mutableStateOf("All") }
    var selectedCampaign by remember { mutableStateOf<Campaign?>(null) }
    var showApplyDialog by remember { mutableStateOf(false) }
    
    val platforms = listOf("All", "Instagram", "YouTube", "TikTok", "Twitter", "Facebook")
    
    val campaigns = remember {
        listOf(
            Campaign(
                id = "1",
                title = "Tech Product Launch Campaign",
                brand = "TechBrand Inc.",
                description = "Looking for tech influencers to promote our latest smartphone. Must have 10K+ followers and engagement rate above 3%.",
                platform = "Instagram",
                budget = 5000.0,
                deadline = Date(System.currentTimeMillis() + 7 * 86400000),
                applicants = 15,
                status = CampaignStatus.OPEN,
                requirements = listOf("10K+ followers", "3%+ engagement", "Tech niche"),
                deliverables = listOf("3 Instagram posts", "5 stories", "1 reel")
            ),
            Campaign(
                id = "2",
                title = "Fashion Brand Collaboration",
                brand = "StyleHub",
                description = "Partner with us for our summer collection launch. Looking for fashion content creators.",
                platform = "YouTube",
                budget = 3500.0,
                deadline = Date(System.currentTimeMillis() + 14 * 86400000),
                applicants = 8,
                status = CampaignStatus.OPEN,
                requirements = listOf("5K+ subscribers", "Fashion content", "Video quality"),
                deliverables = listOf("1 YouTube video", "3 shorts")
            ),
            Campaign(
                id = "3",
                title = "Food Review Series",
                brand = "Foodie Network",
                description = "Join our food review campaign and showcase local restaurants.",
                platform = "TikTok",
                budget = 2000.0,
                deadline = Date(System.currentTimeMillis() + 10 * 86400000),
                applicants = 20,
                status = CampaignStatus.OPEN,
                requirements = listOf("3K+ followers", "Food niche"),
                deliverables = listOf("5 TikTok videos")
            ),
            Campaign(
                id = "4",
                title = "Gaming Tournament Sponsorship",
                brand = "GameZone",
                description = "Promote our gaming tournament to your audience.",
                platform = "YouTube",
                budget = 4500.0,
                deadline = Date(System.currentTimeMillis() + 5 * 86400000),
                applicants = 12,
                status = CampaignStatus.URGENT,
                requirements = listOf("Gaming content", "10K+ subs"),
                deliverables = listOf("1 tournament stream", "3 promotional videos")
            ),
            Campaign(
                id = "5",
                title = "Fitness App Promotion",
                brand = "FitLife",
                description = "Help us promote our new fitness tracking app.",
                platform = "Instagram",
                budget = 3000.0,
                deadline = Date(System.currentTimeMillis() + 20 * 86400000),
                applicants = 18,
                status = CampaignStatus.OPEN,
                requirements = listOf("Fitness niche", "5K+ followers"),
                deliverables = listOf("2 posts", "4 stories", "App review")
            )
        )
    }
    
    val filteredCampaigns = remember(searchQuery, selectedPlatform) {
        campaigns.filter { campaign ->
            val matchesSearch = campaign.title.contains(searchQuery, ignoreCase = true) ||
                                campaign.brand.contains(searchQuery, ignoreCase = true) ||
                                campaign.description.contains(searchQuery, ignoreCase = true)
            val matchesPlatform = selectedPlatform == "All" || campaign.platform == selectedPlatform
            matchesSearch && matchesPlatform
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Campaigns",
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
                    IconButton(onClick = { /* TODO: Filter */ }) {
                        Icon(Icons.Outlined.FilterList, contentDescription = "Filter")
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
            contentPadding = PaddingValues(bottom = 80.dp)
        ) {
            // Search Bar
            item {
                SearchBar(
                    query = searchQuery,
                    onQueryChange = { searchQuery = it },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
            }
            
            // Platform Filters
            item {
                PlatformFilters(
                    platforms = platforms,
                    selectedPlatform = selectedPlatform,
                    onPlatformSelected = { selectedPlatform = it },
                    modifier = Modifier.padding(vertical = 12.dp)
                )
            }
            
            // Results Count
            item {
                Text(
                    text = "${filteredCampaigns.size} Campaigns Available",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
                )
            }
            
            // Campaign Cards
            items(filteredCampaigns) { campaign ->
                CampaignCard(
                    campaign = campaign,
                    onClick = { selectedCampaign = campaign },
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
                )
            }
            
            // Empty State
            if (filteredCampaigns.isEmpty()) {
                item {
                    EmptyState(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 60.dp)
                    )
                }
            }
        }
    }
    
    // Campaign Details Dialog
    selectedCampaign?.let { campaign ->
        CampaignDetailsDialog(
            campaign = campaign,
            onDismiss = { selectedCampaign = null },
            onApply = {
                showApplyDialog = true
                selectedCampaign = null
            }
        )
    }
    
    // Apply Confirmation Dialog
    if (showApplyDialog) {
        ApplyConfirmationDialog(
            onDismiss = { showApplyDialog = false },
            onConfirm = {
                // TODO: Submit application
                showApplyDialog = false
            }
        )
    }
}

data class Campaign(
    val id: String,
    val title: String,
    val brand: String,
    val description: String,
    val platform: String,
    val budget: Double,
    val deadline: Date,
    val applicants: Int,
    val status: CampaignStatus,
    val requirements: List<String>,
    val deliverables: List<String>
)

enum class CampaignStatus {
    OPEN, URGENT, CLOSED
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = modifier.fillMaxWidth(),
        placeholder = { Text("Search campaigns...") },
        leadingIcon = {
            Icon(Icons.Outlined.Search, contentDescription = "Search")
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(Icons.Outlined.Clear, contentDescription = "Clear")
                }
            }
        },
        shape = RoundedCornerShape(16.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = RexoTheme.colorScheme.surface.copy(alpha = 0.5f),
            unfocusedContainerColor = RexoTheme.colorScheme.surface.copy(alpha = 0.5f),
            focusedBorderColor = RexoTheme.colorScheme.primary,
            unfocusedBorderColor = RexoTheme.colorScheme.outline.copy(alpha = 0.3f)
        ),
        singleLine = true
    )
}

@Composable
fun PlatformFilters(
    platforms: List<String>,
    selectedPlatform: String,
    onPlatformSelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyRow(
        modifier = modifier,
        contentPadding = PaddingValues(horizontal = 20.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(platforms) { platform ->
            val isSelected = platform == selectedPlatform
            
            val backgroundColor by animateColorAsState(
                targetValue = if (isSelected) RexoTheme.colorScheme.primary else RexoTheme.colorScheme.surfaceVariant,
                animationSpec = tween(300),
                label = "platform_bg"
            )
            
            FilterChip(
                selected = isSelected,
                onClick = { onPlatformSelected(platform) },
                label = {
                    Text(
                        text = platform,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                    )
                },
                leadingIcon = if (platform != "All") {
                    {
                        Icon(
                            imageVector = getPlatformIcon(platform),
                            contentDescription = platform,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                } else null,
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = backgroundColor,
                    containerColor = backgroundColor
                )
            )
        }
    }
}

fun getPlatformIcon(platform: String): ImageVector {
    return when (platform) {
        "Instagram" -> Icons.Outlined.Camera
        "YouTube" -> Icons.Outlined.PlayCircle
        "TikTok" -> Icons.Outlined.MusicNote
        "Twitter" -> Icons.Outlined.TagFaces
        "Facebook" -> Icons.Outlined.Group
        else -> Icons.Outlined.Public
    }
}

@Composable
fun CampaignCard(
    campaign: Campaign,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val dateFormat = remember { SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()) }
    
    FloatingGlassCard(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
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
                // Platform Badge
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = getPlatformColor(campaign.platform).copy(alpha = 0.15f)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = getPlatformIcon(campaign.platform),
                            contentDescription = campaign.platform,
                            modifier = Modifier.size(16.dp),
                            tint = getPlatformColor(campaign.platform)
                        )
                        Text(
                            text = campaign.platform,
                            style = RexoTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = getPlatformColor(campaign.platform)
                        )
                    }
                }
                
                // Status Badge
                if (campaign.status == CampaignStatus.URGENT) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = Color(0xFFEF4444).copy(alpha = 0.15f)
                    ) {
                        Text(
                            text = "🔥 URGENT",
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            style = RexoTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFFEF4444)
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Title
            Text(
                text = campaign.title,
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            Spacer(modifier = Modifier.height(4.dp))
            
            // Brand
            Text(
                text = campaign.brand,
                style = RexoTheme.typography.bodyMedium,
                color = RexoTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Description
            Text(
                text = campaign.description,
                style = RexoTheme.typography.bodySmall,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Footer
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Budget
                Column {
                    Text(
                        text = "Budget",
                        style = RexoTheme.typography.labelSmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Text(
                        text = "₹${String.format("%,.0f", campaign.budget)}",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF10B981)
                    )
                }
                
                // Deadline
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "Deadline",
                        style = RexoTheme.typography.labelSmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Text(
                        text = dateFormat.format(campaign.deadline),
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Applicants
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Outlined.People,
                    contentDescription = "Applicants",
                    modifier = Modifier.size(16.dp),
                    tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "${campaign.applicants} applicants",
                    style = RexoTheme.typography.bodySmall,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
        }
    }
}

fun getPlatformColor(platform: String): Color {
    return when (platform) {
        "Instagram" -> Color(0xFFE4405F)
        "YouTube" -> Color(0xFFFF0000)
        "TikTok" -> Color(0xFF000000)
        "Twitter" -> Color(0xFF1DA1F2)
        "Facebook" -> Color(0xFF1877F2)
        else -> Color(0xFF6366F1)
    }
}

@Composable
fun CampaignDetailsDialog(
    campaign: Campaign,
    onDismiss: () -> Unit,
    onApply: () -> Unit
) {
    val dateFormat = remember { SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()) }
    
    Dialog(onDismissRequest = onDismiss) {
        GlassSurface(
            shape = RoundedCornerShape(28.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
                    .padding(24.dp)
                    .fillMaxWidth()
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Campaign Details",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Outlined.Close, contentDescription = "Close")
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Platform
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = getPlatformColor(campaign.platform).copy(alpha = 0.15f)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = getPlatformIcon(campaign.platform),
                            contentDescription = campaign.platform,
                            modifier = Modifier.size(20.dp),
                            tint = getPlatformColor(campaign.platform)
                        )
                        Text(
                            text = campaign.platform,
                            style = RexoTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = getPlatformColor(campaign.platform)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Title & Brand
                Text(
                    text = campaign.title,
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "by ${campaign.brand}",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoTheme.colorScheme.primary
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Description
                Text(
                    text = campaign.description,
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.8f)
                )
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // Requirements
                Text(
                    text = "Requirements",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                campaign.requirements.forEach { req ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.CheckCircle,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = RexoTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = req,
                            style = RexoTheme.typography.bodySmall
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Deliverables
                Text(
                    text = "Deliverables",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                campaign.deliverables.forEach { deliverable ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Assignment,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = RexoTheme.colorScheme.secondary
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = deliverable,
                            style = RexoTheme.typography.bodySmall
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // Stats
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text(
                            text = "Budget",
                            style = RexoTheme.typography.labelSmall,
                            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                        Text(
                            text = "₹${String.format("%,.0f", campaign.budget)}",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF10B981)
                        )
                    }
                    
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = "Deadline",
                            style = RexoTheme.typography.labelSmall,
                            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                        Text(
                            text = dateFormat.format(campaign.deadline),
                            style = RexoTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Apply Button
                Button(
                    onClick = onApply,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = RexoTheme.colorScheme.primary
                    )
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Send,
                        contentDescription = "Apply",
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Apply Now", style = RexoTheme.typography.titleMedium)
                }
            }
        }
    }
}

@Composable
fun ApplyConfirmationDialog(
    onDismiss: () -> Unit,
    onConfirm: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                imageVector = Icons.Outlined.CheckCircle,
                contentDescription = "Success",
                tint = Color(0xFF10B981),
                modifier = Modifier.size(48.dp)
            )
        },
        title = {
            Text(
                text = "Application Submitted!",
                style = RexoTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Text(
                text = "Your application has been submitted successfully. The brand will review it and get back to you soon.",
                style = RexoTheme.typography.bodyMedium,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.8f)
            )
        },
        confirmButton = {
            Button(
                onClick = onConfirm,
                shape = RoundedCornerShape(12.dp)
            ) {
                Text("Got it")
            }
        }
    )
}

@Composable
fun EmptyState(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Outlined.SearchOff,
            contentDescription = "No campaigns",
            modifier = Modifier.size(80.dp),
            tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.3f)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "No campaigns found",
            style = RexoTheme.typography.titleMedium,
            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        )
        
        Text(
            text = "Try adjusting your filters",
            style = RexoTheme.typography.bodySmall,
            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.5f)
        )
    }
}
