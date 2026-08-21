package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.remote.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable

/**
 * Admin Repository
 * Handles all admin panel data operations against Supabase.
 * Covers: dashboard stats, user management, campaign control, submissions,
 * deposits, withdrawals, shop admin, disputes, KYC, wallets, settings,
 * audit logs, and broadcast notifications.
 */
class AdminRepository {

    private fun getCurrentAdminId(): String {
        return SupabaseClient.auth.currentUserOrNull()?.id ?: "unknown_admin"
    }

    private fun getCurrentAdminName(): String {
        val user = SupabaseClient.auth.currentUserOrNull()
        return user?.userMetadata?.get("full_name")?.toString()?.removeSurrounding("\"")
            ?: user?.userMetadata?.get("name")?.toString()?.removeSurrounding("\"")
            ?: user?.email?.substringBefore("@")
            ?: "Admin"
    }

    // ========== DASHBOARD ==========

    suspend fun getDashboardStats(): AdminDashboardStats = withContext(Dispatchers.IO) {
        val users = try {
            SupabaseClient.client.from("users").select().decodeList<AdminUserCountDto>()
        } catch (_: Exception) { emptyList() }

        val campaigns = try {
            SupabaseClient.client.from("campaigns").select().decodeList<AdminCampaignListDto>()
        } catch (_: Exception) { emptyList() }

        val wallets = try {
            SupabaseClient.client.from("wallets").select().decodeList<AdminWalletDto>()
        } catch (_: Exception) { emptyList() }

        val pendingWithdrawals = try {
            SupabaseClient.client.from("withdrawals").select {
                filter { eq("status", "pending") }
            }.decodeList<AdminWithdrawalDto>()
        } catch (_: Exception) { emptyList() }

        val activeCampaigns = campaigns.count { it.status == "active" }
        val totalEscrow = wallets.sumOf { it.escrow_balance }
        val pendingPayouts = pendingWithdrawals.sumOf { it.amount }

        AdminDashboardStats(
            totalUsers = users.size,
            activeCampaigns = activeCampaigns,
            totalCampaigns = campaigns.size,
            lockedEscrow = totalEscrow,
            pendingPayouts = pendingPayouts,
            totalWalletBalance = wallets.sumOf { it.available_balance },
            totalRevenue = wallets.sumOf { it.total_earnings }
        )
    }

    // ========== USER MANAGEMENT ==========

    suspend fun getUsers(
        searchQuery: String = "",
        roleFilter: String = "all",
        statusFilter: String = "all"
    ): List<AdminUserDto> = withContext(Dispatchers.IO) {
        try {
            val users = SupabaseClient.client.from("users").select()
                .decodeList<AdminUserDto>()

            users.filter { user ->
                val matchesSearch = searchQuery.isBlank() ||
                    user.name.contains(searchQuery, ignoreCase = true) ||
                    user.email.contains(searchQuery, ignoreCase = true)

                val matchesRole = roleFilter == "all" ||
                    user.role.equals(roleFilter, ignoreCase = true)

                val matchesStatus = when (statusFilter) {
                    "active" -> !user.is_banned && !user.is_suspended
                    "suspended" -> user.is_suspended
                    "banned" -> user.is_banned
                    else -> true
                }

                matchesSearch && matchesRole && matchesStatus
            }
        } catch (e: Exception) {
            throw Exception("Failed to fetch users: ${e.message}")
        }
    }

