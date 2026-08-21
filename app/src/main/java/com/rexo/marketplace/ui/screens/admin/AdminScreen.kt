package com.rexo.marketplace.ui.screens.admin

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rexo.marketplace.data.remote.SupabaseClient
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
 * Admin Center Screen - Premium clean white design
 * Fetches real data from Supabase for KYC, withdrawals, deposits, and users.
 * No glassmorphism, no dummy data.
 */

// --- Admin DTOs ---

@Serializable
data class AdminKycDto(
    val id: String = "",
    val user_id: String = "",
    val user_name: String = "",
    val document_type: String = "",
    val status: String = "pending",
    val submitted_at: String = ""
)

@Serializable
data class AdminWithdrawalDto(
    val id: String = "",
    val user_id: String = "",
    val user_name: String = "",
    val amount: Double = 0.0,
    val payout_method: String = "",
    val status: String = "pending",
    val created_at: String = ""
)

@Serializable
data class AdminDepositDto(
    val id: String = "",
    val brand_id: String = "",
    val brand_name: String = "",
    val amount: Double = 0.0,
    val payment_method: String = "",
    val status: String = "pending",
    val created_at: String = ""
)

@Serializable
data class AdminUserDto(
    val id: String = "",
    val email: String = "",
    val name: String = "",
    val role: String = "creator",
    val is_verified: Boolean = false,
    val is_banned: Boolean = false,
    val created_at: String = ""
)

@Serializable
data class AdminCampaignCountDto(
    val id: String = ""
)

// --- Admin ViewModel ---

data class AdminUiState(
    val isLoading: Boolean = true,
    val error: String? = null,
    val totalUsers: Int = 0,
    val totalCampaigns: Int = 0,
    val pendingKyc: List<AdminKycDto> = emptyList(),
    val pendingWithdrawals: List<AdminWithdrawalDto> = emptyList(),
    val pendingDeposits: List<AdminDepositDto> = emptyList(),
    val recentUsers: List<AdminUserDto> = emptyList()
)

class AdminViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(AdminUiState())
    val uiState: StateFlow<AdminUiState> = _uiState.asStateFlow()

    init {
        loadAdminData()
    }

    fun loadAdminData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                withContext(Dispatchers.IO) {
                    // Fetch pending KYC documents
                    val kyc = try {
                        SupabaseClient.client.from("kyc_documents").select {
                            filter { eq("status", "pending") }
                        }.decodeList<AdminKycDto>()
                    } catch (e: Exception) { emptyList() }

                    // Fetch pending withdrawals
                    val withdrawals = try {
                        SupabaseClient.client.from("withdrawals").select {
                            filter { eq("status", "pending") }
                        }.decodeList<AdminWithdrawalDto>()
                    } catch (e: Exception) { emptyList() }

                    // Fetch pending deposits
                    val deposits = try {
                        SupabaseClient.client.from("deposits").select {
                            filter { eq("status", "pending") }
                        }.decodeList<AdminDepositDto>()
                    } catch (e: Exception) { emptyList() }

                    // Fetch recent users
                    val users = try {
                        SupabaseClient.client.from("users").select()
                            .decodeList<AdminUserDto>()
                    } catch (e: Exception) { emptyList() }

                    // Fetch campaign count
                    val campaigns = try {
                        SupabaseClient.client.from("campaigns").select()
                            .decodeList<AdminCampaignCountDto>()
                    } catch (e: Exception) { emptyList() }

                    _uiState.value = AdminUiState(
                        isLoading = false,
                        totalUsers = users.size,
                        totalCampaigns = campaigns.size,
                        pendingKyc = kyc,
                        pendingWithdrawals = withdrawals,
                        pendingDeposits = deposits,
                        recentUsers = users.take(20)
                    )
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "Failed to load admin data"
                )
            }
        }
    }

    fun approveKyc(kycId: String) {
        viewModelScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    SupabaseClient.client.from("kyc_documents").update({
                        set("status", "approved")
                    }) {
                        filter { eq("id", kycId) }
                    }
                }
                loadAdminData()
            } catch (e: Exception) { /* ignore */ }
        }
    }

    fun rejectKyc(kycId: String) {
        viewModelScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    SupabaseClient.client.from("kyc_documents").update({
                        set("status", "rejected")
                    }) {
                        filter { eq("id", kycId) }
                    }
                }
                loadAdminData()
            } catch (e: Exception) { /* ignore */ }
        }
    }

    fun approveWithdrawal(withdrawalId: String) {
        viewModelScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    SupabaseClient.client.from("withdrawals").update({
                        set("status", "approved")
                    }) {
                        filter { eq("id", withdrawalId) }
                    }
                }
                loadAdminData()
            } catch (e: Exception) { /* ignore */ }
        }
    }

    fun rejectWithdrawal(withdrawalId: String) {
        viewModelScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    SupabaseClient.client.from("withdrawals").update({
                        set("status", "rejected")
                    }) {
                        filter { eq("id", withdrawalId) }
                    }
                }
                loadAdminData()
            } catch (e: Exception) { /* ignore */ }
        }
    }

    fun approveDeposit(depositId: String) {
        viewModelScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    SupabaseClient.client.from("deposits").update({
                        set("status", "approved")
                    }) {
                        filter { eq("id", depositId) }
                    }
                }
                loadAdminData()
            } catch (e: Exception) { /* ignore */ }
        }
    }

    fun rejectDeposit(depositId: String) {
        viewModelScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    SupabaseClient.client.from("deposits").update({
                        set("status", "rejected")
                    }) {
                        filter { eq("id", depositId) }
                    }
                }
                loadAdminData()
            } catch (e: Exception) { /* ignore */ }
        }
    }
}

