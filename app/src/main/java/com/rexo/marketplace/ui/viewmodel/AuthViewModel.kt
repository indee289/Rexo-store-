package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.repository.AuthRepository
import com.rexo.marketplace.data.repository.UserRepository
import io.github.jan.supabase.auth.user.UserInfo
import io.github.jan.supabase.exceptions.RestException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Authentication ViewModel
 * Manages authentication state and operations.
 * Also checks user role for admin access control.
 */
class AuthViewModel : ViewModel() {

    private val repository = AuthRepository()
    private val userRepository = UserRepository()

    // UI State
    private val _uiState = MutableStateFlow<AuthUiState>(AuthUiState.Loading)
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    // Current User
    private val _currentUser = MutableStateFlow<UserInfo?>(null)
    val currentUser: StateFlow<UserInfo?> = _currentUser.asStateFlow()

    // Admin role state - true if the authenticated user has role = "admin"
    private val _isAdmin = MutableStateFlow(false)
    val isAdmin: StateFlow<Boolean> = _isAdmin.asStateFlow()

    init {
        checkAuthStatus()
    }

    /**
     * Check if user is already logged in via stored session.
     * On app start, attempt to restore the session from storage.
     * Also checks if user has admin role.
     */
    private fun checkAuthStatus() {
        viewModelScope.launch {
            _uiState.value = AuthUiState.Loading
            val result = repository.loadSession()
            result.onSuccess { user ->
                _currentUser.value = user
                if (user != null) {
                    _uiState.value = AuthUiState.Authenticated(user)
                    checkAdminRole(user)
                } else {
                    _isAdmin.value = false
                    _uiState.value = AuthUiState.Idle
                }
            }.onFailure {
                _isAdmin.value = false
                _uiState.value = AuthUiState.Idle
            }
        }
    }

    /**
     * Check if the authenticated user has admin role.
     * Checks both the Supabase users table role field and the email.
     */
    private suspend fun checkAdminRole(user: UserInfo) {
        try {
            // First check by role in users table
            val role = userRepository.getUserRole(user.id)
            if (role == "admin") {
                _isAdmin.value = true
                return
            }

            // Secondary check: verify by known admin email
            val email = user.email
            if (email != null && userRepository.isAdminEmail(email)) {
                _isAdmin.value = true
                return
            }

            _isAdmin.value = false
        } catch (e: Exception) {
            // On failure, check email as fallback
            val email = user.email
            _isAdmin.value = email != null && userRepository.isAdminEmail(email)
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
                checkAdminRole(userInfo)
            }.onFailure { error ->
                _isAdmin.value = false
                _uiState.value = AuthUiState.Error(mapErrorMessage(error))
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
                checkAdminRole(userInfo)
            }.onFailure { error ->
                _isAdmin.value = false
                _uiState.value = AuthUiState.Error(mapErrorMessage(error))
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
                _isAdmin.value = false
                _uiState.value = AuthUiState.Idle
            }.onFailure { error ->
                _isAdmin.value = false
                _uiState.value = AuthUiState.Error(mapErrorMessage(error))
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
                _uiState.value = AuthUiState.Error(mapErrorMessage(error))
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

    /**
     * Map Supabase errors to user-friendly messages.
     * Never expose Supabase URLs, technical details, or raw exception messages.
     */
    private fun mapErrorMessage(error: Throwable): String {
        val message = error.message?.lowercase() ?: ""

        return when {
            // Network / connection issues
            message.contains("unable to resolve host") ||
                message.contains("timeout") ||
                message.contains("connect") ||
                message.contains("network") ||
                message.contains("unreachable") -> {
                "Unable to connect. Please check your internet connection."
            }
            // Invalid credentials
            message.contains("invalid login credentials") ||
                message.contains("invalid email or password") ||
                message.contains("invalid_credentials") -> {
                "Invalid email or password. Please try again."
            }
            // Email already registered
            message.contains("already registered") ||
                message.contains("already been registered") ||
                message.contains("user already exists") -> {
                "An account with this email already exists. Please sign in instead."
            }
            // Weak password
            message.contains("password") && message.contains("short") ||
                message.contains("password") && message.contains("weak") -> {
                "Password is too short. Please use at least 8 characters."
            }
            // Invalid email
            message.contains("invalid email") ||
                message.contains("not a valid email") -> {
                "Please enter a valid email address."
            }
            // Rate limited
            message.contains("rate limit") ||
                message.contains("too many requests") -> {
                "Too many attempts. Please wait a moment and try again."
            }
            // Email not confirmed
            message.contains("email not confirmed") -> {
                "Please check your email and confirm your account before signing in."
            }
            // RestException - generic Supabase REST error
            error is RestException -> {
                "Something went wrong. Please try again."
            }
            // Fallback - never expose raw error text
            else -> {
                "Something went wrong. Please try again."
            }
        }
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
