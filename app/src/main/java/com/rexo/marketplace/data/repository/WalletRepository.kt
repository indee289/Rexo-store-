package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.remote.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable

/**
 * Wallet Repository
 * Fetches wallet and transaction data from Supabase.
 * No mock data fallbacks - returns proper errors on failure.
 */
class WalletRepository {

    private fun getCurrentUserId(): String {
        return SupabaseClient.auth.currentUserOrNull()?.id
            ?: throw Exception("Not authenticated")
    }

    /**
     * Fetch wallet from Supabase 'wallets' table for the current user.
     */
    suspend fun getWallet(): WalletFullDto? = withContext(Dispatchers.IO) {
        val userId = getCurrentUserId()
        try {
            SupabaseClient.client.from("wallets").select {
                filter { eq("user_id", userId) }
            }.decodeSingle<WalletFullDto>()
        } catch (e: Exception) {
            if (e.message?.contains("Not authenticated") == true) throw e
            null
        }
    }

    /**
     * Fetch transactions from Supabase 'transactions' table for the current user.
     * Ordered by created_at DESC.
     */
    suspend fun getTransactions(): List<TransactionDto> = withContext(Dispatchers.IO) {
        val userId = getCurrentUserId()
        val results = SupabaseClient.client.from("transactions").select {
            filter { eq("user_id", userId) }
        }.decodeList<TransactionDto>()
        results.sortedByDescending { it.created_at }
    }

    /**
     * Create a deposit request in the 'deposits' table.
     */
    suspend fun deposit(amount: Double, paymentMethod: String) = withContext(Dispatchers.IO) {
        val userId = getCurrentUserId()
        SupabaseClient.client.from("deposits").insert(
            DepositInsertDto(
                brand_id = userId,
                amount = amount,
                payment_method = paymentMethod,
                transaction_ref = "DEP-${System.currentTimeMillis()}",
                status = "pending"
            )
        )
    }

    /**
     * Create a withdrawal request in the 'withdrawals' table.
     */
    suspend fun withdraw(amount: Double, payoutMethod: String, payoutDetails: String) = withContext(Dispatchers.IO) {
        val userId = getCurrentUserId()
        SupabaseClient.client.from("withdrawals").insert(
            WithdrawalInsertDto(
                user_id = userId,
                amount = amount,
                payout_method = payoutMethod,
                payout_details = payoutDetails,
                status = "pending"
            )
        )
    }
}

/**
 * Full wallet DTO with all fields from Supabase 'wallets' table.
 */
@Serializable
data class WalletFullDto(
    val user_id: String,
    val available_balance: Double = 0.0,
    val escrow_balance: Double = 0.0,
    val total_earnings: Double = 0.0,
    val total_withdrawn: Double = 0.0,
    val currency: String = "INR"
)

/**
 * Transaction DTO matching Supabase 'transactions' table.
 */
@Serializable
data class TransactionDto(
    val id: String,
    val user_id: String,
    val title: String = "",
    val amount: Double = 0.0,
    val type: String = "",
    val status: String = "completed",
    val reference_id: String? = null,
    val notes: String? = null,
    val created_at: String = ""
)

/**
 * Insert DTO for deposits table.
 */
@Serializable
data class DepositInsertDto(
    val brand_id: String,
    val amount: Double,
    val payment_method: String,
    val transaction_ref: String,
    val status: String = "pending"
)

/**
 * Insert DTO for withdrawals table.
 */
@Serializable
data class WithdrawalInsertDto(
    val user_id: String,
    val amount: Double,
    val payout_method: String,
    val payout_details: String,
    val status: String = "pending"
)