// --- Admin Screen ---

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminScreen(
    onNavigateBack: () -> Unit = {}
) {
    val adminViewModel: AdminViewModel = viewModel()
    val uiState by adminViewModel.uiState.collectAsState()

    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("Overview", "KYC", "Transactions", "Users")

    Scaffold(
        containerColor = Color.White,
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
                    IconButton(onClick = { adminViewModel.loadAdminData() }) {
                        Icon(
                            Icons.Outlined.Refresh,
                            contentDescription = "Refresh",
                            tint = RexoColors.AccentOrange
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Tab Row
            ScrollableTabRow(
                selectedTabIndex = selectedTab,
                containerColor = Color.White,
                contentColor = RexoColors.AccentOrange,
                edgePadding = 20.dp,
                indicator = { tabPositions ->
                    if (selectedTab < tabPositions.size) {
                        TabRowDefaults.SecondaryIndicator(
                            modifier = Modifier.tabIndicatorOffset(tabPositions[selectedTab]),
                            color = RexoColors.AccentOrange
                        )
                    }
                }
            ) {
                tabs.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        text = {
                            Text(
                                text = title,
                                fontWeight = if (selectedTab == index) FontWeight.Bold else FontWeight.Normal,
                                color = if (selectedTab == index) RexoColors.AccentOrange else RexoColors.TextSecondary
                            )
                        }
                    )
                }
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
                                Icons.Outlined.ErrorOutline,
                                contentDescription = "Error",
                                modifier = Modifier.size(48.dp),
                                tint = RexoColors.Error
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            Text(
                                text = uiState.error ?: "",
                                style = RexoTheme.typography.bodyMedium,
                                color = RexoColors.TextSecondary
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Button(
                                onClick = { adminViewModel.loadAdminData() },
                                colors = ButtonDefaults.buttonColors(containerColor = RexoColors.AccentOrange),
                                shape = RoundedCornerShape(12.dp)
                            ) {
                                Text("Retry")
                            }
                        }
                    }
                }

                else -> {
                    when (selectedTab) {
                        0 -> OverviewTab(uiState)
                        1 -> KycTab(uiState, adminViewModel)
                        2 -> TransactionsTab(uiState, adminViewModel)
                        3 -> UsersTab(uiState)
                    }
                }
            }
        }
    }
}

