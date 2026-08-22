package com.rexo.marketplace.ui.screens.admin

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
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rexo.marketplace.data.repository.*
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.*

/**
 * Admin Center Screen - Complete 13-module admin panel
 * Clean white UI with RexoColors.AccentOrange accent.
 * Each module fetches real data from Supabase via AdminRepository.
 */

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminScreen(
    onNavigateBack: () -> Unit = {}
) {
    val viewModel: AdminViewModel = viewModel()
    val selectedModule by viewModel.selectedModule.collectAsState()
    val actionMessage by viewModel.actionMessage.collectAsState()

    val modules = listOf(
        "Dashboard", "Users", "Campaigns", "Submissions",
        "Deposits", "Withdrawals", "Shop", "Disputes",
        "KYC", "Wallets", "Settings", "Audit Logs", "Broadcast"
    )

    // Show action snackbar
    val snackbarHostState = remember { SnackbarHostState() }
    LaunchedEffect(actionMessage) {
        actionMessage?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearActionMessage()
        }
    }

    Scaffold(
        containerColor = Color.White,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Admin Center",
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
                actions = {
                    IconButton(onClick = { viewModel.selectModule(selectedModule) }) {
                        Icon(
                            Icons.Outlined.Refresh,
                            contentDescription = "Refresh",
                            tint = RexoColors.AccentOrange
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Module Tab Row
            ScrollableTabRow(
                selectedTabIndex = selectedModule,
                containerColor = Color.White,
                contentColor = RexoColors.AccentOrange,
                edgePadding = 16.dp,
                indicator = { tabPositions ->
                    if (selectedModule < tabPositions.size) {
                        TabRowDefaults.SecondaryIndicator(
                            modifier = Modifier.tabIndicatorOffset(tabPositions[selectedModule]),
                            color = RexoColors.AccentOrange
                        )
                    }
                }
            ) {
                modules.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedModule == index,
                        onClick = { viewModel.selectModule(index) },
                        text = {
                            Text(
                                text = title,
                                fontWeight = if (selectedModule == index) FontWeight.Bold else FontWeight.Normal,
                                color = if (selectedModule == index) RexoColors.AccentOrange else RexoColors.TextSecondary,
                                maxLines = 1
                            )
                        }
                    )
                }
            }

            // Module Content
            when (selectedModule) {
                0 -> DashboardTab(viewModel)
                1 -> UserManagementTab(viewModel)
                2 -> CampaignControlTab(viewModel)
                3 -> SubmissionsTab(viewModel)
                4 -> DepositsTab(viewModel)
                5 -> WithdrawalsTab(viewModel)
                6 -> ShopAdminTab(viewModel)
                7 -> DisputesTab(viewModel)
                8 -> KycTab(viewModel)
                9 -> WalletsTab(viewModel)
                10 -> SettingsTab(viewModel)
                11 -> AuditLogsTab(viewModel)
                12 -> BroadcastTab(viewModel)
            }
        }
    }
}

// ========== MODULE 1: DASHBOARD ==========

@Composable
private fun DashboardTab(viewModel: AdminViewModel) {
    val state by viewModel.dashboardState.collectAsState()

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadDashboard() }
    ) {
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Text(
                    text = "Platform Overview",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            // Stats Row 1
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    StatCard(
                        icon = Icons.Outlined.People,
                        label = "Total Users",
                        value = state.stats.totalUsers.toString(),
                        color = Color(0xFF6366F1),
                        modifier = Modifier.weight(1f)
                    )
                    StatCard(
                        icon = Icons.Outlined.Campaign,
                        label = "Active Campaigns",
                        value = state.stats.activeCampaigns.toString(),
                        color = RexoColors.Warning,
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            // Stats Row 2
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    StatCard(
                        icon = Icons.Outlined.Lock,
                        label = "Locked Escrow",
                        value = "₹${formatAmount(state.stats.lockedEscrow)}",
                        color = RexoColors.AccentOrange,
                        modifier = Modifier.weight(1f)
                    )
                    StatCard(
                        icon = Icons.Outlined.Payments,
                        label = "Pending Payouts",
                        value = "₹${formatAmount(state.stats.pendingPayouts)}",
                        color = RexoColors.Error,
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            // Revenue Section
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Revenue Overview",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = Color.White,
                    border = BorderStroke(1.dp, RexoColors.CardBorder)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        RevenueRow("Total Wallet Balance", state.stats.totalWalletBalance)
                        Spacer(modifier = Modifier.height(8.dp))
                        RevenueRow("Total Revenue (Earnings)", state.stats.totalRevenue)
                        Spacer(modifier = Modifier.height(8.dp))
                        RevenueRow("Total Campaigns", state.stats.totalCampaigns.toDouble())
                    }
                }
            }

            // Quick Stats
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Financial Health",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = Color.White,
                    border = BorderStroke(1.dp, RexoColors.CardBorder)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        val total = state.stats.totalWalletBalance + state.stats.lockedEscrow
                        val escrowPct = if (total > 0) (state.stats.lockedEscrow / total).toFloat() else 0f

                        Text("Escrow vs Available", style = RexoTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                        Spacer(modifier = Modifier.height(8.dp))
                        LinearProgressIndicator(
                            progress = { escrowPct },
                            modifier = Modifier.fillMaxWidth().height(8.dp),
                            color = RexoColors.AccentOrange,
                            trackColor = RexoColors.Gray200,
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Escrow: ${(escrowPct * 100).toInt()}%", style = RexoTheme.typography.bodySmall, color = RexoColors.TextSecondary)
                            Text("Available: ${((1 - escrowPct) * 100).toInt()}%", style = RexoTheme.typography.bodySmall, color = RexoColors.TextSecondary)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun RevenueRow(label: String, value: Double) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = label, style = RexoTheme.typography.bodyMedium, color = RexoColors.TextSecondary)
        Text(
            text = "₹${formatAmount(value)}",
            style = RexoTheme.typography.bodyMedium,
            fontWeight = FontWeight.Bold,
            color = RexoColors.TextPrimary
        )
    }
}

