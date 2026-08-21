package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.model.Wallet
import com.rexo.marketplace.data.repository.WalletRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.Date

/**
 * Wallet ViewModel
 * Manages wallet state, transactions, analytics, escrow
 */
class WalletViewModel(
    private val repository: WalletRepository
) : ViewModel() {

    // UI State
    private val _uiState = MutableStateFlow(WalletUiState())
    val uiState: StateFlow<WalletUiState> = _uiState.asStateFlow()

    // Balance
    private val _balance = MutableStateFlow(0.0)
    val balance: StateFlow<Double> = _balance.asStateFlow()

    // Transactions
    private val _transactions = MutableStateFlow<List<Transaction>>(emptyList())
    val transactions: StateFlow<List<Transaction>> = _transactions.asStateFlow()

    // Analytics
    private val _analytics = MutableStateFlow<WalletAnalytics?>(null)
    val analytics: StateFlow<WalletAnalytics?> = _analytics.asStateFlow()

    // Escrow
    private val _escrowItems = MutableStateFlow<List<EscrowItem>>(emptyList())
    val escrowItems: StateFlow<List<EscrowItem>> = _escrowItems.asStateFlow()

    init {
        loadWalletData()
    }

    fun loadWalletData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                // Load balance
                val wallet = repository.getWallet()
                _balance.value = wallet?.availableBalance ?: 0.0

                // Load transactions
                _transactions.value = repository.getTransactions()

                // Load analytics
                _analytics.value = repository.getAnalytics()

                // Load escrow items
                _escrowItems.value = repository.getEscrowItems()

                _uiState.update { it.copy(isLoading = false, error = null) }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(isLoading = false, error = e.message ?: "Unknown error") 
                }
            }
        }
    }

    fun depositMoney(amount: Double, method: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true) }
            try {
                repository.deposit(amount, method)
                loadWalletData()
                _uiState.update { 
                    it.copy(
                        isProcessing = false, 
                        showSuccess = true,
                        successMessage = "₹${String.format("%,.2f", amount)} deposited successfully!"
                    ) 
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(isProcessing = false, error = e.message ?: "Deposit failed") 
                }
            }
        }
    }

    fun withdrawMoney(amount: Double, method: String, accountDetails: Map<String, String>) {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true) }
            try {
                repository.withdraw(amount, method, accountDetails)
                loadWalletData()
                _uiState.update { 
                    it.copy(
                        isProcessing = false, 
                        showSuccess = true,
                        successMessage = "Withdrawal request submitted!"
                    ) 
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(isProcessing = false, error = e.message ?: "Withdrawal failed") 
                }
            }
        }
    }

    fun releaseEscrow(escrowId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true) }
            try {
                repository.releaseEscrow(escrowId)
                loadWalletData()
                _uiState.update { 
                    it.copy(
                        isProcessing = false, 
                        showSuccess = true,
                        successMessage = "Escrow released successfully!"
                    ) 
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(isProcessing = false, error = e.message ?: "Release failed") 
                }
            }
        }
    }

    fun raiseDispute(escrowId: String, reason: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true) }
            try {
                repository.raiseDispute(escrowId, reason)
                loadWalletData()
                _uiState.update { 
                    it.copy(
                        isProcessing = false, 
                        showSuccess = true,
                        successMessage = "Dispute raised. Admin will review."
                    ) 
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(isProcessing = false, error = e.message ?: "Failed to raise dispute") 
                }
            }
        }
    }

    fun clearSuccess() {
        _uiState.update { it.copy(showSuccess = false, successMessage = null) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class WalletUiState(
    val isLoading: Boolean = false,
    val isProcessing: Boolean = false,
    val error: String? = null,
    val showSuccess: Boolean = false,
    val successMessage: String? = null
)

data class Transaction(
    val id: String,
    val type: String,
    val amount: Double,
    val status: String,
    val date: Date,
    val description: String
)

data class WalletAnalytics(
    val totalIncome: Double,
    val totalExpense: Double,
    val categoryBreakdown: Map<String, Double>,
    val monthlyTrends: List<MonthlyData>
)

data class MonthlyData(
    val month: String,
    val income: Double,
    val expense: Double
)

data class EscrowItem(
    val id: String,
    val campaignName: String,
    val amount: Double,
    val status: String,
    val dueDate: Date,
    val canRelease: Boolean
)
