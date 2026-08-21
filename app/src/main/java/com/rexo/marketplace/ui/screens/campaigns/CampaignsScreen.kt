package com.rexo.marketplace.ui.screens.campaigns

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.ui.window.Dialog
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.CampaignItem
import com.rexo.marketplace.ui.viewmodel.CampaignUiState
import com.rexo.marketplace.ui.viewmodel.CampaignViewModel

/**
 * Campaigns Screen (Tasks tab)
 *
 * Premium clean white design showing real campaigns from Supabase via CampaignViewModel.
 * Features:
 * - Search bar with category filter chips
 * - Campaign cards with progress bars, platform icons, bookmark icons
 * - Campaign detail dialog when tapped
 * - Apply button that submits real applications to Supabase
 * - Proper loading/empty/error states
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CampaignsScreen(
    onNavigateBack: () -> Unit = {},
    onNavigateToCampaignDetail: (String) -> Unit = {},
    campaignViewModel: CampaignViewModel? = null
) {
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
        ?: remember { mutableStateOf(listOf("All")) }

    var selectedCampaign by remember { mutableStateOf<CampaignItem?>(null) }
    var showApplyDialog by remember { mutableStateOf(false) }
    var applyingCampaign by remember { mutableStateOf<CampaignItem?>(null) }
    var proposalText by remember { mutableStateOf("") }

    // Handle success state
    LaunchedEffect(uiState.showSuccess) {
        if (uiState.showSuccess) {
            showApplyDialog = false
            applyingCampaign = null
            proposalText = ""
        }
    }

    Scaffold(
        containerColor = Color.White,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Tasks",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            Icons.Outlined.ArrowBack,
                            contentDescription = "Back",
                            tint = RexoColors.TextPrimary
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White
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
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { viewModel?.updateSearchQuery(it) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 12.dp),
                    placeholder = {
                        Text(
                            "Search campaigns...",
                            color = RexoColors.TextSecondary
                        )
                    },
                    leadingIcon = {
                        Icon(
                            Icons.Outlined.Search,
                            contentDescription = "Search",
                            tint = RexoColors.TextSecondary
                        )
                    },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { viewModel?.updateSearchQuery("") }) {
                                Icon(
                                    Icons.Outlined.Clear,
                                    contentDescription = "Clear",
                                    tint = RexoColors.TextSecondary
                                )
                            }
                        }
                    },
                    shape = RoundedCornerShape(16.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedContainerColor = RexoColors.Gray50,
                        unfocusedContainerColor = RexoColors.Gray50,
                        focusedBorderColor = RexoColors.AccentOrange,
                        unfocusedBorderColor = RexoColors.CardBorder
                    ),
                    singleLine = true
                )
            }

            // Category Filter Chips
            item {
                LazyRow(
                    modifier = Modifier.padding(vertical = 8.dp),
                    contentPadding = PaddingValues(horizontal = 20.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(categories) { category ->
                        val isSelected = category == selectedCategory
                        FilterChip(
                            selected = isSelected,
                            onClick = { viewModel?.selectCategory(category) },
                            label = {
                                Text(
                                    text = category,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                )
                            },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = RexoColors.AccentOrange,
                                selectedLabelColor = Color.White,
                                containerColor = RexoColors.Gray100,
                                labelColor = RexoColors.TextSecondary
                            )
                        )
                    }
                }
            }

            // Campaign Count
            item {
                Text(
                    text = "$filteredCount of $totalCount campaigns",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoColors.TextSecondary,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
                )
            }

            // Loading State
            if (uiState.isLoading) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 60.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            color = RexoColors.AccentOrange
                        )
                    }
                }
            }

            // Error State
            if (uiState.error != null && !uiState.isLoading) {
                item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 60.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.ErrorOutline,
                            contentDescription = "Error",
                            modifier = Modifier.size(64.dp),
                            tint = RexoColors.Error
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Something went wrong",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = RexoColors.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = uiState.error ?: "",
                            style = RexoTheme.typography.bodySmall,
                            color = RexoColors.TextSecondary
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(
                            onClick = { viewModel?.loadCampaigns() },
                            shape = RoundedCornerShape(12.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = RexoColors.AccentOrange
                            )
                        ) {
                            Text("Retry")
                        }
                    }
                }
            }

            // Campaign Cards
            if (!uiState.isLoading && uiState.error == null) {
                if (campaigns.isEmpty()) {
                    item {
                        CampaignsEmptyState(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 60.dp)
                        )
                    }
                } else {
                    items(campaigns) { campaign ->
                        CampaignCardItem(
                            campaign = campaign,
                            onClick = { onNavigateToCampaignDetail(campaign.id) },
                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp)
                        )
                    }
                }
            }
        }
    }

    // Campaign Details Dialog
    selectedCampaign?.let { campaign ->
        CampaignDetailDialog(
            campaign = campaign,
            onDismiss = { selectedCampaign = null },
            onApply = {
                applyingCampaign = campaign
                selectedCampaign = null
                showApplyDialog = true
            }
        )
    }

    // Apply Dialog
    if (showApplyDialog && applyingCampaign != null) {
        ApplyDialog(
            campaign = applyingCampaign!!,
            proposal = proposalText,
            onProposalChange = { proposalText = it },
            isProcessing = uiState.isProcessing,
            onDismiss = {
                showApplyDialog = false
                applyingCampaign = null
                proposalText = ""
            },
            onSubmit = {
                viewModel?.applyToCampaign(
                    campaignId = applyingCampaign!!.id,
                    campaignTitle = applyingCampaign!!.title,
                    brandName = applyingCampaign!!.brandName,
                    feeRequested = applyingCampaign!!.payoutPerCreator,
                    proposal = proposalText
                )
            }
        )
    }

    // Success Snackbar
    if (uiState.showSuccess) {
        AlertDialog(
            onDismissRequest = { viewModel?.clearSuccess() },
            icon = {
                Icon(
                    imageVector = Icons.Outlined.CheckCircle,
                    contentDescription = "Success",
                    tint = RexoColors.Success,
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
                    text = uiState.successMessage ?: "Your application has been submitted successfully.",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoColors.TextSecondary
                )
            },
            confirmButton = {
                Button(
                    onClick = { viewModel?.clearSuccess() },
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = RexoColors.AccentOrange
                    )
                ) {
                    Text("Got it")
                }
            }
        )
    }
}

@Composable
private fun CampaignCardItem(
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
            // Header: Brand logo + Title + Bookmark
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top
            ) {
                // Brand logo square
                Surface(
                    modifier = Modifier.size(48.dp),
                    shape = RoundedCornerShape(12.dp),
                    color = RexoColors.Gray100
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

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = campaign.title,
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = campaign.brandName,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.AccentOrange,
                        fontWeight = FontWeight.Medium
                    )
                }

                // Bookmark icon
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

            // Category + Deliverable badges
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = RexoColors.AccentOrange.copy(alpha = 0.1f)
                ) {
                    Text(
                        text = campaign.category,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                        style = RexoTheme.typography.labelSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.AccentOrange
                    )
                }

                if (campaign.deliverableType.isNotBlank()) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = RexoColors.Gray100
                    ) {
                        Text(
                            text = campaign.deliverableType,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                            style = RexoTheme.typography.labelSmall,
                            color = RexoColors.TextSecondary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Platform icons row
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
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Slots progress bar
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

            // Footer: Budget + Slots + Deadline
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Budget
                Text(
                    text = "\u20B9${String.format("%,.0f", campaign.payoutPerCreator)}/creator",
                    style = RexoTheme.typography.bodySmall,
                    fontWeight = FontWeight.SemiBold,
                    color = RexoColors.Success
                )

                // Slots
                Text(
                    text = "${campaign.filledSlots}/${campaign.slots} slots",
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.TextSecondary
                )

                // Deadline
                Text(
                    text = campaign.deadline.take(10).ifBlank { "No deadline" },
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.TextSecondary
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Apply button
            Button(
                onClick = onClick,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = RexoColors.AccentOrange
                ),
                contentPadding = PaddingValues(vertical = 12.dp)
            ) {
                Text(
                    "Apply Now",
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
private fun CampaignDetailDialog(
    campaign: CampaignItem,
    onDismiss: () -> Unit,
    onApply: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = Color.White,
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
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
                    IconButton(onClick = onDismiss) {
                        Icon(
                            Icons.Outlined.Close,
                            contentDescription = "Close",
                            tint = RexoColors.TextSecondary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Category + Deliverable type
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = RexoColors.AccentOrange.copy(alpha = 0.1f)
                    ) {
                        Text(
                            text = campaign.category,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            style = RexoTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = RexoColors.AccentOrange
                        )
                    }
                    if (campaign.deliverableType.isNotBlank()) {
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = RexoColors.Gray100
                        ) {
                            Text(
                                text = campaign.deliverableType,
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                style = RexoTheme.typography.labelSmall,
                                color = RexoColors.TextSecondary
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Title & Brand
                Text(
                    text = campaign.title,
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "by ${campaign.brandName}",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoColors.AccentOrange
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Description
                Text(
                    text = campaign.description,
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoColors.TextSecondary
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Stats row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text(
                            text = "Budget",
                            style = RexoTheme.typography.labelSmall,
                            color = RexoColors.TextSecondary
                        )
                        Text(
                            text = "\u20B9${String.format("%,.0f", campaign.budget)}",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.Success
                        )
                    }
                    Column {
                        Text(
                            text = "Per Creator",
                            style = RexoTheme.typography.labelSmall,
                            color = RexoColors.TextSecondary
                        )
                        Text(
                            text = "\u20B9${String.format("%,.0f", campaign.payoutPerCreator)}",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.TextPrimary
                        )
                    }
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = "Slots",
                            style = RexoTheme.typography.labelSmall,
                            color = RexoColors.TextSecondary
                        )
                        Text(
                            text = "${campaign.filledSlots}/${campaign.slots}",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = RexoColors.TextPrimary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Deadline
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Outlined.Schedule,
                        contentDescription = "Deadline",
                        modifier = Modifier.size(16.dp),
                        tint = RexoColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Deadline: ${campaign.deadline.take(10).ifBlank { "Not set" }}",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Apply Button
                Button(
                    onClick = onApply,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = RexoColors.AccentOrange
                    ),
                    contentPadding = PaddingValues(vertical = 14.dp)
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Send,
                        contentDescription = "Apply",
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        "Apply Now",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
private fun ApplyDialog(
    campaign: CampaignItem,
    proposal: String,
    onProposalChange: (String) -> Unit,
    isProcessing: Boolean,
    onDismiss: () -> Unit,
    onSubmit: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = Color.White,
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
                    .padding(24.dp)
                    .fillMaxWidth()
            ) {
                Text(
                    text = "Apply to Campaign",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = campaign.title,
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoColors.TextSecondary
                )

                Spacer(modifier = Modifier.height(20.dp))

                OutlinedTextField(
                    value = proposal,
                    onValueChange = onProposalChange,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp),
                    placeholder = {
                        Text(
                            "Write your pitch or proposal...",
                            color = RexoColors.TextSecondary
                        )
                    },
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = RexoColors.AccentOrange,
                        unfocusedBorderColor = RexoColors.CardBorder
                    )
                )

                Spacer(modifier = Modifier.height(20.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text("Cancel")
                    }

                    Button(
                        onClick = onSubmit,
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        enabled = proposal.isNotBlank() && !isProcessing,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = RexoColors.AccentOrange
                        )
                    ) {
                        if (isProcessing) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                color = Color.White,
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text("Submit")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CampaignsEmptyState(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Outlined.SearchOff,
            contentDescription = "No campaigns",
            modifier = Modifier.size(80.dp),
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
            style = RexoTheme.typography.bodySmall,
            color = RexoColors.TextSecondary
        )
    }
}