// ========== MODULE 2: USER MANAGEMENT ==========

@Composable
private fun UserManagementTab(viewModel: AdminViewModel) {
    val state by viewModel.userState.collectAsState()
    var searchText by remember { mutableStateOf("") }
    var selectedRole by remember { mutableStateOf("all") }
    var showActionDialog by remember { mutableStateOf<AdminUserDto?>(null) }

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadUsers() }
    ) {
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Search Bar
            item {
                OutlinedTextField(
                    value = searchText,
                    onValueChange = {
                        searchText = it
                        viewModel.loadUsers(search = it, role = selectedRole)
                    },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("Search users by name or email...") },
                    leadingIcon = { Icon(Icons.Outlined.Search, contentDescription = null) },
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = RexoColors.AccentOrange,
                        cursorColor = RexoColors.AccentOrange
                    ),
                    singleLine = true
                )
            }

            // Role Filter Chips
            item {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    listOf("all", "creator", "brand", "admin").forEach { role ->
                        FilterChip(
                            selected = selectedRole == role,
                            onClick = {
                                selectedRole = role
                                viewModel.loadUsers(search = searchText, role = role)
                            },
                            label = { Text(role.replaceFirstChar { it.uppercase() }) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = RexoColors.AccentOrange.copy(alpha = 0.1f),
                                selectedLabelColor = RexoColors.AccentOrange
                            )
                        )
                    }
                }
            }

            item {
                Text(
                    text = "Users (${state.users.size})",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            if (state.users.isEmpty()) {
                item { EmptyState(icon = Icons.Outlined.People, message = "No users found") }
            } else {
                items(state.users) { user ->
                    UserManagementCard(
                        user = user,
                        onActionClick = { showActionDialog = user }
                    )
                }
            }
        }
    }

    // User Action Dialog
    showActionDialog?.let { user ->
        UserActionDialog(
            user = user,
            onDismiss = { showActionDialog = null },
            onVerifyToggle = {
                viewModel.toggleUserVerification(user.id, user.is_verified)
                showActionDialog = null
            },
            onRoleChange = { role ->
                viewModel.changeUserRole(user.id, role)
                showActionDialog = null
            },
            onSuspend = {
                viewModel.suspendUser(user.id, "Admin action")
                showActionDialog = null
            },
            onUnsuspend = {
                viewModel.unsuspendUser(user.id)
                showActionDialog = null
            },
            onBan = {
                viewModel.banUser(user.id, "Admin action")
                showActionDialog = null
            },
            onUnban = {
                viewModel.unbanUser(user.id)
                showActionDialog = null
            },
            onDelete = {
                viewModel.deleteUser(user.id)
                showActionDialog = null
            }
        )
    }
}

@Composable
private fun UserManagementCard(user: AdminUserDto, onActionClick: () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = (user.name ?: "").ifBlank { "Unknown" },
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.TextPrimary
                    )
                    if (user.is_verified) {
                        Spacer(modifier = Modifier.width(4.dp))
                        Icon(Icons.Outlined.Verified, contentDescription = "Verified", tint = RexoColors.AccentOrange, modifier = Modifier.size(16.dp))
                    }
                }
                Text(text = user.email ?: "", style = RexoTheme.typography.bodySmall, color = RexoColors.TextSecondary)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    StatusChip(user.role, Color(0xFF6366F1))
                    if (user.is_banned) StatusChip("Banned", RexoColors.Error)
                    if (user.is_suspended) StatusChip("Suspended", RexoColors.Warning)
                }
            }
            IconButton(onClick = onActionClick) {
                Icon(Icons.Outlined.MoreVert, contentDescription = "Actions", tint = RexoColors.TextSecondary)
            }
        }
    }
}

@Composable
private fun UserActionDialog(
    user: AdminUserDto,
    onDismiss: () -> Unit,
    onVerifyToggle: () -> Unit,
    onRoleChange: (String) -> Unit,
    onSuspend: () -> Unit,
    onUnsuspend: () -> Unit,
    onBan: () -> Unit,
    onUnban: () -> Unit,
    onDelete: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Actions: ${(user.name ?: "").ifBlank { user.email ?: "User" }}", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                TextButton(onClick = onVerifyToggle, modifier = Modifier.fillMaxWidth()) {
                    Text(
                        if (user.is_verified) "Remove Verified Badge" else "Grant Verified Badge",
                        color = RexoColors.AccentOrange
                    )
                }
                HorizontalDivider()
                Text("Change Role:", style = RexoTheme.typography.bodySmall, color = RexoColors.TextSecondary)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("creator", "brand", "admin").forEach { role ->
                        FilterChip(
                            selected = user.role == role,
                            onClick = { onRoleChange(role) },
                            label = { Text(role.replaceFirstChar { it.uppercase() }) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = RexoColors.AccentOrange.copy(alpha = 0.1f)
                            )
                        )
                    }
                }
                HorizontalDivider()
                if (user.is_suspended) {
                    TextButton(onClick = onUnsuspend, modifier = Modifier.fillMaxWidth()) {
                        Text("Unsuspend", color = RexoColors.Success)
                    }
                } else {
                    TextButton(onClick = onSuspend, modifier = Modifier.fillMaxWidth()) {
                        Text("Suspend", color = RexoColors.Warning)
                    }
                }
                if (user.is_banned) {
                    TextButton(onClick = onUnban, modifier = Modifier.fillMaxWidth()) {
                        Text("Unban", color = RexoColors.Success)
                    }
                } else {
                    TextButton(onClick = onBan, modifier = Modifier.fillMaxWidth()) {
                        Text("Ban", color = RexoColors.Error)
                    }
                }
                HorizontalDivider()
                TextButton(onClick = onDelete, modifier = Modifier.fillMaxWidth()) {
                    Text("Delete Account", color = RexoColors.Error)
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text("Close", color = RexoColors.TextSecondary) }
        }
    )
}

