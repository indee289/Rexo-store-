package com.rexo.marketplace.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

/**
 * Wallet & Transaction Data Models
 */

enum class TransactionType {
    CAMPAIGN_PAYOUT,
    DEPOSIT,
    WITHDRAWAL,
    ESCROW_HOLD,
    ESCROW_RELEASE,
    PLATFORM_FEE,
    ADMIN_CREDIT,
    ADMIN_DEBIT,
    REFUND,
    BONUS
}

enum class TransactionDirection {
    CREDIT, DEBIT
}

enum class TransactionStatus {
    COMPLETED, PENDING, FAILED, REJECTED
}

@Entity(tableName = "wallets")
@Serializable
data class Wallet(
    @PrimaryKey
    val userId: String,
    val availableBalance: Double = 0.0,
    val pendingBalance: Double = 0.0,
    val totalEarned: Double = 0.0,
    val totalSpent: Double = 0.0,
    val escrowHold: Double = 0.0,
    val isFrozen: Boolean = false
)

@Entity(tableName = "wallet_transactions")
@Serializable
data class WalletTransaction(
    @PrimaryKey
    val id: String,
    val userId: String,
    val type: String,
    val amount: Double,
    val direction: String,
    val status: String,
    val note: String,
    val referenceId: String? = null,
    val campaignId: String? = null,
    val campaignTitle: String? = null,
    val counterpartyName: String? = null,
    val proofScreenshotUrl: String? = null,
    val adminRemarks: String? = null,
    val createdAt: String
) {
    fun getTypeEnum(): TransactionType = try {
        TransactionType.valueOf(type)
    } catch (e: Exception) {
        TransactionType.ADMIN_CREDIT
    }
    
    fun getDirectionEnum(): TransactionDirection = try {
        TransactionDirection.valueOf(direction)
    } catch (e: Exception) {
        TransactionDirection.CREDIT
    }
    
    fun getStatusEnum(): TransactionStatus = try {
        TransactionStatus.valueOf(status)
    } catch (e: Exception) {
        TransactionStatus.PENDING
    }
}

@Entity(tableName = "withdrawal_requests")
@Serializable
data class WithdrawalRequest(
    @PrimaryKey
    val id: String,
    val userId: String,
    val userName: String,
    val userRole: String,
    val amount: Double,
    val method: String,  // UPI, Bank, PayPal, Manual
    val payoutDetailsJson: String,  // JSON object
    val status: String = "pending",
    val adminNotes: String? = null,
    val createdAt: String,
    val resolvedAt: String? = null
)

@Entity(tableName = "deposit_requests")
@Serializable
data class DepositRequest(
    @PrimaryKey
    val id: String,
    val brandId: String,
    val brandName: String,
    val amount: Double,
    val paymentMethod: String,
    val transactionRef: String,
    val proofScreenshotUrl: String? = null,
    val notes: String? = null,
    val status: String = "pending",
    val createdAt: String,
    val processedAt: String? = null
)
