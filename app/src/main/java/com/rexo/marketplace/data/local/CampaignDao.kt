package com.rexo.marketplace.data.local

import androidx.room.*
import com.rexo.marketplace.data.model.Campaign
import com.rexo.marketplace.data.model.CampaignApplication
import kotlinx.coroutines.flow.Flow

/**
 * Campaign Data Access Object
 */
@Dao
interface CampaignDao {
    
    // Campaigns
    @Query("SELECT * FROM campaigns WHERE status = 'ACTIVE' ORDER BY createdAt DESC")
    fun getActiveCampaignsFlow(): Flow<List<Campaign>>
    
    @Query("SELECT * FROM campaigns WHERE id = :campaignId")
    suspend fun getCampaignById(campaignId: String): Campaign?
    
    @Query("SELECT * FROM campaigns WHERE brandId = :brandId")
    fun getCampaignsByBrandFlow(brandId: String): Flow<List<Campaign>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCampaign(campaign: Campaign)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCampaigns(campaigns: List<Campaign>)
    
    @Update
    suspend fun updateCampaign(campaign: Campaign)
    
    @Delete
    suspend fun deleteCampaign(campaign: Campaign)
    
    // Applications
    @Query("SELECT * FROM campaign_applications WHERE creatorId = :creatorId ORDER BY appliedAt DESC")
    fun getApplicationsByCreatorFlow(creatorId: String): Flow<List<CampaignApplication>>
    
    @Query("SELECT * FROM campaign_applications WHERE campaignId = :campaignId")
    fun getApplicationsByCampaignFlow(campaignId: String): Flow<List<CampaignApplication>>
    
    @Query("SELECT * FROM campaign_applications WHERE id = :applicationId")
    suspend fun getApplicationById(applicationId: String): CampaignApplication?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertApplication(application: CampaignApplication)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertApplications(applications: List<CampaignApplication>)
    
    @Update
    suspend fun updateApplication(application: CampaignApplication)
    
    @Query("DELETE FROM campaign_applications")
    suspend fun deleteAllApplications()
}