// ========== MODULE 3: CAMPAIGN CONTROL ==========

@Composable
private fun CampaignControlTab(viewModel: AdminViewModel) {
    val state by viewModel.campaignState.collectAsState()
    var selectedFilter by remember { mutableStateOf("all") }

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadCampaigns() }
    ) {
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Filter Chips
            item {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    listOf("all", "active", "paused", "completed", "cancelled").forEach { filter ->
                        FilterChip(
                            selected = selectedFilter == filter,
                            onClick = {
                                selectedFilter = filter
                                viewModel.loadCampaigns(filter)
                            },
                            label = { Text(filter.replaceFirstChar { it.uppercase() }) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = RexoColors.AccentOrange.copy(alpha = 0.1f),
                                selectedLabelColor = RexoColors.AccentOrange
                            )
                        )
                    }
                }
            }

            item {
                Text(
                    text = "Campaigns (${state.campaigns.size})",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            if (state.campaigns.isEmpty()) {
                item { EmptyState(icon = Icons.Outlined.Campaign, message = "No campaigns found") }
            } else {
                items(state.campaigns) { campaign ->
                    CampaignControlCard(
                        campaign = campaign,
                        onPause = { viewModel.pauseCampaign(campaign.id) },
                        onResume = { viewModel.resumeCampaign(campaign.id) },
                        onForceComplete = { viewModel.forceCompleteCampaign(campaign.id) },
                        onCancel = { viewModel.forceCancelCampaign(campaign.id) },
                        onDelete = { viewModel.deleteCampaign(campaign.id) }
                    )
                }
            }
        }
    }
}

@Composable
private fun CampaignControlCard(
    campaign: AdminCampaignListDto,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onForceComplete: () -> Unit,
    onCancel: () -> Unit,
    onDelete: () -> Unit
) {
    var showActions by remember { mutableStateOf(false) }

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = campaign.title.ifBlank { "Untitled Campaign" },
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.TextPrimary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = "by ${campaign.brand_name.ifBlank { "Unknown" }} | Budget: ₹${formatAmount(campaign.budget)}",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                }
                StatusChip(campaign.status, getStatusColor(campaign.status))
            }

            if (showActions) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    if (campaign.status == "active") {
                        SmallActionButton("Pause", RexoColors.Warning, onPause)
                    }
                    if (campaign.status == "paused") {
                        SmallActionButton("Resume", RexoColors.Success, onResume)
                    }
                    if (campaign.status != "completed") {
                        SmallActionButton("Complete", Color(0xFF6366F1), onForceComplete)
                    }
                    if (campaign.status != "cancelled") {
                        SmallActionButton("Cancel", RexoColors.Error, onCancel)
                    }
                    SmallActionButton("Delete", RexoColors.Error, onDelete)
                }
            }

            Spacer(modifier = Modifier.height(4.dp))
            TextButton(
                onClick = { showActions = !showActions },
                modifier = Modifier.align(Alignment.End)
            ) {
                Text(
                    if (showActions) "Hide Actions" else "Show Actions",
                    color = RexoColors.AccentOrange,
                    style = RexoTheme.typography.bodySmall
                )
            }
        }
    }
}

// ========== MODULE 4: SUBMISSIONS ==========

@Composable
private fun SubmissionsTab(viewModel: AdminViewModel) {
    val state by viewModel.submissionState.collectAsState()
    var selectedFilter by remember { mutableStateOf("all") }

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadSubmissions() }
    ) {
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("all", "applied", "submitted", "approved", "paid", "rejected").forEach { filter ->
                        FilterChip(
                            selected = selectedFilter == filter,
                            onClick = {
                                selectedFilter = filter
                                viewModel.loadSubmissions(filter)
                            },
                            label = { Text(filter.replaceFirstChar { it.uppercase() }) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = RexoColors.AccentOrange.copy(alpha = 0.1f),
                                selectedLabelColor = RexoColors.AccentOrange
                            )
                        )
                    }
                }
            }

            item {
                Text(
                    "Submissions (${state.submissions.size})",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            if (state.submissions.isEmpty()) {
                item { EmptyState(icon = Icons.Outlined.Assignment, message = "No submissions found") }
            } else {
                items(state.submissions) { submission ->
                    SubmissionCard(
                        submission = submission,
                        onApprove = { viewModel.approveSubmission(submission.id) },
                        onReject = { viewModel.rejectSubmission(submission.id, "Not meeting requirements") },
                        onDisburse = { viewModel.disburseSubmissionPayout(submission.id, submission.creator_id, submission.fee_requested) }
                    )
                }
            }
        }
    }
}

