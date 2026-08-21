package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.model.Campaign
import com.rexo.marketplace.data.repository.CampaignRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.Date

/**
 * Campaign ViewModel
 * Manages campaign listings, applications, creation
 */
class CampaignViewModel(
    private val repository: CampaignRepository
) : ViewModel() {

    // UI State
    private val _uiState = MutableStateFlow(CampaignUiState())
    val uiState: StateFlow<CampaignUiState> = _uiState.asStateFlow()

    // Campaigns List
    private val _campaigns = MutableStateFlow<List<CampaignItem>>(emptyList())
    val campaigns: StateFlow<List<CampaignItem>> = _campaigns.asStateFlow()

    // Selected Campaign
    private val _selectedCampaign = MutableStateFlow<CampaignItem?>(null)
    val selectedCampaign: StateFlow<CampaignItem?> = _selectedCampaign.asStateFlow()

    // Filters
    private val _selectedCategory = MutableStateFlow("All")
    val selectedCategory: StateFlow<String> = _selectedCategory.asStateFlow()

    init {
        loadCampaigns()
    }

    fun loadCampaigns(category: String = "All") {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                val campaigns = repository.getCampaigns(category)
                _campaigns.value = campaigns
                _selectedCategory.value = category
                _uiState.update { it.copy(isLoading = false, error = null) }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(isLoading = false, error = e.message ?: "Failed to load campaigns") 
                }
            }
        }
    }

    fun selectCampaign(campaign: CampaignItem) {
        _selectedCampaign.value = campaign
    }

    fun applyToCampaign(campaignId: String, proposal: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true) }
            try {
                repository.applyToCampaign(campaignId, proposal)
                _uiState.update { 
                    it.copy(
                        isProcessing = false, 
                        showSuccess = true,
                        successMessage = "Application submitted successfully!"
                    ) 
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(isProcessing = false, error = e.message ?: "Application failed") 
                }
            }
        }
    }

    fun createCampaign(campaign: CreateCampaignRequest) {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true) }
            try {
                repository.createCampaign(campaign)
                _uiState.update { 
                    it.copy(
                        isProcessing = false, 
                        showSuccess = true,
                        successMessage = "Campaign created successfully!"
                    ) 
                }
                loadCampaigns()
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(isProcessing = false, error = e.message ?: "Failed to create campaign") 
                }
            }
        }
    }

    fun clearSuccess() {
        _uiState.update { it.copy(showSuccess = false, successMessage = null) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class CampaignUiState(
    val isLoading: Boolean = false,
    val isProcessing: Boolean = false,
    val error: String? = null,
    val showSuccess: Boolean = false,
    val successMessage: String? = null
)

data class CampaignItem(
    val id: String,
    val title: String,
    val description: String,
    val category: String,
    val platform: String,
    val budget: Double,
    val brandName: String,
    val brandLogo: String?,
    val deadline: Date,
    val applicants: Int,
    val status: String,
    val deliverables: List<String>
)

data class CreateCampaignRequest(
    val title: String,
    val description: String,
    val category: String,
    val platform: String,
    val budget: Double,
    val deadline: String,
    val deliverables: String,
    val requirements: String
)