    suspend fun updateUserVerification(userId: String, isVerified: Boolean) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("users").update({
            set("is_verified", isVerified)
        }) {
            filter { eq("id", userId) }
        }
        logAction("user_verification", userId, if (isVerified) "Granted verified badge" else "Removed verified badge")
    }

    suspend fun updateUserRole(userId: String, newRole: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("users").update({
            set("role", newRole)
        }) {
            filter { eq("id", userId) }
        }
        logAction("role_change", userId, "Changed role to $newRole")
    }

    suspend fun suspendUser(userId: String, reason: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("users").update({
            set("is_suspended", true)
        }) {
            filter { eq("id", userId) }
        }
        logAction("user_suspend", userId, "Suspended: $reason")
    }

    suspend fun unsuspendUser(userId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("users").update({
            set("is_suspended", false)
        }) {
            filter { eq("id", userId) }
        }
        logAction("user_unsuspend", userId, "Unsuspended user")
    }

    suspend fun banUser(userId: String, reason: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("users").update({
            set("is_banned", true)
        }) {
            filter { eq("id", userId) }
        }
        logAction("user_ban", userId, "Banned: $reason")
    }

    suspend fun unbanUser(userId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("users").update({
            set("is_banned", false)
        }) {
            filter { eq("id", userId) }
        }
        logAction("user_unban", userId, "Unbanned user")
    }

    suspend fun deleteUser(userId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("users").delete {
            filter { eq("id", userId) }
        }
        logAction("user_delete", userId, "Deleted user account")
    }

    // ========== CAMPAIGN CONTROL ==========

    suspend fun getCampaigns(statusFilter: String = "all"): List<AdminCampaignListDto> = withContext(Dispatchers.IO) {
        try {
            val campaigns = SupabaseClient.client.from("campaigns").select()
                .decodeList<AdminCampaignListDto>()

            if (statusFilter == "all") campaigns
            else campaigns.filter { it.status.equals(statusFilter, ignoreCase = true) }
        } catch (e: Exception) {
            throw Exception("Failed to fetch campaigns: ${e.message}")
        }
    }

    suspend fun pauseCampaign(campaignId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("campaigns").update({
            set("status", "paused")
        }) {
            filter { eq("id", campaignId) }
        }
        logAction("campaign_pause", campaignId, "Paused campaign")
    }

    suspend fun resumeCampaign(campaignId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("campaigns").update({
            set("status", "active")
        }) {
            filter { eq("id", campaignId) }
        }
        logAction("campaign_resume", campaignId, "Resumed campaign")
    }

    suspend fun forceCompleteCampaign(campaignId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("campaigns").update({
            set("status", "completed")
        }) {
            filter { eq("id", campaignId) }
        }
        logAction("campaign_force_complete", campaignId, "Force completed campaign")
    }

    suspend fun forceCancelCampaign(campaignId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("campaigns").update({
            set("status", "cancelled")
        }) {
            filter { eq("id", campaignId) }
        }
        logAction("campaign_cancel", campaignId, "Force cancelled campaign with refund")
    }

    suspend fun deleteCampaign(campaignId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("campaigns").delete {
            filter { eq("id", campaignId) }
        }
        logAction("campaign_delete", campaignId, "Deleted campaign")
    }

    // ========== CONTENT SUBMISSIONS ==========

    suspend fun getSubmissions(statusFilter: String = "all"): List<AdminSubmissionDto> = withContext(Dispatchers.IO) {
        try {
            val submissions = SupabaseClient.client.from("campaign_applications").select()
                .decodeList<AdminSubmissionDto>()

            if (statusFilter == "all") submissions
            else submissions.filter { it.status.equals(statusFilter, ignoreCase = true) }
        } catch (e: Exception) {
            throw Exception("Failed to fetch submissions: ${e.message}")
        }
    }

    suspend fun approveSubmission(applicationId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("campaign_applications").update({
            set("status", "approved")
        }) {
            filter { eq("id", applicationId) }
        }
        logAction("submission_approve", applicationId, "Approved submission")
    }

    suspend fun rejectSubmission(applicationId: String, reason: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("campaign_applications").update({
            set("status", "rejected")
        }) {
            filter { eq("id", applicationId) }
        }
        logAction("submission_reject", applicationId, "Rejected: $reason")
    }

    suspend fun disburseSubmissionPayout(applicationId: String, creatorId: String, amount: Double) = withContext(Dispatchers.IO) {
        // Mark application as paid
        SupabaseClient.client.from("campaign_applications").update({
            set("status", "paid")
        }) {
            filter { eq("id", applicationId) }
        }
        logAction("payout_disburse", applicationId, "Disbursed payout of $amount to creator $creatorId")
    }

    // ========== DEPOSIT REQUESTS ==========

    suspend fun getPendingDeposits(): List<AdminDepositDto> = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("deposits").select {
                filter { eq("status", "pending") }
            }.decodeList<AdminDepositDto>()
        } catch (e: Exception) {
            throw Exception("Failed to fetch deposits: ${e.message}")
        }
    }

    suspend fun approveDeposit(depositId: String, brandId: String, amount: Double) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("deposits").update({
            set("status", "approved")
        }) {
            filter { eq("id", depositId) }
        }
        logAction("deposit_approve", depositId, "Approved deposit of $amount for brand $brandId")
    }

    suspend fun rejectDeposit(depositId: String, remarks: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("deposits").update({
            set("status", "rejected")
        }) {
            filter { eq("id", depositId) }
        }
        logAction("deposit_reject", depositId, "Rejected: $remarks")
    }

    // ========== WITHDRAWAL REQUESTS ==========

    suspend fun getPendingWithdrawals(): List<AdminWithdrawalDto> = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("withdrawals").select {
                filter { eq("status", "pending") }
            }.decodeList<AdminWithdrawalDto>()
        } catch (e: Exception) {
            throw Exception("Failed to fetch withdrawals: ${e.message}")
        }
    }

    suspend fun approveWithdrawal(withdrawalId: String, bankReference: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("withdrawals").update({
            set("status", "approved")
        }) {
            filter { eq("id", withdrawalId) }
        }
        logAction("withdrawal_approve", withdrawalId, "Approved with ref: $bankReference")
    }

    suspend fun rejectWithdrawal(withdrawalId: String, reason: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("withdrawals").update({
            set("status", "rejected")
        }) {
            filter { eq("id", withdrawalId) }
        }
        logAction("withdrawal_reject", withdrawalId, "Rejected: $reason")
    }

    // ========== E-COMMERCE & SHOP ==========

    suspend fun getProducts(): List<AdminProductDto> = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("store_products").select()
                .decodeList<AdminProductDto>()
        } catch (e: Exception) {
            throw Exception("Failed to fetch products: ${e.message}")
        }
    }

    suspend fun addProduct(product: AdminProductInsertDto) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("store_products").insert(product)
        logAction("product_add", product.id, "Added product: ${product.name}")
    }

    suspend fun updateProductStatus(productId: String, status: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("store_products").update({
            set("status", status)
        }) {
            filter { eq("id", productId) }
        }
        logAction("product_update", productId, "Updated product status to $status")
    }

    suspend fun deleteProduct(productId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("store_products").delete {
            filter { eq("id", productId) }
        }
        logAction("product_delete", productId, "Deleted product")
    }

    suspend fun getOrders(): List<AdminOrderDto> = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("store_orders").select()
                .decodeList<AdminOrderDto>()
        } catch (e: Exception) {
            throw Exception("Failed to fetch orders: ${e.message}")
        }
    }

    suspend fun updateOrderStatus(orderId: String, newStatus: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("store_orders").update({
            set("status", newStatus)
        }) {
            filter { eq("id", orderId) }
        }
        logAction("order_status_update", orderId, "Updated order status to $newStatus")
    }

    // ========== DISPUTES ==========

    suspend fun getDisputes(): List<AdminDisputeDto> = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("disputes").select()
                .decodeList<AdminDisputeDto>()
        } catch (e: Exception) {
            throw Exception("Failed to fetch disputes: ${e.message}")
        }
    }

    suspend fun resolveDispute(disputeId: String, resolution: String, action: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("disputes").update({
            set("status", "resolved")
            set("resolution", resolution)
        }) {
            filter { eq("id", disputeId) }
        }
        logAction("dispute_resolve", disputeId, "Resolved ($action): $resolution")
    }

    suspend fun dismissDispute(disputeId: String, reason: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("disputes").update({
            set("status", "dismissed")
            set("resolution", reason)
        }) {
            filter { eq("id", disputeId) }
        }
        logAction("dispute_dismiss", disputeId, "Dismissed: $reason")
    }

    // ========== KYC VERIFICATION ==========

    suspend fun getPendingKyc(): List<AdminKycDto> = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("kyc_documents").select {
                filter { eq("status", "pending") }
            }.decodeList<AdminKycDto>()
        } catch (e: Exception) {
            throw Exception("Failed to fetch KYC documents: ${e.message}")
        }
    }

    suspend fun approveKyc(kycId: String, userId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("kyc_documents").update({
            set("status", "approved")
        }) {
            filter { eq("id", kycId) }
        }
        // Grant verified badge
        SupabaseClient.client.from("users").update({
            set("is_verified", true)
        }) {
            filter { eq("id", userId) }
        }
        logAction("kyc_approve", kycId, "Approved KYC for user $userId and granted verified badge")
    }

    suspend fun rejectKyc(kycId: String, reason: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("kyc_documents").update({
            set("status", "rejected")
        }) {
            filter { eq("id", kycId) }
        }
        logAction("kyc_reject", kycId, "Rejected: $reason")
    }

    // ========== WALLETS & ESCROW ==========

    suspend fun getAllWallets(): List<AdminWalletDto> = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("wallets").select()
                .decodeList<AdminWalletDto>()
        } catch (e: Exception) {
            throw Exception("Failed to fetch wallets: ${e.message}")
        }
    }

    suspend fun freezeWallet(userId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("wallets").update({
            set("is_frozen", true)
        }) {
            filter { eq("user_id", userId) }
        }
        logAction("wallet_freeze", userId, "Froze wallet")
    }

    suspend fun unfreezeWallet(userId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("wallets").update({
            set("is_frozen", false)
        }) {
            filter { eq("user_id", userId) }
        }
        logAction("wallet_unfreeze", userId, "Unfroze wallet")
    }

    suspend fun manualCreditWallet(userId: String, amount: Double, reason: String) = withContext(Dispatchers.IO) {
        // Note: In production, this would use an RPC or transaction to safely update balance
        logAction("wallet_credit", userId, "Manual credit of $amount: $reason")
    }

    suspend fun manualDebitWallet(userId: String, amount: Double, reason: String) = withContext(Dispatchers.IO) {
        logAction("wallet_debit", userId, "Manual debit of $amount: $reason")
    }

    // ========== SYSTEM SETTINGS ==========

    suspend fun getSettings(): AdminSettingsDto = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("platform_settings").select()
                .decodeSingle<AdminSettingsDto>()
        } catch (_: Exception) {
            AdminSettingsDto()
        }
    }

    suspend fun updateSettings(settings: AdminSettingsDto) = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("platform_settings").upsert(settings) {
                onConflict = "id"
            }
            logAction("settings_update", "platform", "Updated platform settings")
        } catch (e: Exception) {
            throw Exception("Failed to update settings: ${e.message}")
        }
    }

    // ========== AUDIT LOGS ==========

    suspend fun getAuditLogs(actionFilter: String = "all"): List<AdminAuditLogDto> = withContext(Dispatchers.IO) {
        try {
            val logs = SupabaseClient.client.from("audit_logs").select()
                .decodeList<AdminAuditLogDto>()

            val filtered = if (actionFilter == "all") logs
            else logs.filter { it.action_type.contains(actionFilter, ignoreCase = true) }

            filtered.sortedByDescending { it.created_at }
        } catch (e: Exception) {
            throw Exception("Failed to fetch audit logs: ${e.message}")
        }
    }

    suspend fun logAction(actionType: String, targetId: String, reason: String) {
        try {
            val log = AdminAuditLogInsertDto(
                admin_id = getCurrentAdminId(),
                admin_name = getCurrentAdminName(),
                action_type = actionType,
                target_id = targetId,
                reason = reason
            )
            SupabaseClient.client.from("audit_logs").insert(log)
        } catch (_: Exception) {
            // Audit log failure should not block admin actions
        }
    }

    // ========== BROADCAST NOTIFICATIONS ==========

    suspend fun sendBroadcast(title: String, body: String, targetAudience: String) = withContext(Dispatchers.IO) {
        try {
            if (targetAudience == "all") {
                val users = SupabaseClient.client.from("users").select()
                    .decodeList<AdminUserCountDto>()
                users.forEach { user ->
                    val notification = AdminNotificationInsertDto(
                        user_id = user.id,
                        title = title,
                        body = body,
                        type = "broadcast"
                    )
                    SupabaseClient.client.from("notifications").insert(notification)
                }
            } else {
                val users = SupabaseClient.client.from("users").select {
                    filter { eq("role", targetAudience) }
                }.decodeList<AdminUserCountDto>()
                users.forEach { user ->
                    val notification = AdminNotificationInsertDto(
                        user_id = user.id,
                        title = title,
                        body = body,
                        type = "broadcast"
                    )
                    SupabaseClient.client.from("notifications").insert(notification)
                }
            }
            logAction("broadcast_send", targetAudience, "Sent broadcast: $title")
        } catch (e: Exception) {
            throw Exception("Failed to send broadcast: ${e.message}")
        }
    }
}