@Composable
private fun SubmissionCard(
    submission: AdminSubmissionDto,
    onApprove: () -> Unit,
    onReject: () -> Unit,
    onDisburse: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = submission.campaign_title?.ifBlank { "Campaign" } ?: "Campaign",
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.TextPrimary
                    )
                    Text(
                        text = "by ${submission.creator_name?.ifBlank { "Creator" } ?: "Creator"} | ₹${formatAmount(submission.fee_requested)}",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                    if (!submission.deliverable_url.isNullOrBlank()) {
                        Text(
                            text = "Deliverable: ${submission.deliverable_url}",
                            style = RexoTheme.typography.bodySmall,
                            color = Color(0xFF6366F1),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
                StatusChip(submission.status, getStatusColor(submission.status))
            }

            if (submission.status == "submitted" || submission.status == "applied") {
                Spacer(modifier = Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    SmallActionButton("Approve", RexoColors.Success, onApprove)
                    SmallActionButton("Reject", RexoColors.Error, onReject)
                }
            }
            if (submission.status == "approved") {
                Spacer(modifier = Modifier.height(8.dp))
                SmallActionButton("Disburse Payout", RexoColors.AccentOrange, onDisburse)
            }
        }
    }
}

// ========== MODULE 5: DEPOSITS ==========

@Composable
private fun DepositsTab(viewModel: AdminViewModel) {
    val state by viewModel.depositState.collectAsState()

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadDeposits() }
    ) {
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                Text(
                    "Pending Deposits (${state.deposits.size})",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            if (state.deposits.isEmpty()) {
                item { EmptyState(icon = Icons.Outlined.Payments, message = "No pending deposits") }
            } else {
                items(state.deposits) { deposit ->
                    DepositCard(
                        deposit = deposit,
                        onApprove = { viewModel.approveDeposit(deposit.id, deposit.brand_id, deposit.amount) },
                        onReject = { viewModel.rejectDeposit(deposit.id, "Invalid payment proof") }
                    )
                }
            }
        }
    }
}

@Composable
private fun DepositCard(
    deposit: AdminDepositDto,
    onApprove: () -> Unit,
    onReject: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = deposit.brand_name?.ifBlank { "Brand" } ?: "Brand",
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.TextPrimary
                    )
                    Text(
                        text = "Amount: ₹${formatAmount(deposit.amount)}",
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoColors.Success,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "Method: ${deposit.payment_method ?: "N/A"} | Ref: ${deposit.transaction_ref ?: "N/A"}",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                    Text(
                        text = formatDate(deposit.created_at ?: ""),
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.Gray400
                    )
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                SmallActionButton("Approve & Credit", RexoColors.Success, onApprove)
                SmallActionButton("Reject", RexoColors.Error, onReject)
            }
        }
    }
}

// ========== MODULE 6: WITHDRAWALS ==========

@Composable
private fun WithdrawalsTab(viewModel: AdminViewModel) {
    val state by viewModel.withdrawalState.collectAsState()

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadWithdrawals() }
    ) {
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                Text(
                    "Pending Withdrawals (${state.withdrawals.size})",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            if (state.withdrawals.isEmpty()) {
                item { EmptyState(icon = Icons.Outlined.AccountBalanceWallet, message = "No pending withdrawals") }
            } else {
                items(state.withdrawals) { withdrawal ->
                    WithdrawalCard(
                        withdrawal = withdrawal,
                        onApprove = { viewModel.approveWithdrawal(withdrawal.id, "REF-${System.currentTimeMillis()}") },
                        onReject = { viewModel.rejectWithdrawal(withdrawal.id, "Insufficient details") }
                    )
                }
            }
        }
    }
}

@Composable
private fun WithdrawalCard(
    withdrawal: AdminWithdrawalDto,
    onApprove: () -> Unit,
    onReject: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = withdrawal.user_name?.ifBlank { "User" } ?: "User",
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.TextPrimary
                    )
                    Text(
                        text = "Amount: ₹${formatAmount(withdrawal.amount)}",
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoColors.AccentOrange,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "Method: ${withdrawal.payout_method ?: "N/A"}",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                    Text(
                        text = formatDate(withdrawal.created_at ?: ""),
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.Gray400
                    )
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                SmallActionButton("Approve", RexoColors.Success, onApprove)
                SmallActionButton("Hold/Reject", RexoColors.Error, onReject)
            }
        }
    }
}

// ========== MODULE 7: SHOP ADMIN ==========

