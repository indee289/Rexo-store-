package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.repository.*
import com.rexo.marketplace.utils.ErrorUtils
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Admin ViewModel
 * Manages state for all 13 admin modules with proper loading/error/success states.
 * Uses AdminRepository for all Supabase operations.
 */
class AdminViewModel(
    private val repository: AdminRepository = AdminRepository()
) : ViewModel() {

    // Current selected module tab index
    private val _selectedModule = MutableStateFlow(0)
    val selectedModule: StateFlow<Int> = _selectedModule.asStateFlow()

    // Dashboard State
    private val _dashboardState = MutableStateFlow(DashboardModuleState())
    val dashboardState: StateFlow<DashboardModuleState> = _dashboardState.asStateFlow()

    // User Management State
    private val _userState = MutableStateFlow(UserModuleState())
    val userState: StateFlow<UserModuleState> = _userState.asStateFlow()

    // Campaign State
    private val _campaignState = MutableStateFlow(CampaignModuleState())
    val campaignState: StateFlow<CampaignModuleState> = _campaignState.asStateFlow()

    // Submissions State
    private val _submissionState = MutableStateFlow(SubmissionModuleState())
    val submissionState: StateFlow<SubmissionModuleState> = _submissionState.asStateFlow()

    // Deposits State
    private val _depositState = MutableStateFlow(DepositModuleState())
    val depositState: StateFlow<DepositModuleState> = _depositState.asStateFlow()

    // Withdrawals State
    private val _withdrawalState = MutableStateFlow(WithdrawalModuleState())
    val withdrawalState: StateFlow<WithdrawalModuleState> = _withdrawalState.asStateFlow()

    // Shop State
    private val _shopState = MutableStateFlow(ShopModuleState())
    val shopState: StateFlow<ShopModuleState> = _shopState.asStateFlow()

    // Disputes State
    private val _disputeState = MutableStateFlow(DisputeModuleState())
    val disputeState: StateFlow<DisputeModuleState> = _disputeState.asStateFlow()

    // KYC State
    private val _kycState = MutableStateFlow(KycModuleState())
    val kycState: StateFlow<KycModuleState> = _kycState.asStateFlow()

    // Wallets State
    private val _walletState = MutableStateFlow(WalletModuleState())
    val walletState: StateFlow<WalletModuleState> = _walletState.asStateFlow()

    // Settings State
    private val _settingsState = MutableStateFlow(SettingsModuleState())
    val settingsState: StateFlow<SettingsModuleState> = _settingsState.asStateFlow()

    // Audit Logs State
    private val _auditState = MutableStateFlow(AuditModuleState())
    val auditState: StateFlow<AuditModuleState> = _auditState.asStateFlow()

    // Broadcast State
    private val _broadcastState = MutableStateFlow(BroadcastModuleState())
    val broadcastState: StateFlow<BroadcastModuleState> = _broadcastState.asStateFlow()

    // Action feedback
    private val _actionMessage = MutableStateFlow<String?>(null)
    val actionMessage: StateFlow<String?> = _actionMessage.asStateFlow()

    init {
        loadDashboard()
    }

    fun selectModule(index: Int) {
        _selectedModule.value = index
        when (index) {
            0 -> loadDashboard()
            1 -> loadUsers()
            2 -> loadCampaigns()
            3 -> loadSubmissions()
            4 -> loadDeposits()
            5 -> loadWithdrawals()
            6 -> loadShop()
            7 -> loadDisputes()
            8 -> loadKyc()
            9 -> loadWallets()
            10 -> loadSettings()
            11 -> loadAuditLogs()
            12 -> { /* Broadcast - no initial load needed */ }
        }
    }

    fun clearActionMessage() {
        _actionMessage.value = null
    }

    // ========== DASHBOARD ==========

    fun loadDashboard() {
        viewModelScope.launch {
            _dashboardState.update { it.copy(isLoading = true, error = null) }
            try {
                val stats = repository.getDashboardStats()
                _dashboardState.update { it.copy(isLoading = false, stats = stats) }
            } catch (e: Exception) {
                _dashboardState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    // ========== USER MANAGEMENT ==========

    fun loadUsers(search: String = "", role: String = "all", status: String = "all") {
        viewModelScope.launch {
            _userState.update { it.copy(isLoading = true, error = null, searchQuery = search, roleFilter = role, statusFilter = status) }
            try {
                val users = repository.getUsers(search, role, status)
                _userState.update { it.copy(isLoading = false, users = users) }
            } catch (e: Exception) {
                _userState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    fun toggleUserVerification(userId: String, currentlyVerified: Boolean) {
        viewModelScope.launch {
            try {
                repository.updateUserVerification(userId, !currentlyVerified)
                _actionMessage.value = if (!currentlyVerified) "User verified" else "Verification removed"
                loadUsers(_userState.value.searchQuery, _userState.value.roleFilter, _userState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun changeUserRole(userId: String, newRole: String) {
        viewModelScope.launch {
            try {
                repository.updateUserRole(userId, newRole)
                _actionMessage.value = "Role changed to $newRole"
                loadUsers(_userState.value.searchQuery, _userState.value.roleFilter, _userState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun suspendUser(userId: String, reason: String) {
        viewModelScope.launch {
            try {
                repository.suspendUser(userId, reason)
                _actionMessage.value = "User suspended"
                loadUsers(_userState.value.searchQuery, _userState.value.roleFilter, _userState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun unsuspendUser(userId: String) {
        viewModelScope.launch {
            try {
                repository.unsuspendUser(userId)
                _actionMessage.value = "User unsuspended"
                loadUsers(_userState.value.searchQuery, _userState.value.roleFilter, _userState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun banUser(userId: String, reason: String) {
        viewModelScope.launch {
            try {
                repository.banUser(userId, reason)
                _actionMessage.value = "User banned"
                loadUsers(_userState.value.searchQuery, _userState.value.roleFilter, _userState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun unbanUser(userId: String) {
        viewModelScope.launch {
            try {
                repository.unbanUser(userId)
                _actionMessage.value = "User unbanned"
                loadUsers(_userState.value.searchQuery, _userState.value.roleFilter, _userState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun deleteUser(userId: String) {
        viewModelScope.launch {
            try {
                repository.deleteUser(userId)
                _actionMessage.value = "User deleted"
                loadUsers(_userState.value.searchQuery, _userState.value.roleFilter, _userState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    // ========== CAMPAIGN CONTROL ==========

    fun loadCampaigns(statusFilter: String = "all") {
        viewModelScope.launch {
            _campaignState.update { it.copy(isLoading = true, error = null, statusFilter = statusFilter) }
            try {
                val campaigns = repository.getCampaigns(statusFilter)
                _campaignState.update { it.copy(isLoading = false, campaigns = campaigns) }
            } catch (e: Exception) {
                _campaignState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    fun pauseCampaign(campaignId: String) {
        viewModelScope.launch {
            try {
                repository.pauseCampaign(campaignId)
                _actionMessage.value = "Campaign paused"
                loadCampaigns(_campaignState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun resumeCampaign(campaignId: String) {
        viewModelScope.launch {
            try {
                repository.resumeCampaign(campaignId)
                _actionMessage.value = "Campaign resumed"
                loadCampaigns(_campaignState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun forceCompleteCampaign(campaignId: String) {
        viewModelScope.launch {
            try {
                repository.forceCompleteCampaign(campaignId)
                _actionMessage.value = "Campaign force completed"
                loadCampaigns(_campaignState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun forceCancelCampaign(campaignId: String) {
        viewModelScope.launch {
            try {
                repository.forceCancelCampaign(campaignId)
                _actionMessage.value = "Campaign cancelled with refund"
                loadCampaigns(_campaignState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun deleteCampaign(campaignId: String) {
        viewModelScope.launch {
            try {
                repository.deleteCampaign(campaignId)
                _actionMessage.value = "Campaign deleted"
                loadCampaigns(_campaignState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    // ========== SUBMISSIONS ==========

    fun loadSubmissions(statusFilter: String = "all") {
        viewModelScope.launch {
            _submissionState.update { it.copy(isLoading = true, error = null, statusFilter = statusFilter) }
            try {
                val submissions = repository.getSubmissions(statusFilter)
                _submissionState.update { it.copy(isLoading = false, submissions = submissions) }
            } catch (e: Exception) {
                _submissionState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    fun approveSubmission(applicationId: String) {
        viewModelScope.launch {
            try {
                repository.approveSubmission(applicationId)
                _actionMessage.value = "Submission approved"
                loadSubmissions(_submissionState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun rejectSubmission(applicationId: String, reason: String) {
        viewModelScope.launch {
            try {
                repository.rejectSubmission(applicationId, reason)
                _actionMessage.value = "Submission rejected"
                loadSubmissions(_submissionState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun disburseSubmissionPayout(applicationId: String, creatorId: String, amount: Double) {
        viewModelScope.launch {
            try {
                repository.disburseSubmissionPayout(applicationId, creatorId, amount)
                _actionMessage.value = "Payout of ₹$amount disbursed"
                loadSubmissions(_submissionState.value.statusFilter)
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    // ========== DEPOSITS ==========

    fun loadDeposits() {
        viewModelScope.launch {
            _depositState.update { it.copy(isLoading = true, error = null) }
            try {
                val deposits = repository.getPendingDeposits()
                _depositState.update { it.copy(isLoading = false, deposits = deposits) }
            } catch (e: Exception) {
                _depositState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    fun approveDeposit(depositId: String, brandId: String, amount: Double) {
        viewModelScope.launch {
            try {
                repository.approveDeposit(depositId, brandId, amount)
                _actionMessage.value = "Deposit approved and credited"
                loadDeposits()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun rejectDeposit(depositId: String, remarks: String) {
        viewModelScope.launch {
            try {
                repository.rejectDeposit(depositId, remarks)
                _actionMessage.value = "Deposit rejected"
                loadDeposits()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    // ========== WITHDRAWALS ==========

    fun loadWithdrawals() {
        viewModelScope.launch {
            _withdrawalState.update { it.copy(isLoading = true, error = null) }
            try {
                val withdrawals = repository.getPendingWithdrawals()
                _withdrawalState.update { it.copy(isLoading = false, withdrawals = withdrawals) }
            } catch (e: Exception) {
                _withdrawalState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    fun approveWithdrawal(withdrawalId: String, bankReference: String) {
        viewModelScope.launch {
            try {
                repository.approveWithdrawal(withdrawalId, bankReference)
                _actionMessage.value = "Withdrawal approved"
                loadWithdrawals()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun rejectWithdrawal(withdrawalId: String, reason: String) {
        viewModelScope.launch {
            try {
                repository.rejectWithdrawal(withdrawalId, reason)
                _actionMessage.value = "Withdrawal rejected"
                loadWithdrawals()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    // ========== SHOP ==========

    fun loadShop() {
        viewModelScope.launch {
            _shopState.update { it.copy(isLoading = true, error = null) }
            try {
                val products = repository.getProducts()
                val orders = repository.getOrders()
                _shopState.update { it.copy(isLoading = false, products = products, orders = orders) }
            } catch (e: Exception) {
                _shopState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    fun addProduct(name: String, description: String, price: Double, stock: Int) {
        viewModelScope.launch {
            try {
                val product = AdminProductInsertDto(
                    id = "PROD-${System.currentTimeMillis()}",
                    name = name,
                    description = description,
                    price = price,
                    stock = stock,
                    status = "active"
                )
                repository.addProduct(product)
                _actionMessage.value = "Product added"
                loadShop()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun deleteProduct(productId: String) {
        viewModelScope.launch {
            try {
                repository.deleteProduct(productId)
                _actionMessage.value = "Product deleted"
                loadShop()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun updateOrderStatus(orderId: String, newStatus: String) {
        viewModelScope.launch {
            try {
                repository.updateOrderStatus(orderId, newStatus)
                _actionMessage.value = "Order status updated to $newStatus"
                loadShop()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    // ========== DISPUTES ==========

    fun loadDisputes() {
        viewModelScope.launch {
            _disputeState.update { it.copy(isLoading = true, error = null) }
            try {
                val disputes = repository.getDisputes()
                _disputeState.update { it.copy(isLoading = false, disputes = disputes) }
            } catch (e: Exception) {
                _disputeState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    fun resolveDispute(disputeId: String, resolution: String, action: String) {
        viewModelScope.launch {
            try {
                repository.resolveDispute(disputeId, resolution, action)
                _actionMessage.value = "Dispute resolved"
                loadDisputes()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun dismissDispute(disputeId: String, reason: String) {
        viewModelScope.launch {
            try {
                repository.dismissDispute(disputeId, reason)
                _actionMessage.value = "Dispute dismissed"
                loadDisputes()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    // ========== KYC ==========

    fun loadKyc() {
        viewModelScope.launch {
            _kycState.update { it.copy(isLoading = true, error = null) }
            try {
                val kycDocs = repository.getPendingKyc()
                _kycState.update { it.copy(isLoading = false, documents = kycDocs) }
            } catch (e: Exception) {
                _kycState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    fun approveKyc(kycId: String, userId: String) {
        viewModelScope.launch {
            try {
                repository.approveKyc(kycId, userId)
                _actionMessage.value = "KYC approved and badge granted"
                loadKyc()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun rejectKyc(kycId: String, reason: String) {
        viewModelScope.launch {
            try {
                repository.rejectKyc(kycId, reason)
                _actionMessage.value = "KYC rejected"
                loadKyc()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    // ========== WALLETS ==========

    fun loadWallets() {
        viewModelScope.launch {
            _walletState.update { it.copy(isLoading = true, error = null) }
            try {
                val wallets = repository.getAllWallets()
                _walletState.update { it.copy(isLoading = false, wallets = wallets) }
            } catch (e: Exception) {
                _walletState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    fun freezeWallet(userId: String) {
        viewModelScope.launch {
            try {
                repository.freezeWallet(userId)
                _actionMessage.value = "Wallet frozen"
                loadWallets()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun unfreezeWallet(userId: String) {
        viewModelScope.launch {
            try {
                repository.unfreezeWallet(userId)
                _actionMessage.value = "Wallet unfrozen"
                loadWallets()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun manualCreditWallet(userId: String, amount: Double, reason: String) {
        viewModelScope.launch {
            try {
                repository.manualCreditWallet(userId, amount, reason)
                _actionMessage.value = "Credited wallet with amount $amount"
                loadWallets()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    fun manualDebitWallet(userId: String, amount: Double, reason: String) {
        viewModelScope.launch {
            try {
                repository.manualDebitWallet(userId, amount, reason)
                _actionMessage.value = "Debited wallet with amount $amount"
                loadWallets()
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    // ========== SETTINGS ==========

    fun loadSettings() {
        viewModelScope.launch {
            _settingsState.update { it.copy(isLoading = true, error = null) }
            try {
                val settings = repository.getSettings()
                _settingsState.update { it.copy(isLoading = false, settings = settings) }
            } catch (e: Exception) {
                _settingsState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    fun saveSettings(settings: AdminSettingsDto) {
        viewModelScope.launch {
            try {
                repository.updateSettings(settings)
                _actionMessage.value = "Settings saved"
                _settingsState.update { it.copy(settings = settings) }
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
            }
        }
    }

    // ========== AUDIT LOGS ==========

    fun loadAuditLogs(actionFilter: String = "all") {
        viewModelScope.launch {
            _auditState.update { it.copy(isLoading = true, error = null, actionFilter = actionFilter) }
            try {
                val logs = repository.getAuditLogs(actionFilter)
                _auditState.update { it.copy(isLoading = false, logs = logs) }
            } catch (e: Exception) {
                _auditState.update { it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message)) }
            }
        }
    }

    // ========== BROADCAST ==========

    fun sendBroadcast(title: String, body: String, targetAudience: String) {
        viewModelScope.launch {
            _broadcastState.update { it.copy(isSending = true) }
            try {
                repository.sendBroadcast(title, body, targetAudience)
                _actionMessage.value = "Broadcast sent to $targetAudience"
                _broadcastState.update { it.copy(isSending = false, sent = true) }
            } catch (e: Exception) {
                _actionMessage.value = "Failed: ${ErrorUtils.sanitizeErrorMessage(e.message)}"
                _broadcastState.update { it.copy(isSending = false) }
            }
        }
    }

    fun resetBroadcastState() {
        _broadcastState.update { BroadcastModuleState() }
    }
}

// ========== MODULE STATES ==========

data class DashboardModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val stats: AdminDashboardStats = AdminDashboardStats()
)

data class UserModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val users: List<AdminUserDto> = emptyList(),
    val searchQuery: String = "",
    val roleFilter: String = "all",
    val statusFilter: String = "all"
)

data class CampaignModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val campaigns: List<AdminCampaignListDto> = emptyList(),
    val statusFilter: String = "all"
)

data class SubmissionModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val submissions: List<AdminSubmissionDto> = emptyList(),
    val statusFilter: String = "all"
)

data class DepositModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val deposits: List<AdminDepositDto> = emptyList()
)

data class WithdrawalModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val withdrawals: List<AdminWithdrawalDto> = emptyList()
)

data class ShopModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val products: List<AdminProductDto> = emptyList(),
    val orders: List<AdminOrderDto> = emptyList()
)

data class DisputeModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val disputes: List<AdminDisputeDto> = emptyList()
)

data class KycModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val documents: List<AdminKycDto> = emptyList()
)

data class WalletModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val wallets: List<AdminWalletDto> = emptyList()
)

data class SettingsModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val settings: AdminSettingsDto = AdminSettingsDto()
)

data class AuditModuleState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val logs: List<AdminAuditLogDto> = emptyList(),
    val actionFilter: String = "all"
)

data class BroadcastModuleState(
    val isSending: Boolean = false,
    val sent: Boolean = false
)
