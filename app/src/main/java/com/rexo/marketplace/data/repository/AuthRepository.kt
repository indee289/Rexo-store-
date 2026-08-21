package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.remote.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.user.UserInfo
import io.github.jan.supabase.exceptions.RestException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Authentication Repository
 * Handles all authentication operations using Supabase Auth
 */
class AuthRepository {
    
    private val auth = SupabaseClient.auth
    
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
     * Get current session
     */
    fun getCurrentSession(): Flow<UserInfo?> = flow {
        try {
            val session = auth.currentSessionOrNull()
            emit(session?.user)
        } catch (e: Exception) {
            emit(null)
        }
    }
    
    /**
     * Check if user is logged in
     */
    fun isLoggedIn(): Boolean {
        return auth.currentSessionOrNull() != null
    }
    
    /**
     * Get current user
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