@Composable
private fun ShopAdminTab(viewModel: AdminViewModel) {
    val state by viewModel.shopState.collectAsState()
    var showAddProduct by remember { mutableStateOf(false) }
    var showProducts by remember { mutableStateOf(true) }

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadShop() }
    ) {
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Toggle between products and orders
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(
                        selected = showProducts,
                        onClick = { showProducts = true },
                        label = { Text("Products (${state.products.size})") },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = RexoColors.AccentOrange.copy(alpha = 0.1f),
                            selectedLabelColor = RexoColors.AccentOrange
                        )
                    )
                    FilterChip(
                        selected = !showProducts,
                        onClick = { showProducts = false },
                        label = { Text("Orders (${state.orders.size})") },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = RexoColors.AccentOrange.copy(alpha = 0.1f),
                            selectedLabelColor = RexoColors.AccentOrange
                        )
                    )
                }
            }

            if (showProducts) {
                item {
                    Button(
                        onClick = { showAddProduct = true },
                        colors = ButtonDefaults.buttonColors(containerColor = RexoColors.AccentOrange),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(Icons.Outlined.Add, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Add Product")
                    }
                }

                if (state.products.isEmpty()) {
                    item { EmptyState(icon = Icons.Outlined.ShoppingBag, message = "No products yet") }
                } else {
                    items(state.products) { product ->
                        ProductCard(
                            product = product,
                            onDelete = { viewModel.deleteProduct(product.id) }
                        )
                    }
                }
            } else {
                if (state.orders.isEmpty()) {
                    item { EmptyState(icon = Icons.Outlined.Receipt, message = "No orders yet") }
                } else {
                    items(state.orders) { order ->
                        OrderCard(
                            order = order,
                            onUpdateStatus = { newStatus -> viewModel.updateOrderStatus(order.id, newStatus) }
                        )
                    }
                }
            }
        }
    }

    // Add Product Dialog
    if (showAddProduct) {
        AddProductDialog(
            onDismiss = { showAddProduct = false },
            onAdd = { name, desc, price, stock ->
                viewModel.addProduct(name, desc, price, stock)
                showAddProduct = false
            }
        )
    }
}

@Composable
private fun ProductCard(product: AdminProductDto, onDelete: () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(product.name ?: "Product", style = RexoTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = RexoColors.TextPrimary)
                Text("₹${formatAmount(product.price)} | Stock: ${product.stock}", style = RexoTheme.typography.bodySmall, color = RexoColors.TextSecondary)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                StatusChip(product.status, getStatusColor(product.status))
                IconButton(onClick = onDelete, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Outlined.Delete, contentDescription = "Delete", tint = RexoColors.Error, modifier = Modifier.size(18.dp))
                }
            }
        }
    }
}

@Composable
private fun OrderCard(order: AdminOrderDto, onUpdateStatus: (String) -> Unit) {
    var expanded by remember { mutableStateOf(false) }

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("Order #${order.id.takeLast(8)}", style = RexoTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = RexoColors.TextPrimary)
                    Text("Qty: ${order.quantity} | Total: ₹${formatAmount(order.total_amount)}", style = RexoTheme.typography.bodySmall, color = RexoColors.TextSecondary)
                }
                StatusChip(order.status, getStatusColor(order.status))
            }
            Spacer(modifier = Modifier.height(4.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                listOf("pending", "shipped", "delivered", "cancelled").forEach { status ->
                    if (status != order.status) {
                        SmallActionButton(
                            text = status.replaceFirstChar { it.uppercase() },
                            color = getStatusColor(status),
                            onClick = { onUpdateStatus(status) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun AddProductDialog(onDismiss: () -> Unit, onAdd: (String, String, Double, Int) -> Unit) {
    var name by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var price by remember { mutableStateOf("") }
    var stock by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Product", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Name") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(8.dp))
                OutlinedTextField(value = description, onValueChange = { description = it }, label = { Text("Description") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(8.dp))
                OutlinedTextField(value = price, onValueChange = { price = it }, label = { Text("Price (INR)") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(8.dp))
                OutlinedTextField(value = stock, onValueChange = { stock = it }, label = { Text("Stock") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(8.dp))
            }
        },
        confirmButton = {
            Button(
                onClick = { onAdd(name, description, price.toDoubleOrNull() ?: 0.0, stock.toIntOrNull() ?: 0) },
                colors = ButtonDefaults.buttonColors(containerColor = RexoColors.AccentOrange),
                shape = RoundedCornerShape(8.dp)
            ) { Text("Add") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel", color = RexoColors.TextSecondary) }
        }
    )
}

// ========== MODULE 8: DISPUTES ==========

@Composable
private fun DisputesTab(viewModel: AdminViewModel) {
    val state by viewModel.disputeState.collectAsState()

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadDisputes() }
    ) {
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                Text(
                    "Disputes (${state.disputes.size})",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            if (state.disputes.isEmpty()) {
                item { EmptyState(icon = Icons.Outlined.Gavel, message = "No disputes") }
            } else {
                items(state.disputes) { dispute ->
                    DisputeCard(
                        dispute = dispute,
                        onRefundBrand = { viewModel.resolveDispute(dispute.id, "Refunded to brand", "refund_brand") },
                        onDisburseCreator = { viewModel.resolveDispute(dispute.id, "Disbursed to creator", "disburse_creator") },
                        onDismiss = { viewModel.dismissDispute(dispute.id, "No valid grounds") }
                    )
                }
            }
        }
    }
}

@Composable
private fun DisputeCard(
    dispute: AdminDisputeDto,
    onRefundBrand: () -> Unit,
    onDisburseCreator: () -> Unit,
    onDismiss: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = dispute.reason.ifBlank { "Dispute" },
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.TextPrimary
                    )
                    Text(
                        text = dispute.details.ifBlank { "No details provided" },
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = "Campaign: ${dispute.campaign_id.takeLast(8)}",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.Gray400
                    )
                }
                StatusChip(dispute.status, getStatusColor(dispute.status))
            }

            if (dispute.status == "open") {
                Spacer(modifier = Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    SmallActionButton("Refund Brand", RexoColors.Warning, onRefundBrand)
                    SmallActionButton("Pay Creator", RexoColors.Success, onDisburseCreator)
                    SmallActionButton("Dismiss", RexoColors.Gray500, onDismiss)
                }
            }
        }
    }
}

// ========== MODULE 9: KYC VERIFICATION ==========

