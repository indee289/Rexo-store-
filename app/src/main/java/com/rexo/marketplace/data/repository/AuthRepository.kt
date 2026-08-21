package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.remote.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.user.UserInfo
import io.github.jan.supabase.exceptions.RestException
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Authentication Repository
 * Handles all authentication operations using Supabase Auth
 */
class AuthRepository {

    private val auth = SupabaseClient.auth

    /**
     * Load session on app start.
     * Supabase client has autoLoadFromStorage = true, so the session
     * is restored automatically. This method attempts to refresh it
     * and returns the current user if a valid session exists.
     */
    suspend fun loadSession(): Result<UserInfo?> {
        return try {
            // Attempt to refresh the current session to verify it's still valid
            auth.refreshCurrentSession()
            val user = auth.currentUserOrNull()
            Result.success(user)
        } catch (e: Exception) {
            // If refresh fails, session is invalid or expired
            Result.success(null)
        }
    }

    /**
     * Sign up with email and password
     */
    suspend fun signUp(
        email: String,
        password: String,
        fullName: String? = null,
        phone: String? = null
    ): Result<UserInfo> {
        return try {
            auth.signUpWith(Email) {
                this.email = email
                this.password = password

                // Add user metadata
                data = buildJsonObject {
                    fullName?.let { put("full_name", it) }
                    phone?.let { put("phone", it) }
                    put("created_at", System.currentTimeMillis())
                }
            }

            // After sign up, get the current user
            val user = auth.currentUserOrNull()
                ?: return Result.failure(Exception("Sign up succeeded but user is null"))
            Result.success(user)
        } catch (e: RestException) {
            Result.failure(e)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Sign in with email and password
     */
    suspend fun signIn(
        email: String,
        password: String
    ): Result<UserInfo> {
        return try {
            auth.signInWith(Email) {
                this.email = email
                this.password = password
            }

            // After sign in, get the current user
            val user = auth.currentUserOrNull()
                ?: return Result.failure(Exception("Sign in succeeded but user is null"))
            Result.success(user)
        } catch (e: RestException) {
            Result.failure(e)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Sign out current user
     */
    suspend fun signOut(): Result<Unit> {
        return try {
            auth.signOut()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Check if user is logged in (synchronous check)
     */
    fun isLoggedIn(): Boolean {
        return auth.currentSessionOrNull() != null
    }

    /**
     * Get current user (synchronous)
     */
    fun getCurrentUser(): UserInfo? {
        return auth.currentUserOrNull()
    }

    /**
     * Send password reset email
     */
    suspend fun sendPasswordResetEmail(email: String): Result<Unit> {
        return try {
            auth.resetPasswordForEmail(email)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Update password
     */
    suspend fun updatePassword(newPassword: String): Result<Unit> {
        return try {
            auth.updateUser {
                password = newPassword
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Refresh session
     */
    suspend fun refreshSession(): Result<UserInfo> {
        return try {
            auth.refreshCurrentSession()
            val user = auth.currentUserOrNull()
                ?: return Result.failure(Exception("Session refreshed but user is null"))
            Result.success(user)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
