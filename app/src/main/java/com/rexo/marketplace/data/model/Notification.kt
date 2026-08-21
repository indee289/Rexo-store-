package com.rexo.marketplace.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

/**
 * Notification & FCM Data Models
 */

enum class NotificationType {
    CAMPAIGN_APPROVED,
    CAMPAIGN_REJECTED,
    CAMPAIGN_APPLICATION_ACCEPTED,
    CAMPAIGN_APPLICATION_REJECTED,
    CREATOR_SELECTED,
    CREATOR_REMOVED,
    WITHDRAWAL_APPROVED,
    WITHDRAWAL_REJECTED,
    DEPOSIT_APPROVED,
    DEPOSIT_REJECTED,
    WALLET_CREDITED,
    WALLET_DEBITED,
    KYC_APPROVED,
    KYC_REJECTED,
    USER_VERIFIED,
    ADMIN_BROADCAST,
    SECURITY_ALERT
}

@Entity(tableName = "notifications")
@Serializable
data class AppNotification(
    @PrimaryKey
    val id: String,
    val userId: String,
    val title: String,
    val body: String,
    val message: String? = null,
    val type: String,
    val payloadJson: String,  // JSON object with screen, targetId, etc.
    val isRead: Boolean = false,
    val deliveryStatus: String? = "sent",
    val referenceId: String? = null,
    val createdAt: String
) {
    fun getTypeEnum(): NotificationType = try {
        NotificationType.valueOf(type)
    } catch (e: Exception) {
        NotificationType.ADMIN_BROADCAST
    }
}

@Entity(tableName = "user_devices")
@Serializable
data class UserDevice(
    @PrimaryKey
    val id: String,
    val userId: String,
    val fcmToken: String,
    val platform: String = "android",
    val appVersion: String,
    val deviceName: String,
    val createdAt: String,
    val updatedAt: String
)
