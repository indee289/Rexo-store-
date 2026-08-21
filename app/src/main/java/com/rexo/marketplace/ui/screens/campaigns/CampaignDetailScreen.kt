package com.rexo.marketplace.ui.screens.campaigns

import androidx.compose.foundation.layout.*
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.CampaignItem
import com.rexo.marketplace.ui.viewmodel.CampaignViewModel

/**
 * Campaign Detail Screen
 * Full campaign information with apply functionality.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CampaignDetailScreen(
    campaignId: String,
    onNavigateBack: () -> Unit = {},
    campaignViewModel: CampaignViewModel
) {
    val uiState by campaignViewModel.uiState.collectAsState()
    val campaigns by campaignViewModel.campaigns.collectAsState()
    val campaign = campaigns.find { it.id == campaignId }

    var showApplySheet by remember { mutableStateOf(false) }
    var pitchText by remember { mutableStateOf("") }
    var feeRequested by remember { mutableStateOf("") }

    // Handle success
    LaunchedEffect(uiState.showSuccess) {
        if (uiState.showSuccess) {
            showApplySheet = false
            pitchText = ""
            feeRequested = ""
            kotlinx.coroutines.delay(2000)
            campaignViewModel.clearSuccess()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Campaign Details") },
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
        if (campaign == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                if (uiState.isLoading) {
                    CircularProgressIndicator(color = RexoColors.AccentOrange)
                } else {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Outlined.Campaign,
                            contentDescription = "Not found",
                            modifier = Modifier.size(80.dp),
                            tint = RexoColors.Gray300
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Campaign not found",
                            style = RexoTheme.typography.titleMedium,
                            color = RexoColors.TextSecondary
                        )
                    }
                }
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .verticalScroll(rememberScrollState())
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Brand Info
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Surface(
                        modifier = Modifier.size(56.dp),
                        shape = CircleShape,
                        color = RexoColors.AccentOrange.copy(alpha = 0.1f)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(
                                text = campaign.brandName.firstOrNull()?.uppercase() ?: "B",
                                style = RexoTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = RexoColors.AccentOrange
                            )
                        }
                    }

                    Column {
                        Text(
                            text = campaign.brandName,
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = campaign.category,
                            style = RexoTheme.typography.bodySmall,
                            color = RexoColors.TextSecondary
                        )
                    }
                }

                // Campaign Title
                Text(
                    text = campaign.title,
                    style = RexoTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )

                // Status Badge
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = when (campaign.status) {
                        "active" -> RexoColors.Success.copy(alpha = 0.1f)
                        "closed" -> RexoColors.Error.copy(alpha = 0.1f)
                        else -> RexoColors.Warning.copy(alpha = 0.1f)
                    }
                ) {
                    Text(
                        text = campaign.status.replaceFirstChar { it.uppercase() },
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        style = RexoTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = when (campaign.status) {
                            "active" -> RexoColors.Success
                            "closed" -> RexoColors.Error
                            else -> RexoColors.Warning
                        }
                    )
                }

                // Description
                GlassSurface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "Description",
                            style = RexoTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = campaign.description,
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextSecondary
                        )
                    }
                }

                // Budget and Payout
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    GlassSurface(
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.AccountBalanceWallet,
                                contentDescription = "Budget",
                                tint = RexoColors.AccentOrange,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "\u20B9${String.format("%,.0f", campaign.budget)}",
                                style = RexoTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "Total Budget",
                                style = RexoTheme.typography.bodySmall,
                                color = RexoColors.TextSecondary
                            )
                        }
                    }

                    GlassSurface(
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Payments,
                                contentDescription = "Payout",
                                tint = RexoColors.Success,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "\u20B9${String.format("%,.0f", campaign.payoutPerCreator)}",
                                style = RexoTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "Per Creator",
                                style = RexoTheme.typography.bodySmall,
                                color = RexoColors.TextSecondary
                            )
                        }
                    }
                }

                // Slots Progress
                GlassSurface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "Slots",
                                style = RexoTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "${campaign.filledSlots}/${campaign.slots} filled",
                                style = RexoTheme.typography.bodyMedium,
                                color = RexoColors.TextSecondary
                            )
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        LinearProgressIndicator(
                            progress = {
                                if (campaign.slots > 0) campaign.filledSlots.toFloat() / campaign.slots.toFloat()
                                else 0f
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(8.dp),
                            color = RexoColors.AccentOrange,
                            trackColor = RexoColors.Gray200
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "${campaign.slots - campaign.filledSlots} slots remaining",
                            style = RexoTheme.typography.bodySmall,
                            color = RexoColors.Success
                        )
                    }
                }

                // Details Section
                GlassSurface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Text(
                            text = "Campaign Details",
                            style = RexoTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )

                        // Deliverable Type
                        DetailRow(
                            icon = Icons.Outlined.VideoLibrary,
                            label = "Deliverable Type",
                            value = campaign.deliverableType.ifEmpty { "Content" }
                        )

                        // Deadline
                        DetailRow(
                            icon = Icons.Outlined.CalendarToday,
                            label = "Deadline",
                            value = campaign.deadline.ifEmpty { "Not specified" }
                        )

                        // Category
                        DetailRow(
                            icon = Icons.Outlined.Category,
                            label = "Category",
                            value = campaign.category
                        )
                    }
                }

                // Success message
                if (uiState.showSuccess) {
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        color = RexoColors.Success.copy(alpha = 0.1f)
                    ) {
                        Row(
                            modifier = Modifier.padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.CheckCircle,
                                contentDescription = "Success",
                                tint = RexoColors.Success
                            )
                            Text(
                                text = uiState.successMessage ?: "Application submitted!",
                                style = RexoTheme.typography.bodyMedium,
                                color = RexoColors.Success,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }

                // Error message
                if (uiState.error != null) {
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        color = RexoColors.Error.copy(alpha = 0.1f)
                    ) {
                        Row(
                            modifier = Modifier.padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.ErrorOutline,
                                contentDescription = "Error",
                                tint = RexoColors.Error
                            )
                            Text(
                                text = uiState.error ?: "",
                                style = RexoTheme.typography.bodyMedium,
                                color = RexoColors.Error
                            )
                        }
                    }
                }

                // Apply Button
                if (campaign.status == "active" && campaign.filledSlots < campaign.slots) {
                    Button(
                        onClick = { showApplySheet = true },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = RexoColors.AccentOrange
                        ),
                        enabled = !uiState.isProcessing
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Send,
                            contentDescription = "Apply",
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Apply to Campaign",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))
            }
        }

        // Apply Bottom Sheet
        if (showApplySheet && campaign != null) {
            ModalBottomSheet(
                onDismissRequest = { showApplySheet = false },
                containerColor = Color.White
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = "Apply to Campaign",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = "Submit your pitch for \"${campaign.title}\"",
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoColors.TextSecondary
                    )

                    OutlinedTextField(
                        value = feeRequested,
                        onValueChange = { feeRequested = it },
                        label = { Text("Fee Requested (\u20B9)") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true,
                        placeholder = { Text("e.g. ${campaign.payoutPerCreator.toInt()}") }
                    )

                    OutlinedTextField(
                        value = pitchText,
                        onValueChange = { pitchText = it },
                        label = { Text("Your Pitch") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        minLines = 4,
                        maxLines = 6,
                        placeholder = { Text("Tell the brand why you're perfect for this campaign...") }
                    )

                    Button(
                        onClick = {
                            val fee = feeRequested.toDoubleOrNull() ?: campaign.payoutPerCreator
                            campaignViewModel.applyToCampaign(
                                campaignId = campaign.id,
                                campaignTitle = campaign.title,
                                brandName = campaign.brandName,
                                feeRequested = fee,
                                proposal = pitchText
                            )
                        },
                        enabled = pitchText.isNotBlank() && !uiState.isProcessing,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = RexoColors.AccentOrange
                        )
                    ) {
                        if (uiState.isProcessing) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(24.dp),
                                color = Color.White,
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text(
                                text = "Submit Application",
                                style = RexoTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                }
            }
        }
    }
}

@Composable
private fun DetailRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            modifier = Modifier.size(20.dp),
            tint = RexoColors.AccentOrange
        )
        Column {
            Text(
                text = label,
                style = RexoTheme.typography.bodySmall,
                color = RexoColors.TextSecondary
            )
            Text(
                text = value,
                style = RexoTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
        }
    }
}