@Composable
private fun KycTab(viewModel: AdminViewModel) {
    val state by viewModel.kycState.collectAsState()

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadKyc() }
    ) {
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                Text(
                    "Pending KYC Approvals (${state.documents.size})",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            if (state.documents.isEmpty()) {
                item { EmptyState(icon = Icons.Outlined.VerifiedUser, message = "No pending KYC requests") }
            } else {
                items(state.documents) { kyc ->
                    KycCard(
                        kyc = kyc,
                        onApprove = { viewModel.approveKyc(kyc.id, kyc.user_id) },
                        onReject = { viewModel.rejectKyc(kyc.id, "Documents unclear, please re-upload") }
                    )
                }
            }
        }
    }
}

@Composable
private fun KycCard(
    kyc: AdminKycDto,
    onApprove: () -> Unit,
    onReject: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = kyc.user_name.ifBlank { "User" },
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.TextPrimary
                    )
                    Text(
                        text = "Document: ${kyc.document_type.ifBlank { "Identity" }}",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                    if (kyc.document_url.isNotBlank()) {
                        Text(
                            text = "Doc URL: ${kyc.document_url}",
                            style = RexoTheme.typography.bodySmall,
                            color = Color(0xFF6366F1),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                    Text(
                        text = "Submitted: ${formatDate(kyc.submitted_at)}",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.Gray400
                    )
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                SmallActionButton("Approve", RexoColors.Success, onApprove)
                SmallActionButton("Reject", RexoColors.Error, onReject)
            }
        }
    }
}

// ========== MODULE 10: WALLETS & ESCROW ==========

@Composable
private fun WalletsTab(viewModel: AdminViewModel) {
    val state by viewModel.walletState.collectAsState()

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadWallets() }
    ) {
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Platform-wide overview
            item {
                val totalAvailable = state.wallets.sumOf { it.available_balance }
                val totalEscrow = state.wallets.sumOf { it.escrow_balance }

                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = Color.White,
                    border = BorderStroke(1.dp, RexoColors.CardBorder)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Platform Wallet Overview", style = RexoTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = RexoColors.TextPrimary)
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                            Column {
                                Text("Total Available", style = RexoTheme.typography.bodySmall, color = RexoColors.TextSecondary)
                                Text("₹${formatAmount(totalAvailable)}", style = RexoTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = RexoColors.Success)
                            }
                            Column {
                                Text("Total Escrow", style = RexoTheme.typography.bodySmall, color = RexoColors.TextSecondary)
                                Text("₹${formatAmount(totalEscrow)}", style = RexoTheme.typography.bodyLarge, fontWeight = FontWeight.Bold, color = RexoColors.AccentOrange)
                            }
                        }
                    }
                }
            }

            item {
                Text(
                    "User Wallets (${state.wallets.size})",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            if (state.wallets.isEmpty()) {
                item { EmptyState(icon = Icons.Outlined.AccountBalanceWallet, message = "No wallets found") }
            } else {
                items(state.wallets) { wallet ->
                    WalletCard(
                        wallet = wallet,
                        onFreeze = { viewModel.freezeWallet(wallet.user_id) },
                        onUnfreeze = { viewModel.unfreezeWallet(wallet.user_id) },
                        onCredit = { viewModel.manualCreditWallet(wallet.user_id, 100.0, "Admin manual credit") },
                        onDebit = { viewModel.manualDebitWallet(wallet.user_id, 100.0, "Admin manual debit") }
                    )
                }
            }
        }
    }
}

@Composable
private fun WalletCard(
    wallet: AdminWalletDto,
    onFreeze: () -> Unit,
    onUnfreeze: () -> Unit,
    onCredit: () -> Unit,
    onDebit: () -> Unit
) {
    var showActions by remember { mutableStateOf(false) }

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { showActions = !showActions },
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, if (wallet.is_frozen) RexoColors.Error.copy(alpha = 0.3f) else RexoColors.CardBorder)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "User: ${wallet.user_id.takeLast(8)}",
                            style = RexoTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = RexoColors.TextPrimary
                        )
                        if (wallet.is_frozen) {
                            Spacer(modifier = Modifier.width(4.dp))
                            StatusChip("Frozen", RexoColors.Error)
                        }
                    }
                    Text(
                        text = "Available: ₹${formatAmount(wallet.available_balance)} | Escrow: ₹${formatAmount(wallet.escrow_balance)}",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                }
                Icon(
                    if (showActions) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore,
                    contentDescription = "Toggle",
                    tint = RexoColors.Gray400
                )
            }

            if (showActions) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    if (wallet.is_frozen) {
                        SmallActionButton("Unfreeze", RexoColors.Success, onUnfreeze)
                    } else {
                        SmallActionButton("Freeze", RexoColors.Error, onFreeze)
                    }
                    SmallActionButton("Credit", RexoColors.Success, onCredit)
                    SmallActionButton("Debit", RexoColors.Warning, onDebit)
                }
            }
        }
    }
}

// ========== MODULE 11: SYSTEM SETTINGS ==========

