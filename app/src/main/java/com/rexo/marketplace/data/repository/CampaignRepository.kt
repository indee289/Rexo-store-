package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.local.CampaignDao
import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.ui.viewmodel.*
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

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

    suspend fun applyToCampaign(campaignId: String, proposal: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("campaign_applications").insert(
            mapOf(
                "campaign_id" to campaignId,
                "proposal" to proposal,
                "status" to "pending"
            )
        )
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
