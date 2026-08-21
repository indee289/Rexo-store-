package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.data.repository.AuthRepository
import com.rexo.marketplace.data.repository.CreatorProfileDto
import com.rexo.marketplace.data.repository.UserDto
import com.rexo.marketplace.data.repository.UserRepository
import com.rexo.marketplace.data.repository.WalletDto
import com.rexo.marketplace.utils.ErrorUtils
import io.github.jan.supabase.auth.auth
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Profile ViewModel
 * Loads user profile, creator stats, and wallet data from Supabase.
 * Handles sign-out functionality.
 */
class ProfileViewModel : ViewModel() {

    private val userRepository = UserRepository()
    private val authRepository = AuthRepository()

    // Profile state
    private val _profileState = MutableStateFlow<ProfileState>(ProfileState.Loading)
    val profileState: StateFlow<ProfileState> = _profileState.asStateFlow()

    // Sign-out event
    private val _signedOut = MutableStateFlow(false)
    val signedOut: StateFlow<Boolean> = _signedOut.asStateFlow()

    init {
        loadProfile()
    }

    /**
     * Load user profile from Supabase tables.
     * Fetches from 'users', 'creator_profiles', and 'wallets'.
     */
    fun loadProfile() {
        viewModelScope.launch {
            _profileState.value = ProfileState.Loading

            val userId = SupabaseClient.auth.currentUserOrNull()?.id
            if (userId == null) {
                _profileState.value = ProfileState.Error("Not authenticated")
                return@launch
            }

            try {
                // Ensure user profile exists (creates one if not found)
                val user = userRepository.ensureUserProfile(userId)
                if (user == null) {
                    _profileState.value = ProfileState.Empty
                    return@launch
                }

                val creatorProfile = userRepository.getCreatorProfile(userId)
                val wallet = userRepository.getWallet(userId)

                _profileState.value = ProfileState.Loaded(
                    user = user,
                    creatorProfile = creatorProfile,
                    wallet = wallet
                )
            } catch (e: Exception) {
                _profileState.value = ProfileState.Error(
                    ErrorUtils.sanitizeErrorMessage(e.message)
                )
            }
        }
    }

    /**
     * Sign out the current user.
     */
    fun signOut() {
        viewModelScope.launch {
            val result = authRepository.signOut()
            result.onSuccess {
                _signedOut.value = true
            }.onFailure {
                // Even on error, attempt to navigate away
                _signedOut.value = true
            }
        }
    }
}

/**
 * Profile UI State
 */
sealed class ProfileState {
    object Loading : ProfileState()
    data class Loaded(
        val user: UserDto,
        val creatorProfile: CreatorProfileDto?,
        val wallet: WalletDto?
    ) : ProfileState()
    data class Error(val message: String) : ProfileState()
    object Empty : ProfileState()
}