@Composable
private fun SettingsTab(viewModel: AdminViewModel) {
    val state by viewModel.settingsState.collectAsState()

    var commission by remember(state.settings) { mutableStateOf(state.settings.commission_percentage.toString()) }
    var minWithdrawal by remember(state.settings) { mutableStateOf(state.settings.min_withdrawal_amount.toString()) }
    var maintenanceMode by remember(state.settings) { mutableStateOf(state.settings.maintenance_mode) }
    var autoApprove by remember(state.settings) { mutableStateOf(state.settings.auto_approve_submissions) }
    var banner by remember(state.settings) { mutableStateOf(state.settings.announcement_banner) }

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadSettings() }
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                "Platform Settings",
                style = RexoTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            // Commission
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = Color.White,
                border = BorderStroke(1.dp, RexoColors.CardBorder)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Commission Fee (%)", style = RexoTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = commission,
                        onValueChange = { commission = it },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(8.dp),
                        colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = RexoColors.AccentOrange)
                    )
                }
            }

            // Min Withdrawal
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = Color.White,
                border = BorderStroke(1.dp, RexoColors.CardBorder)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Minimum Withdrawal Amount (INR)", style = RexoTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = minWithdrawal,
                        onValueChange = { minWithdrawal = it },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(8.dp),
                        colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = RexoColors.AccentOrange)
                    )
                }
            }

            // Toggles
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = Color.White,
                border = BorderStroke(1.dp, RexoColors.CardBorder)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Maintenance Mode", style = RexoTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                            Text("Disables user access to the platform", style = RexoTheme.typography.bodySmall, color = RexoColors.TextSecondary)
                        }
                        Switch(
                            checked = maintenanceMode,
                            onCheckedChange = { maintenanceMode = it },
                            colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = RexoColors.AccentOrange)
                        )
                    }

                    HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Auto-Approve Submissions", style = RexoTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                            Text("Automatically approve creator deliverables", style = RexoTheme.typography.bodySmall, color = RexoColors.TextSecondary)
                        }
                        Switch(
                            checked = autoApprove,
                            onCheckedChange = { autoApprove = it },
                            colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = RexoColors.AccentOrange)
                        )
                    }
                }
            }

            // Announcement Banner
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = Color.White,
                border = BorderStroke(1.dp, RexoColors.CardBorder)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Announcement Banner", style = RexoTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    Text("Shown to all users at the top of the app", style = RexoTheme.typography.bodySmall, color = RexoColors.TextSecondary)
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = banner,
                        onValueChange = { banner = it },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(8.dp),
                        minLines = 2,
                        colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = RexoColors.AccentOrange)
                    )
                }
            }

            // Save Button
            Button(
                onClick = {
                    viewModel.saveSettings(
                        AdminSettingsDto(
                            id = "default",
                            commission_percentage = commission.toDoubleOrNull() ?: 10.0,
                            min_withdrawal_amount = minWithdrawal.toDoubleOrNull() ?: 100.0,
                            maintenance_mode = maintenanceMode,
                            auto_approve_submissions = autoApprove,
                            announcement_banner = banner
                        )
                    )
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = RexoColors.AccentOrange),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text("Save Settings", fontWeight = FontWeight.Bold)
            }
        }
    }
}

// ========== MODULE 12: AUDIT LOGS ==========

@Composable
private fun AuditLogsTab(viewModel: AdminViewModel) {
    val state by viewModel.auditState.collectAsState()
    var selectedFilter by remember { mutableStateOf("all") }

    ModuleContainer(
        isLoading = state.isLoading,
        error = state.error,
        onRetry = { viewModel.loadAuditLogs() }
    ) {
        LazyColumn(
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("all", "user", "campaign", "kyc", "wallet", "deposit", "withdrawal").forEach { filter ->
                        FilterChip(
                            selected = selectedFilter == filter,
                            onClick = {
                                selectedFilter = filter
                                viewModel.loadAuditLogs(filter)
                            },
                            label = { Text(filter.replaceFirstChar { it.uppercase() }) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = RexoColors.AccentOrange.copy(alpha = 0.1f),
                                selectedLabelColor = RexoColors.AccentOrange
                            )
                        )
                    }
                }
            }

            item {
                Text(
                    "Audit Logs (${state.logs.size})",
                    style = RexoTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = RexoColors.TextPrimary
                )
            }

            if (state.logs.isEmpty()) {
                item { EmptyState(icon = Icons.Outlined.History, message = "No audit logs found") }
            } else {
                items(state.logs) { log ->
                    AuditLogCard(log)
                }
            }
        }
    }
}

@Composable
private fun AuditLogCard(log: AdminAuditLogDto) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Surface(
                shape = CircleShape,
                color = RexoColors.AccentOrange.copy(alpha = 0.1f),
                modifier = Modifier.size(36.dp)
            ) {
                Icon(
                    Icons.Outlined.History,
                    contentDescription = null,
                    tint = RexoColors.AccentOrange,
                    modifier = Modifier.padding(8.dp)
                )
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = log.action_type.replace("_", " ").replaceFirstChar { it.uppercase() },
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = RexoColors.TextPrimary
                )
                Text(
                    text = "by ${log.admin_name.ifBlank { "Admin" }} | Target: ${log.target_id.takeLast(8)}",
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.TextSecondary
                )
                if (log.reason.isNotBlank()) {
                    Text(
                        text = log.reason,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.Gray500,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                Text(
                    text = formatDate(log.created_at),
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.Gray400
                )
            }
        }
    }
}

// ========== MODULE 13: BROADCAST ==========

