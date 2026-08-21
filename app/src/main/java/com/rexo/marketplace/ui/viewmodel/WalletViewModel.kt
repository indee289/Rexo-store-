package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.repository.TransactionDto
import com.rexo.marketplace.data.repository.WalletFullDto
import com.rexo.marketplace.data.repository.WalletRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Wallet ViewModel
 * Loads wallet balance, transactions from Supabase.
 * Handles deposit and withdrawal operations.
 */
class WalletViewModel : ViewModel() {

    private val repository = WalletRepository()

    private val _uiState = MutableStateFlow(WalletUiState())
    val uiState: StateFlow<WalletUiState> = _uiState.asStateFlow()

    init {
        loadWalletData()
    }

    /**
     * Load wallet and transactions from Supabase.
     * Shows zero-balance wallet if none exists (never shows error for missing wallet).
     */
    fun loadWalletData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val wallet = repository.getWallet()
                val transactions = try {
                    repository.getTransactions()
                } catch (e: Exception) {
                    emptyList()
                }

                if (wallet == null) {
                    // User not authenticated - show friendly error
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = "Please sign in to view your wallet"
                        )
                    }
                } else {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            wallet = wallet,
                            transactions = transactions,
                            error = null
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = "Could not load wallet. Please try again."
                    )
                }
            }
        }
    }

    /**
     * Deposit money - creates a real entry in Supabase 'deposits' table.
     */
    fun depositMoney(amount: Double, paymentMethod: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true, error = null) }
            try {
                repository.deposit(amount, paymentMethod)
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        successMessage = "Deposit request of ₹${String.format("%,.2f", amount)} submitted!"
                    )
                }
                loadWalletData()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        error = e.message ?: "Deposit failed"
                    )
                }
            }
        }
    }

    /**
     * Withdraw money - creates a real entry in Supabase 'withdrawals' table.
     */
    fun withdrawMoney(amount: Double, payoutMethod: String, payoutDetails: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true, error = null) }
            try {
                repository.withdraw(amount, payoutMethod, payoutDetails)
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        successMessage = "Withdrawal request submitted!"
                    )
                }
                loadWalletData()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        error = e.message ?: "Withdrawal failed"
                    )
                }
            }
        }
    }

    fun clearSuccess() {
        _uiState.update { it.copy(successMessage = null) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

/**
 * Wallet UI State
 */
data class WalletUiState(
    val isLoading: Boolean = false,
    val isProcessing: Boolean = false,
    val wallet: WalletFullDto? = null,
    val transactions: List<TransactionDto> = emptyList(),
    val error: String? = null,
    val successMessage: String? = null
)
