package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.local.CampaignDao
import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.ui.viewmodel.*
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Date

/**
 * Campaign Repository
 * Handles campaign operations with Supabase and local Room
 */
class CampaignRepository(
    private val campaignDao: CampaignDao,
    private val supabaseClient: SupabaseClient
) {
    suspend fun getCampaigns(category: String = "All"): List<CampaignItem> = withContext(Dispatchers.IO) {
        try {
            val query = supabaseClient.client.from("campaigns").select()
            
            val response = if (category != "All") {
                query.decodeList<CampaignDto>().filter { it.category == category }
            } else {
                query.decodeList<CampaignDto>()
            }
            
            response.map { it.toCampaignItem() }
        } catch (e: Exception) {
            // Mock data for demo
            listOf(
                CampaignItem(
                    "1",
                    "Tech Product Launch Campaign",
                    "Looking for tech reviewers to promote our new smartphone",
                    "Tech",
                    "Instagram",
                    5000.0,
                    "Brand XYZ",
                    null,
                    Date(),
                    15,
                    "active",
                    listOf("3 Instagram Posts", "5 Stories", "1 Reel")
                ),
                CampaignItem(
                    "2",
                    "Fashion Summer Collection",
                    "Promote our summer collection with your unique style",
                    "Fashion",
                    "Instagram",
                    3500.0,
                    "Fashion Co",
                    null,
                    Date(),
                    8,
                    "active",
                    listOf("2 Posts", "Product Photos")
                )
            )
        }
    }

    suspend fun applyToCampaign(campaignId: String, proposal: String) = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("campaign_applications").insert(
                mapOf(
                    "campaign_id" to campaignId,
                    "proposal" to proposal,
                    "status" to "pending"
                )
            )
        } catch (e: Exception) {
            throw Exception("Application failed: ${e.message}")
        }
    }

    suspend fun createCampaign(request: CreateCampaignRequest) = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("campaigns").insert(
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
        } catch (e: Exception) {
            throw Exception("Failed to create campaign: ${e.message}")
        }
    }
}

@kotlinx.serialization.Serializable
data class CampaignDto(
    val id: String,
    val title: String,
    val description: String,
    val category: String,
    val platform: String,
    val budget: Double,
    val brand_name: String,
    val brand_logo: String? = null,
    val deadline: String,
    val applicants: Int = 0,
    val status: String,
    val deliverables: String
) {
    fun toCampaignItem() = CampaignItem(
        id, title, description, category, platform, budget,
        brand_name, brand_logo, Date(), applicants, status,
        deliverables.split(",").map { it.trim() }
    )
}