@Composable
private fun BroadcastTab(viewModel: AdminViewModel) {
    val state by viewModel.broadcastState.collectAsState()

    var title by remember { mutableStateOf("") }
    var body by remember { mutableStateOf("") }
    var targetAudience by remember { mutableStateOf("all") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            "Push & In-App Broadcast",
            style = RexoTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold,
            color = RexoColors.TextPrimary
        )

        if (state.sent) {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = RexoColors.Success.copy(alpha = 0.1f),
                border = BorderStroke(1.dp, RexoColors.Success.copy(alpha = 0.3f))
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Outlined.CheckCircle, contentDescription = null, tint = RexoColors.Success)
                    Text("Broadcast sent successfully!", color = RexoColors.Success, fontWeight = FontWeight.SemiBold)
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Button(
                onClick = {
                    viewModel.resetBroadcastState()
                    title = ""
                    body = ""
                    targetAudience = "all"
                },
                colors = ButtonDefaults.buttonColors(containerColor = RexoColors.AccentOrange),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text("Send Another")
            }
        } else {
            // Notification Title
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = Color.White,
                border = BorderStroke(1.dp, RexoColors.CardBorder)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Notification Title", style = RexoTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("Enter notification title...") },
                        shape = RoundedCornerShape(8.dp),
                        colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = RexoColors.AccentOrange, cursorColor = RexoColors.AccentOrange),
                        singleLine = true
                    )
                }
            }

            // Notification Body
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = Color.White,
                border = BorderStroke(1.dp, RexoColors.CardBorder)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Notification Body", style = RexoTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = body,
                        onValueChange = { body = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("Enter notification body...") },
                        shape = RoundedCornerShape(8.dp),
                        minLines = 3,
                        colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = RexoColors.AccentOrange, cursorColor = RexoColors.AccentOrange)
                    )
                }
            }

            // Target Audience
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = Color.White,
                border = BorderStroke(1.dp, RexoColors.CardBorder)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Target Audience", style = RexoTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf("all" to "All Users", "creator" to "Creators", "brand" to "Brands").forEach { (value, label) ->
                            FilterChip(
                                selected = targetAudience == value,
                                onClick = { targetAudience = value },
                                label = { Text(label) },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = RexoColors.AccentOrange.copy(alpha = 0.1f),
                                    selectedLabelColor = RexoColors.AccentOrange
                                )
                            )
                        }
                    }
                }
            }

            // Send Button
            Button(
                onClick = { viewModel.sendBroadcast(title, body, targetAudience) },
                modifier = Modifier.fillMaxWidth(),
                enabled = title.isNotBlank() && body.isNotBlank() && !state.isSending,
                colors = ButtonDefaults.buttonColors(
                    containerColor = RexoColors.AccentOrange,
                    disabledContainerColor = RexoColors.Gray300
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                if (state.isSending) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Sending...")
                } else {
                    Icon(Icons.Outlined.Send, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Send Broadcast", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

// ========== SHARED COMPONENTS ==========

@Composable
private fun ModuleContainer(
    isLoading: Boolean,
    error: String?,
    onRetry: () -> Unit,
    content: @Composable () -> Unit
) {
    when {
        isLoading -> {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = RexoColors.AccentOrange)
            }
        }
        error != null -> {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        Icons.Outlined.ErrorOutline,
                        contentDescription = "Error",
                        modifier = Modifier.size(48.dp),
                        tint = RexoColors.Error
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = error,
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(
                        onClick = onRetry,
                        colors = ButtonDefaults.buttonColors(containerColor = RexoColors.AccentOrange),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text("Retry")
                    }
                }
            }
        }
        else -> content()
    }
}

@Composable
private fun EmptyState(icon: ImageVector, message: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            icon,
            contentDescription = null,
            modifier = Modifier.size(48.dp),
            tint = RexoColors.Gray300
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = message,
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary
        )
    }
}

@Composable
private fun StatCard(
    icon: ImageVector,
    label: String,
    value: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Surface(
                shape = CircleShape,
                color = color.copy(alpha = 0.1f),
                modifier = Modifier.size(40.dp)
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = label,
                    tint = color,
                    modifier = Modifier.padding(8.dp)
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = value,
                style = RexoTheme.typography.titleLarge,
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
private fun StatusChip(text: String, color: Color) {
    Surface(
        shape = RoundedCornerShape(6.dp),
        color = color.copy(alpha = 0.1f)
    ) {
        Text(
            text = text.replaceFirstChar { it.uppercase() },
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
            style = RexoTheme.typography.bodySmall,
            color = color,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
private fun SmallActionButton(text: String, color: Color, onClick: () -> Unit) {
    Surface(
        modifier = Modifier.clickable(onClick = onClick),
        shape = RoundedCornerShape(8.dp),
        color = color.copy(alpha = 0.1f),
        border = BorderStroke(1.dp, color.copy(alpha = 0.3f))
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
            style = RexoTheme.typography.bodySmall,
            color = color,
            fontWeight = FontWeight.SemiBold
        )
    }
}

// ========== UTILITY FUNCTIONS ==========

private fun formatAmount(amount: Double): String {
    return if (amount >= 100000) {
        String.format("%.1fL", amount / 100000)
    } else if (amount >= 1000) {
        String.format("%.1fK", amount / 1000)
    } else {
        String.format("%.0f", amount)
    }
}

private fun formatDate(dateStr: String): String {
    if (dateStr.isBlank()) return "N/A"
    return try {
        dateStr.take(10)
    } catch (_: Exception) {
        dateStr
    }
}

private fun getStatusColor(status: String): Color {
    return when (status.lowercase()) {
        "active", "approved", "delivered", "paid" -> RexoColors.Success
        "pending", "applied", "submitted" -> RexoColors.Warning
        "paused", "suspended" -> Color(0xFF6366F1)
        "completed" -> Color(0xFF6366F1)
        "rejected", "cancelled", "banned", "open" -> RexoColors.Error
        "resolved", "dismissed" -> RexoColors.Gray500
        else -> RexoColors.Gray400
    }
}
