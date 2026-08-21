package com.rexo.marketplace.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

/**
 * User Data Models
 * Converted from TypeScript interfaces in types/index.ts
 */

enum class UserRole {
    CREATOR, BRAND, ADMIN
}

enum class AdminSubRole {
    SUPER_ADMIN, MODERATOR, FINANCE_ADMIN
}

enum class UserAccountStatus {
    ACTIVE, SUSPENDED, BANNED, PENDING_KYC
}

@Serializable
data class SocialLinks(
    val instagram: String? = null,
    val youtube: String? = null,
    val tiktok: String? = null,
    val x: String? = null,
    val linkedin: String? = null
)

@Serializable
data class BrandProfile(
    val companyName: String,
    val industry: String,
    val website: String,
    val logo: String
)

@Entity(tableName = "users")
@Serializable
data class UserProfile(
    @PrimaryKey
    val id: String,
    val name: String,
    val username: String,
    val email: String,
    val phone: String = "",
    val avatar: String = "",
    val role: String = UserRole.CREATOR.name,
    val adminSubRole: String? = null,
    val accountStatus: String = UserAccountStatus.ACTIVE.name,
    val riskScore: Int = 0,
    val trustScore: Int = 100,
    val warningCount: Int = 0,
    val lastRiskUpdate: String? = null,
    val isShadowBanned: Boolean = false,
    val suspensionEndDate: String? = null,
    val deviceHash: String? = null,
    val lastIpHash: String? = null,
    val isVerified: Boolean = false,
    val createdAt: String,
    val bio: String = "",
    val location: String = "",
    val niche: String = "",
    val age: Int? = null,
    val website: String? = null,
    
    // Creator specific
    val followersCount: Int? = null,
    val engagementRate: Double? = null,
    val rating: Double? = null,
    val kycVerified: Boolean = false,
    
    // Serialized JSON fields
    val socialLinksJson: String? = null,  // Store as JSON string
    val portfolioJson: String? = null,    // Store as JSON string
    val brandProfileJson: String? = null  // Store as JSON string
) {
    fun getRoleEnum(): UserRole = try {
        UserRole.valueOf(role)
    } catch (e: Exception) {
        UserRole.CREATOR
    }
    
    fun getAccountStatusEnum(): UserAccountStatus = try {
        UserAccountStatus.valueOf(accountStatus)
    } catch (e: Exception) {
        UserAccountStatus.ACTIVE
    }
}

@Serializable
data class PortfolioItem(
    val id: String,
    val title: String,
    val brandName: String,
    val deliverableType: String,
    val linkUrl: String,
    val thumbnailUrl: String,
    val viewsCount: Int,
    val likesCount: Int
)
