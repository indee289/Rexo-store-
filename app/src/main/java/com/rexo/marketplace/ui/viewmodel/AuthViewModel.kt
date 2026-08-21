package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.repository.AuthRepository
import io.github.jan.supabase.auth.user.UserInfo
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Authentication ViewModel
 * Manages authentication state and operations
 */
class AuthViewModel : ViewModel() {
    
    private val repository = AuthRepository()
    
    // UI State
    private val _uiState = MutableStateFlow<AuthUiState>(AuthUiState.Idle)
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()
    
    // Current User
    private val _currentUser = MutableStateFlow<UserInfo?>(null)
    val currentUser: StateFlow<UserInfo?> = _currentUser.asStateFlow()
    
    init {
        checkAuthStatus()
    }
    
    /**
     * Check if user is already logged in
     */
    private fun checkAuthStatus() {
        viewModelScope.launch {
            val user = repository.getCurrentUser()
            _currentUser.value = user
            if (user != null) {
                _uiState.value = AuthUiState.Authenticated(user)
            }
        }
    }
    
    /**
     * Sign up with email and password
     */
    fun signUp(email: String, password: String, fullName: String, phone: String) {
        viewModelScope.launch {
            _uiState.value = AuthUiState.Loading
            
            val result = repository.signUp(
                email = email,
                password = password,
                fullName = fullName,
                phone = phone
            )
            
            result.onSuccess { userInfo ->
                _currentUser.value = userInfo
                _uiState.value = AuthUiState.Authenticated(userInfo)
            }.onFailure { error ->
                _uiState.value = AuthUiState.Error(
                    error.message ?: "Sign up failed. Please try again."
                )
            }
        }
    }
    
    /**
     * Sign in with email and password
     */
    fun signIn(email: String, password: String) {
        viewModelScope.launch {
            _uiState.value = AuthUiState.Loading
            
            val result = repository.signIn(
                email = email,
                password = password
            )
            
            result.onSuccess { userInfo ->
                _currentUser.value = userInfo
                _uiState.value = AuthUiState.Authenticated(userInfo)
            }.onFailure { error ->
                _uiState.value = AuthUiState.Error(
                    error.message ?: "Sign in failed. Please check your credentials."
                )
            }
        }
    }
    
    /**
     * Sign out current user
     */
    fun signOut() {
        viewModelScope.launch {
            _uiState.value = AuthUiState.Loading
            
            val result = repository.signOut()
            
            result.onSuccess {
                _currentUser.value = null
                _uiState.value = AuthUiState.Idle
            }.onFailure { error ->
                _uiState.value = AuthUiState.Error(
                    error.message ?: "Sign out failed. Please try again."
                )
            }
        }
    }
    
    /**
     * Send password reset email
     */
    fun sendPasswordResetEmail(email: String) {
        viewModelScope.launch {
            _uiState.value = AuthUiState.Loading
            
            val result = repository.sendPasswordResetEmail(email)
            
            result.onSuccess {
                _uiState.value = AuthUiState.PasswordResetSent
            }.onFailure { error ->
                _uiState.value = AuthUiState.Error(
                    error.message ?: "Failed to send reset email. Please try again."
                )
            }
        }
    }
    
    /**
     * Reset UI state to idle
     */
    fun resetState() {
        _uiState.value = AuthUiState.Idle
    }
    
    /**
     * Validate email format
     */
    fun isValidEmail(email: String): Boolean {
        return android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()
    }
    
    /**
     * Validate password strength
     * At least 8 characters
     */
    fun isValidPassword(password: String): Boolean {
        return password.length >= 8
    }
}

/**
 * Authentication UI State
 */
sealed class AuthUiState {
    object Idle : AuthUiState()
    object Loading : AuthUiState()
    data class Authenticated(val user: UserInfo) : AuthUiState()
    data class Error(val message: String) : AuthUiState()
    object PasswordResetSent : AuthUiState()
}
