package com.rexo.marketplace.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

/**
 * Campaign Data Models
 */

enum class CampaignStatus {
    ACTIVE, COMPLETED, PAUSED, DRAFT, REJECTED
}

enum class ApplicationStatus {
    APPLIED, SHORTLISTED, HIRED, REJECTED, SUBMITTED, APPROVED, PAID
}

enum class EscrowStatus {
    HELD, RELEASED, REFUNDED, PARTIALLY_RELEASED
}

@Entity(tableName = "campaigns")
@Serializable
data class Campaign(
    @PrimaryKey
    val id: String,
    val brandId: String,
    val brandName: String,
    val brandLogo: String,
    val title: String,
    val description: String,
    val niche: String,
    val platform: String,
    val deliverableType: String,
    val payoutPerCreator: Double,
    val totalBudget: Double,
    val totalSlots: Int,
    val filledSlots: Int = 0,
    val minFollowers: Int,
    val minEngagementRate: Double,
    val deadline: String,
    val requirementsJson: String,  // JSON array of requirements
    val status: String = CampaignStatus.ACTIVE.name,
    val createdAt: String,
    val escrowStatus: String? = EscrowStatus.HELD.name,
    val escrowAmount: Double? = null,
    val coverImage: String? = null,
    val sampleDemoUrl: String? = null,
    val guidelines: String? = null,
    val dosAndDontsJson: String? = null,  // JSON array
    val aiFlagStatus: String? = "safe",
    val moderationReason: String? = null
) {
    fun getStatusEnum(): CampaignStatus = try {
        CampaignStatus.valueOf(status)
    } catch (e: Exception) {
        CampaignStatus.ACTIVE
    }
}

@Entity(tableName = "campaign_applications")
@Serializable
data class CampaignApplication(
    @PrimaryKey
    val id: String,
    val campaignId: String,
    val campaignTitle: String,
    val brandName: String,
    val creatorId: String,
    val creatorName: String,
    val creatorAvatar: String,
    val creatorHandle: String,
    val followersCount: Int,
    val engagementRate: Double,
    val proposedPitch: String,
    val feeRequested: Double,
    val deliverableUrl: String? = null,
    val status: String = ApplicationStatus.APPLIED.name,
    val appliedAt: String,
    val submittedAt: String? = null,
    val reviewedAt: String? = null,
    val rejectionReason: String? = null,
    val payoutRemarks: String? = null,
    val paidAt: String? = null
) {
    fun getStatusEnum(): ApplicationStatus = try {
        ApplicationStatus.valueOf(status)
    } catch (e: Exception) {
        ApplicationStatus.APPLIED
    }
}