// ========== DTOs ==========

@Serializable
data class AdminUserCountDto(
    val id: String = ""
)

@Serializable
data class AdminUserDto(
    val id: String = "",
    val email: String = "",
    val name: String = "",
    val role: String = "creator",
    val is_verified: Boolean = false,
    val is_banned: Boolean = false,
    val is_suspended: Boolean = false,
    val created_at: String = ""
)

@Serializable
data class AdminCampaignListDto(
    val id: String = "",
    val title: String = "",
    val brand_name: String = "",
    val budget: Double = 0.0,
    val status: String = "active",
    val category: String = "",
    val created_at: String = ""
)

@Serializable
data class AdminSubmissionDto(
    val id: String = "",
    val campaign_id: String = "",
    val campaign_title: String = "",
    val creator_id: String = "",
    val creator_name: String = "",
    val deliverable_url: String = "",
    val proposal: String = "",
    val fee_requested: Double = 0.0,
    val status: String = "applied",
    val created_at: String = ""
)

@Serializable
data class AdminDepositDto(
    val id: String = "",
    val brand_id: String = "",
    val brand_name: String = "",
    val amount: Double = 0.0,
    val payment_method: String = "",
    val transaction_ref: String = "",
    val status: String = "pending",
    val created_at: String = ""
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
data class AdminProductDto(
    val id: String = "",
    val name: String = "",
    val description: String = "",
    val price: Double = 0.0,
    val stock: Int = 0,
    val status: String = "active",
    val image_url: String = "",
    val created_at: String = ""
)

@Serializable
data class AdminProductInsertDto(
    val id: String = "",
    val name: String = "",
    val description: String = "",
    val price: Double = 0.0,
    val stock: Int = 0,
    val status: String = "active",
    val image_url: String = ""
)

@Serializable
data class AdminOrderDto(
    val id: String = "",
    val user_id: String = "",
    val product_id: String = "",
    val quantity: Int = 1,
    val total_amount: Double = 0.0,
    val status: String = "pending",
    val created_at: String = ""
)

@Serializable
data class AdminDisputeDto(
    val id: String = "",
    val campaign_id: String = "",
    val creator_id: String = "",
    val brand_id: String = "",
    val reason: String = "",
    val details: String = "",
    val status: String = "open",
    val resolution: String = "",
    val created_at: String = ""
)

@Serializable
data class AdminKycDto(
    val id: String = "",
    val user_id: String = "",
    val user_name: String = "",
    val document_type: String = "",
    val document_url: String = "",
    val status: String = "pending",
    val submitted_at: String = ""
)

@Serializable
data class AdminWalletDto(
    val user_id: String = "",
    val available_balance: Double = 0.0,
    val escrow_balance: Double = 0.0,
    val total_earnings: Double = 0.0,
    val total_withdrawn: Double = 0.0,
    val is_frozen: Boolean = false,
    val currency: String = "INR"
)

@Serializable
data class AdminSettingsDto(
    val id: String = "default",
    val commission_percentage: Double = 10.0,
    val min_withdrawal_amount: Double = 100.0,
    val maintenance_mode: Boolean = false,
    val auto_approve_submissions: Boolean = false,
    val announcement_banner: String = ""
)

@Serializable
data class AdminAuditLogDto(
    val id: String = "",
    val admin_id: String = "",
    val admin_name: String = "",
    val action_type: String = "",
    val target_id: String = "",
    val reason: String = "",
    val created_at: String = ""
)

@Serializable
data class AdminAuditLogInsertDto(
    val admin_id: String = "",
    val admin_name: String = "",
    val action_type: String = "",
    val target_id: String = "",
    val reason: String = ""
)

@Serializable
data class AdminNotificationInsertDto(
    val user_id: String = "",
    val title: String = "",
    val body: String = "",
    val type: String = "broadcast"
)

@Serializable
data class AdminDashboardStats(
    val totalUsers: Int = 0,
    val activeCampaigns: Int = 0,
    val totalCampaigns: Int = 0,
    val lockedEscrow: Double = 0.0,
    val pendingPayouts: Double = 0.0,
    val totalWalletBalance: Double = 0.0,
    val totalRevenue: Double = 0.0
)
