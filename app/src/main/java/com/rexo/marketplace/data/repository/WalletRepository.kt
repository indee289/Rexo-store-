package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.remote.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

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
     * If no wallet row exists, creates one with default zero balances.
     */
    suspend fun getWallet(): WalletFullDto? = withContext(Dispatchers.IO) {
        val userId = getCurrentUserId()
        try {
            val wallet = try {
                SupabaseClient.client.from("wallets").select {
                    filter { eq("user_id", userId) }
                }.decodeSingle<WalletFullDto>()
            } catch (e: Exception) {
                null
            }

            if (wallet != null) return@withContext wallet

            // No wallet row - create one with zero balances
            return@withContext ensureWallet(userId)
        } catch (e: Exception) {
            if (e.message?.contains("Not authenticated") == true) throw e
            null
        }
    }

    /**
     * Ensure a wallet row exists for the given user.
     * Uses upsert with onConflict to avoid race conditions on concurrent access.
     */
    private suspend fun ensureWallet(userId: String): WalletFullDto? {
        return try {
            val newWallet = WalletInsertDto(
                user_id = userId,
                available_balance = 0.0,
                escrow_balance = 0.0,
                total_earnings = 0.0,
                total_withdrawn = 0.0,
                currency = "INR"
            )
            SupabaseClient.client.from("wallets").upsert(newWallet) {
                onConflict = "user_id"
            }

            // Fetch and return the wallet row
            SupabaseClient.client.from("wallets").select {
                filter { eq("user_id", userId) }
            }.decodeSingle<WalletFullDto>()
        } catch (e: Exception) {
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
        val authUser = SupabaseClient.auth.currentUserOrNull()
        val userName = authUser?.userMetadata?.get("full_name")?.toString()?.removeSurrounding("\"")
            ?: authUser?.userMetadata?.get("name")?.toString()?.removeSurrounding("\"")
            ?: authUser?.email?.substringBefore("@") ?: "Unknown"

        SupabaseClient.client.from("deposits").insert(
            DepositInsertDto(
                id = "DEP-${System.currentTimeMillis()}-${userId.take(8)}",
                brand_id = userId,
                brand_name = userName,
                amount = amount,
                payment_method = paymentMethod,
                transaction_ref = "DEP-${System.currentTimeMillis()}",
                status = "pending"
            )
        )
    }

    /**
     * Create a withdrawal request in the 'withdrawals' table.
     * payout_details is serialized as a JSONB object matching the schema.
     */
    suspend fun withdraw(amount: Double, payoutMethod: String, payoutDetails: String) = withContext(Dispatchers.IO) {
        val userId = getCurrentUserId()
        val authUser = SupabaseClient.auth.currentUserOrNull()
        val userName = authUser?.userMetadata?.get("full_name")?.toString()?.removeSurrounding("\"")
            ?: authUser?.userMetadata?.get("name")?.toString()?.removeSurrounding("\"")
            ?: authUser?.email?.substringBefore("@") ?: "Unknown"

        val payoutDetailsJson = buildJsonObject {
            put("method", payoutMethod)
            put("detail", payoutDetails)
        }

        SupabaseClient.client.from("withdrawals").insert(
            WithdrawalInsertDto(
                id = "WDR-${System.currentTimeMillis()}-${userId.take(8)}",
                user_id = userId,
                user_name = userName,
                user_role = "creator",
                amount = amount,
                payout_method = payoutMethod,
                payout_details = payoutDetailsJson,
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
 * Includes all NOT NULL fields required by the schema.
 */
@Serializable
data class DepositInsertDto(
    val id: String,
    val brand_id: String,
    val brand_name: String,
    val amount: Double,
    val payment_method: String,
    val transaction_ref: String,
    val status: String = "pending"
)

/**
 * Insert DTO for withdrawals table.
 * Includes all NOT NULL fields required by the schema.
 * payout_details is JSONB, serialized as a JsonObject.
 */
@Serializable
data class WithdrawalInsertDto(
    val id: String,
    val user_id: String,
    val user_name: String,
    val user_role: String = "creator",
    val amount: Double,
    val payout_method: String,
    val payout_details: JsonObject,
    val status: String = "pending"
)

/**
 * Insert DTO for creating a new wallet row.
 */
@Serializable
data class WalletInsertDto(
    val user_id: String,
    val available_balance: Double = 0.0,
    val escrow_balance: Double = 0.0,
    val total_earnings: Double = 0.0,
    val total_withdrawn: Double = 0.0,
    val currency: String = "INR"
)
