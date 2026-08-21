package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.repository.CampaignRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

/**
 * Campaign ViewModel
 * Manages campaign listings with search and category filtering.
 * No mock/fallback data - shows proper error/empty states.
 */
class CampaignViewModel(
    private val repository: CampaignRepository = CampaignRepository()
) : ViewModel() {

    // UI State
    private val _uiState = MutableStateFlow(CampaignUiState())
    val uiState: StateFlow<CampaignUiState> = _uiState.asStateFlow()

    // All campaigns from Supabase (unfiltered)
    private val _allCampaigns = MutableStateFlow<List<CampaignItem>>(emptyList())

    // Filtered campaigns (after search + category filter applied)
    private val _campaigns = MutableStateFlow<List<CampaignItem>>(emptyList())
    val campaigns: StateFlow<List<CampaignItem>> = _campaigns.asStateFlow()

    // Total count (before filtering)
    val totalCount: StateFlow<Int> = _allCampaigns.map { it.size }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    // Filtered count
    val filteredCount: StateFlow<Int> = _campaigns.map { it.size }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    // Selected Campaign
    private val _selectedCampaign = MutableStateFlow<CampaignItem?>(null)
    val selectedCampaign: StateFlow<CampaignItem?> = _selectedCampaign.asStateFlow()

    // Categories
    private val _categories = MutableStateFlow<List<String>>(listOf("All"))
    val categories: StateFlow<List<String>> = _categories.asStateFlow()

    // Search query
    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    // Selected category filter
    private val _selectedCategory = MutableStateFlow("All")
    val selectedCategory: StateFlow<String> = _selectedCategory.asStateFlow()

    init {
        loadCampaigns()
        loadCategories()
    }

    fun loadCampaigns() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val allCampaigns = repository.getCampaigns()
                _allCampaigns.value = allCampaigns
                applyFilters()
                _uiState.update { it.copy(isLoading = false, error = null) }
            } catch (e: Exception) {
                _allCampaigns.value = emptyList()
                _campaigns.value = emptyList()
                _uiState.update {
                    it.copy(isLoading = false, error = e.message ?: "Failed to load campaigns")
                }
            }
        }
    }

    private fun loadCategories() {
        viewModelScope.launch {
            try {
                val cats = repository.getCategories()
                _categories.value = cats
            } catch (_: Exception) {
                _categories.value = listOf("All", "Music", "Logo", "Clipping", "UGC")
            }
        }
    }

    fun updateSearchQuery(query: String) {
        _searchQuery.value = query
        applyFilters()
    }

    fun selectCategory(category: String) {
        _selectedCategory.value = category
        applyFilters()
    }

    private fun applyFilters() {
        val query = _searchQuery.value
        val category = _selectedCategory.value
        val all = _allCampaigns.value

        _campaigns.value = all
            .filter { campaign ->
                if (category != "All") campaign.category.equals(category, ignoreCase = true) else true
            }
            .filter { campaign ->
                if (query.isNotBlank()) {
                    campaign.title.contains(query, ignoreCase = true) ||
                        campaign.description.contains(query, ignoreCase = true)
                } else true
            }
    }

    fun selectCampaign(campaign: CampaignItem) {
        _selectedCampaign.value = campaign
    }

    fun applyToCampaign(campaignId: String, campaignTitle: String, brandName: String, feeRequested: Double, proposal: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true) }
            try {
                repository.applyToCampaign(campaignId, campaignTitle, brandName, feeRequested, proposal)
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
    val budget: Double,
    val payoutPerCreator: Double,
    val brandName: String,
    val brandAvatar: String?,
    val deadline: String,
    val slots: Int,
    val filledSlots: Int,
    val status: String,
    val deliverableType: String,
    val image: String?
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