@Composable
private fun OverviewTab(state: AdminUiState) {
    LazyColumn(
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Stats Grid
        item {
            Text(
                text = "System Statistics",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )
        }

        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                AdminStatCard(
                    icon = Icons.Outlined.People,
                    label = "Total Users",
                    value = state.totalUsers.toString(),
                    color = Color(0xFF6366F1),
                    modifier = Modifier.weight(1f)
                )
                AdminStatCard(
                    icon = Icons.Outlined.Campaign,
                    label = "Campaigns",
                    value = state.totalCampaigns.toString(),
                    color = RexoColors.Warning,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                AdminStatCard(
                    icon = Icons.Outlined.Pending,
                    label = "Pending KYC",
                    value = state.pendingKyc.size.toString(),
                    color = RexoColors.Error,
                    modifier = Modifier.weight(1f)
                )
                AdminStatCard(
                    icon = Icons.Outlined.Payments,
                    label = "Withdrawals",
                    value = state.pendingWithdrawals.size.toString(),
                    color = RexoColors.Success,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        // Quick Actions
        item {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Quick Actions",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )
        }

        item {
            AdminActionItem(
                icon = Icons.Outlined.Group,
                title = "Manage Users",
                subtitle = "${state.totalUsers} total users"
            )
        }

        item {
            AdminActionItem(
                icon = Icons.Outlined.Campaign,
                title = "Moderate Campaigns",
                subtitle = "${state.totalCampaigns} active campaigns"
            )
        }

        item {
            AdminActionItem(
                icon = Icons.Outlined.BarChart,
                title = "View Analytics",
                subtitle = "Platform performance metrics"
            )
        }

        item {
            AdminActionItem(
                icon = Icons.Outlined.Report,
                title = "View Reports",
                subtitle = "User reports and flags"
            )
        }
    }
}

@Composable
private fun KycTab(state: AdminUiState, viewModel: AdminViewModel) {
    LazyColumn(
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text(
                text = "Pending KYC Approvals (${state.pendingKyc.size})",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )
        }

        if (state.pendingKyc.isEmpty()) {
            item {
                EmptyAdminState(
                    icon = Icons.Outlined.VerifiedUser,
                    message = "No pending KYC requests"
                )
            }
        } else {
            items(state.pendingKyc) { kyc ->
                KycApprovalCard(
                    userName = kyc.user_name.ifBlank { "User" },
                    documentType = kyc.document_type,
                    submittedDate = formatAdminDate(kyc.submitted_at),
                    onApprove = { viewModel.approveKyc(kyc.id) },
                    onReject = { viewModel.rejectKyc(kyc.id) }
                )
            }
        }
    }
}

@Composable
private fun TransactionsTab(state: AdminUiState, viewModel: AdminViewModel) {
    LazyColumn(
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Pending Withdrawals
        item {
            Text(
                text = "Pending Withdrawals (${state.pendingWithdrawals.size})",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )
        }

        if (state.pendingWithdrawals.isEmpty()) {
            item {
                EmptyAdminState(
                    icon = Icons.Outlined.AccountBalanceWallet,
                    message = "No pending withdrawals"
                )
            }
        } else {
            items(state.pendingWithdrawals) { withdrawal ->
                WithdrawalRequestCard(
                    userName = withdrawal.user_name.ifBlank { "User" },
                    amount = withdrawal.amount,
                    method = withdrawal.payout_method,
                    requestDate = formatAdminDate(withdrawal.created_at),
                    onApprove = { viewModel.approveWithdrawal(withdrawal.id) },
                    onReject = { viewModel.rejectWithdrawal(withdrawal.id) }
                )
            }
        }

        // Pending Deposits
        item {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Pending Deposits (${state.pendingDeposits.size})",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )
        }

        if (state.pendingDeposits.isEmpty()) {
            item {
                EmptyAdminState(
                    icon = Icons.Outlined.Payments,
                    message = "No pending deposits"
                )
            }
        } else {
            items(state.pendingDeposits) { deposit ->
                DepositCard(
                    brandName = deposit.brand_name.ifBlank { "Brand" },
                    amount = deposit.amount,
                    method = deposit.payment_method,
                    requestDate = formatAdminDate(deposit.created_at),
                    onApprove = { viewModel.approveDeposit(deposit.id) },
                    onReject = { viewModel.rejectDeposit(deposit.id) }
                )
            }
        }
    }
}

@Composable
private fun UsersTab(state: AdminUiState) {
    LazyColumn(
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            Text(
                text = "Users (${state.recentUsers.size})",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )
        }

        if (state.recentUsers.isEmpty()) {
            item {
                EmptyAdminState(
                    icon = Icons.Outlined.People,
                    message = "No users found"
                )
            }
        } else {
            items(state.recentUsers) { user ->
                UserCard(user = user)
            }
        }
    }
}

