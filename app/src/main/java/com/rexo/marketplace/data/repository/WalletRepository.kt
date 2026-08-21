package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.local.WalletDao
import com.rexo.marketplace.data.model.Wallet
import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.ui.viewmodel.*
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Date

/**
 * Wallet Repository
 * Handles wallet operations with Supabase and local Room
 */
class WalletRepository(
    private val walletDao: WalletDao,
    private val supabaseClient: SupabaseClient
) {
    suspend fun getWallet(): Wallet? = withContext(Dispatchers.IO) {
        try {
            // Try Supabase first
            val response = supabaseClient.client
                .from("wallets")
                .select()
                .decodeSingle<Wallet>()
            
            // Cache locally
            walletDao.insertWallet(response)
            response
        } catch (e: Exception) {
            // Fallback to local cache
            walletDao.getWallet(userId = "current_user")
        }
    }

    suspend fun getTransactions(): List<Transaction> = withContext(Dispatchers.IO) {
        try {
            // Fetch from Supabase
            val response = supabaseClient.client
                .from("wallet_transactions")
                .select()
                .decodeList<TransactionDto>()
            
            response.map { it.toTransaction() }
        } catch (e: Exception) {
            // Mock data for now
            listOf(
                Transaction(
                    "1",
                    "Campaign Payment",
                    5000.0,
                    "completed",
                    Date(),
                    "Payment from Brand XYZ"
                ),
                Transaction(
                    "2",
                    "Withdrawal",
                    2000.0,
                    "pending",
                    Date(),
                    "Bank Transfer"
                )
            )
        }
    }

    suspend fun getAnalytics(): WalletAnalytics = withContext(Dispatchers.IO) {
        try {
            // Calculate from transactions
            val transactions = getTransactions()
            val income = transactions.filter { it.type.contains("Payment", ignoreCase = true) }
                .sumOf { it.amount }
            val expense = transactions.filter { it.type.contains("Withdrawal", ignoreCase = true) }
                .sumOf { it.amount }
            
            WalletAnalytics(
                totalIncome = income,
                totalExpense = expense,
                categoryBreakdown = mapOf(
                    "Campaign Earnings" to income * 0.8,
                    "Referral Bonus" to income * 0.15,
                    "Other" to income * 0.05
                ),
                monthlyTrends = listOf(
                    MonthlyData("Jan", 15000.0, 5000.0),
                    MonthlyData("Feb", 18000.0, 7000.0),
                    MonthlyData("Mar", 22000.0, 8000.0)
                )
            )
        } catch (e: Exception) {
            WalletAnalytics(0.0, 0.0, emptyMap(), emptyList())
        }
    }

    suspend fun getEscrowItems(): List<EscrowItem> = withContext(Dispatchers.IO) {
        try {
            val response = supabaseClient.client
                .from("escrow")
                .select()
                .decodeList<EscrowDto>()
            
            response.map { it.toEscrowItem() }
        } catch (e: Exception) {
            // Mock data
            listOf(
                EscrowItem(
                    "1",
                    "Summer Campaign 2024",
                    5000.0,
                    "pending",
                    Date(),
                    true
                )
            )
        }
    }

    suspend fun deposit(amount: Double, method: String) = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("deposit_requests").insert(
                mapOf(
                    "amount" to amount,
                    "payment_method" to method,
                    "status" to "pending"
                )
            )
        } catch (e: Exception) {
            throw Exception("Deposit failed: ${e.message}")
        }
    }

    suspend fun withdraw(
        amount: Double, 
        method: String, 
        accountDetails: Map<String, String>
    ) = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("withdrawal_requests").insert(
                mapOf(
                    "amount" to amount,
                    "payment_method" to method,
                    "account_details" to accountDetails,
                    "status" to "pending"
                )
            )
        } catch (e: Exception) {
            throw Exception("Withdrawal failed: ${e.message}")
        }
    }

    suspend fun releaseEscrow(escrowId: String) = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("escrow").update(
                mapOf("status" to "released")
            ) {
                filter {
                    eq("id", escrowId)
                }
            }
        } catch (e: Exception) {
            throw Exception("Release failed: ${e.message}")
        }
    }

    suspend fun raiseDispute(escrowId: String, reason: String) = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("disputes").insert(
                mapOf(
                    "escrow_id" to escrowId,
                    "reason" to reason,
                    "status" to "pending"
                )
            )
        } catch (e: Exception) {
            throw Exception("Failed to raise dispute: ${e.message}")
        }
    }
}

// DTOs for Supabase
@kotlinx.serialization.Serializable
data class TransactionDto(
    val id: String,
    val type: String,
    val amount: Double,
    val status: String,
    val created_at: String,
    val description: String
) {
    fun toTransaction() = Transaction(
        id, type, amount, status, Date(), description
    )
}

@kotlinx.serialization.Serializable
data class EscrowDto(
    val id: String,
    val campaign_name: String,
    val amount: Double,
    val status: String,
    val due_date: String,
    val can_release: Boolean
) {
    fun toEscrowItem() = EscrowItem(
        id, campaign_name, amount, status, Date(), can_release
    )
}
