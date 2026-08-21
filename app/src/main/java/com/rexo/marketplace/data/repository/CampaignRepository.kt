package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.local.CampaignDao
import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.ui.viewmodel.*
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable

/**
 * Campaign Repository
 * Handles campaign operations with Supabase.
 * No mock data fallback - shows proper error/empty states.
 */
class CampaignRepository(
    private val campaignDao: CampaignDao? = null
) {
    /**
     * Fetch campaigns from Supabase.
     * Supports optional category filtering and search query.
     * On error, throws exception for ViewModel to handle.
     */
    suspend fun getCampaigns(
        category: String = "All",
        searchQuery: String = ""
    ): List<CampaignItem> = withContext(Dispatchers.IO) {
        val query = SupabaseClient.client.from("campaigns").select()
        val allCampaigns = query.decodeList<CampaignDto>()

        val filtered = allCampaigns
            .filter { dto ->
                if (category != "All") dto.category.equals(category, ignoreCase = true) else true
            }
            .filter { dto ->
                if (searchQuery.isNotBlank()) {
                    dto.title.contains(searchQuery, ignoreCase = true) ||
                        dto.description.contains(searchQuery, ignoreCase = true)
                } else true
            }

        filtered.map { it.toCampaignItem() }
    }

    /**
     * Fetch all unique categories from campaigns table.
     */
    suspend fun getCategories(): List<String> = withContext(Dispatchers.IO) {
        val query = SupabaseClient.client.from("campaigns").select()
        val allCampaigns = query.decodeList<CampaignDto>()
        val categories = allCampaigns.map { it.category }.distinct().sorted()
        listOf("All") + categories
    }

    suspend fun applyToCampaign(
        campaignId: String,
        campaignTitle: String,
        brandName: String,
        feeRequested: Double,
        proposal: String
    ) = withContext(Dispatchers.IO) {
        val authUser = SupabaseClient.auth.currentUserOrNull()
            ?: throw Exception("Not authenticated")
        val userId = authUser.id
        val userName = authUser.userMetadata?.get("full_name")?.toString()?.removeSurrounding("\"")
            ?: authUser.userMetadata?.get("name")?.toString()?.removeSurrounding("\"")
            ?: authUser.email?.substringBefore("@") ?: "Unknown"
        val userHandle = authUser.email?.substringBefore("@") ?: "user"

        val applicationDto = CampaignApplicationInsertDto(
            id = "APP-${System.currentTimeMillis()}-${userId.take(8)}",
            campaign_id = campaignId,
            campaign_title = campaignTitle,
            brand_name = brandName,
            creator_id = userId,
            creator_name = userName,
            creator_handle = userHandle,
            fee_requested = feeRequested,
            pitch = proposal,
            status = "submitted"
        )

        SupabaseClient.client.from("campaign_applications").insert(applicationDto)
    }

    suspend fun createCampaign(request: CreateCampaignRequest) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("campaigns").insert(
            mapOf(
                "title" to request.title,
                "description" to request.description,
                "category" to request.category,
                "platform" to request.platform,
                "budget" to request.budget,
                "deadline" to request.deadline,
                "deliverables" to request.deliverables,
                "requirements" to request.requirements,
                "status" to "active"
            )
        )
    }
}

/**
 * DTO matching the Supabase 'campaigns' table schema exactly.
 */
@kotlinx.serialization.Serializable
data class CampaignDto(
    val id: String,
    val brand_id: String = "",
    val brand_name: String = "",
    val brand_avatar: String? = null,
    val title: String,
    val category: String,
    val budget: Double,
    val payout_per_creator: Double = 0.0,
    val deadline: String = "",
    val deliverable_type: String = "",
    val slots: Int = 1,
    val filled_slots: Int = 0,
    val description: String = "",
    val requirements: String? = null,
    val image: String? = null,
    val status: String = "active",
    val created_at: String? = null
) {
    fun toCampaignItem() = CampaignItem(
        id = id,
        title = title,
        description = description,
        category = category,
        budget = budget,
        payoutPerCreator = payout_per_creator,
        brandName = brand_name,
        brandAvatar = brand_avatar,
        deadline = deadline,
        slots = slots,
        filledSlots = filled_slots,
        status = status,
        deliverableType = deliverable_type,
        image = image
    )
}

/**
 * DTO for inserting a campaign application into 'campaign_applications' table.
 * Includes all NOT NULL fields required by the schema.
 */
@Serializable
data class CampaignApplicationInsertDto(
    val id: String,
    val campaign_id: String,
    val campaign_title: String,
    val brand_name: String,
    val creator_id: String,
    val creator_name: String,
    val creator_handle: String,
    val fee_requested: Double,
    val pitch: String? = null,
    val status: String = "submitted"
)