// --- Composable Components ---

@Composable
private fun AdminStatCard(
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
        shadowElevation = 1.dp,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Surface(
                shape = CircleShape,
                color = color.copy(alpha = 0.1f),
                modifier = Modifier.size(44.dp)
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = label,
                    tint = color,
                    modifier = Modifier.padding(10.dp)
                )
            }
            Spacer(modifier = Modifier.height(12.dp))
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
private fun AdminActionItem(
    icon: ImageVector,
    title: String,
    subtitle: String
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { /* Action */ },
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = CircleShape,
                    color = RexoColors.AccentOrange.copy(alpha = 0.1f),
                    modifier = Modifier.size(40.dp)
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = title,
                        tint = RexoColors.AccentOrange,
                        modifier = Modifier.padding(8.dp)
                    )
                }
                Column {
                    Text(
                        text = title,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = RexoColors.TextPrimary
                    )
                    Text(
                        text = subtitle,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                }
            }

            Icon(
                imageVector = Icons.Outlined.ChevronRight,
                contentDescription = "Go",
                tint = RexoColors.Gray400,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun KycApprovalCard(
    userName: String,
    documentType: String,
    submittedDate: String,
    onApprove: () -> Unit,
    onReject: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
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
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = userName,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
                    Text(
                        text = documentType.ifBlank { "Identity Document" },
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                    Text(
                        text = "Submitted $submittedDate",
                        style = RexoTheme.typography.labelSmall,
                        color = RexoColors.Gray400
                    )
                }

                Surface(
                    shape = CircleShape,
                    color = RexoColors.Gray100,
                    modifier = Modifier.size(44.dp)
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Person,
                        contentDescription = userName,
                        modifier = Modifier.padding(10.dp),
                        tint = RexoColors.TextSecondary
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(
                    onClick = onReject,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = RexoColors.Error
                    ),
                    border = BorderStroke(1.dp, RexoColors.Error.copy(alpha = 0.5f))
                ) {
                    Icon(Icons.Outlined.Close, contentDescription = "Reject", modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Reject")
                }

                Button(
                    onClick = onApprove,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = RexoColors.Success
                    )
                ) {
                    Icon(Icons.Outlined.Check, contentDescription = "Approve", modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Approve")
                }
            }
        }
    }
}

@Composable
private fun WithdrawalRequestCard(
    userName: String,
    amount: Double,
    method: String,
    requestDate: String,
    onApprove: () -> Unit,
    onReject: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
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
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = userName,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
                    Text(
                        text = "\u20B9${String.format("%,.2f", amount)}",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.Success
                    )
                    Text(
                        text = "$method | $requestDate",
                        style = RexoTheme.typography.labelSmall,
                        color = RexoColors.Gray400
                    )
                }

                Surface(
                    shape = CircleShape,
                    color = RexoColors.Success.copy(alpha = 0.1f),
                    modifier = Modifier.size(44.dp)
                ) {
                    Icon(
                        imageVector = Icons.Outlined.AccountBalanceWallet,
                        contentDescription = "Withdrawal",
                        modifier = Modifier.padding(10.dp),
                        tint = RexoColors.Success
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(
                    onClick = onReject,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = RexoColors.Error
                    ),
                    border = BorderStroke(1.dp, RexoColors.Error.copy(alpha = 0.5f))
                ) {
                    Text("Reject")
                }

                Button(
                    onClick = onApprove,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = RexoColors.AccentOrange
                    )
                ) {
                    Text("Process")
                }
            }
        }
    }
}

@Composable
private fun DepositCard(
    brandName: String,
    amount: Double,
    method: String,
    requestDate: String,
    onApprove: () -> Unit,
    onReject: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
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
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = brandName,
                        style = RexoTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
                    Text(
                        text = "\u20B9${String.format("%,.2f", amount)}",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF6366F1)
                    )
                    Text(
                        text = "$method | $requestDate",
                        style = RexoTheme.typography.labelSmall,
                        color = RexoColors.Gray400
                    )
                }

                Surface(
                    shape = CircleShape,
                    color = Color(0xFF6366F1).copy(alpha = 0.1f),
                    modifier = Modifier.size(44.dp)
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Payments,
                        contentDescription = "Deposit",
                        modifier = Modifier.padding(10.dp),
                        tint = Color(0xFF6366F1)
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(
                    onClick = onReject,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = RexoColors.Error
                    ),
                    border = BorderStroke(1.dp, RexoColors.Error.copy(alpha = 0.5f))
                ) {
                    Text("Reject")
                }

                Button(
                    onClick = onApprove,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = RexoColors.Success
                    )
                ) {
                    Text("Approve")
                }
            }
        }
    }
}

@Composable
private fun UserCard(user: AdminUserDto) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar
            Surface(
                shape = CircleShape,
                color = RexoColors.Gray100,
                modifier = Modifier.size(40.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = user.name.firstOrNull()?.uppercase() ?: "?",
                        style = RexoTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = user.name.ifBlank { "Unknown" },
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = RexoColors.TextPrimary
                )
                Text(
                    text = user.email,
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.TextSecondary
                )
            }

            // Role badge
            Surface(
                shape = RoundedCornerShape(6.dp),
                color = when (user.role) {
                    "admin" -> RexoColors.AccentOrange.copy(alpha = 0.1f)
                    "brand" -> Color(0xFF6366F1).copy(alpha = 0.1f)
                    else -> RexoColors.Gray100
                }
            ) {
                Text(
                    text = user.role.replaceFirstChar { it.uppercase() },
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                    style = RexoTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = when (user.role) {
                        "admin" -> RexoColors.AccentOrange
                        "brand" -> Color(0xFF6366F1)
                        else -> RexoColors.TextSecondary
                    }
                )
            }
        }
    }
}

@Composable
private fun EmptyAdminState(
    icon: ImageVector,
    message: String
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = icon,
            contentDescription = message,
            modifier = Modifier.size(48.dp),
            tint = RexoColors.Gray300
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = message,
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary,
            textAlign = TextAlign.Center
        )
    }
}

/**
 * Format a Supabase timestamp to a user-friendly date.
 */
private fun formatAdminDate(timestamp: String): String {
    if (timestamp.isBlank()) return "Recently"
    return try {
        val dateStr = timestamp.take(10)
        val parts = dateStr.split("-")
        if (parts.size == 3) {
            val month = when (parts[1]) {
                "01" -> "Jan"; "02" -> "Feb"; "03" -> "Mar"; "04" -> "Apr"
                "05" -> "May"; "06" -> "Jun"; "07" -> "Jul"; "08" -> "Aug"
                "09" -> "Sep"; "10" -> "Oct"; "11" -> "Nov"; "12" -> "Dec"
                else -> parts[1]
            }
            "$month ${parts[2]}"
        } else {
            dateStr
        }
    } catch (e: Exception) {
        "Recently"
    }
}
