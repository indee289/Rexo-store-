package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.remote.SupabaseClient
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * User Repository
 * Fetches user profile, creator profile, and wallet data from Supabase.
 * No mock data fallbacks - returns null or throws on failure.
 */
class UserRepository {

    /**
     * Fetch user from Supabase 'users' table by ID.
     * Returns null if not found or on failure.
     */
    suspend fun getUser(userId: String): UserDto? = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("users").select {
                filter { eq("id", userId) }
            }.decodeSingle<UserDto>()
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Ensure a user profile row exists in the 'users' table.
     * If no row exists for the given userId, create one using auth metadata.
     * Uses upsert with onConflict to avoid race conditions on concurrent access.
     */
    suspend fun ensureUserProfile(userId: String): UserDto? = withContext(Dispatchers.IO) {
        // First try to fetch existing profile
        val existing = getUser(userId)
        if (existing != null) return@withContext existing

        // No row exists - upsert one from auth session metadata
        try {
            val authUser = SupabaseClient.auth.currentUserOrNull()
            val email = authUser?.email ?: ""
            val name = authUser?.userMetadata?.get("full_name")?.toString()?.removeSurrounding("\"")
                ?: authUser?.userMetadata?.get("name")?.toString()?.removeSurrounding("\"")
                ?: email.substringBefore("@")

            val newUser = UserInsertDto(
                id = userId,
                email = email,
                name = name,
                role = if (isAdminEmail(email)) "admin" else "creator"
            )

            SupabaseClient.client.from("users").upsert(newUser) {
                onConflict = "id"
            }

            // Fetch and return the newly created/existing row
            getUser(userId)
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Fetch user role from Supabase 'users' table.
     * Returns the role string ("creator", "brand", "admin") or null on failure.
     * Also checks by email for admin identification.
     */
    suspend fun getUserRole(userId: String): String? = withContext(Dispatchers.IO) {
        try {
            val user = SupabaseClient.client.from("users").select {
                filter { eq("id", userId) }
            }.decodeSingle<UserDto>()
            user.role
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Check if a user is an admin by their email address.
     * This is a secondary check - the primary check is via the role field in the users table.
     */
    fun isAdminEmail(email: String): Boolean {
        return email.lowercase() == ADMIN_EMAIL
    }

    companion object {
        const val ADMIN_EMAIL = "rexoagency.in@gmail.com"
    }

    /**
     * Fetch creator profile from Supabase 'creator_profiles' table by user_id.
     * Returns null if not found (user may not be a creator).
     */
    suspend fun getCreatorProfile(userId: String): CreatorProfileDto? = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("creator_profiles").select {
                filter { eq("user_id", userId) }
            }.decodeSingle<CreatorProfileDto>()
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Fetch wallet from Supabase 'wallets' table by user_id.
     * Returns null if not found.
     */
    suspend fun getWallet(userId: String): WalletDto? = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("wallets").select {
                filter { eq("user_id", userId) }
            }.decodeSingle<WalletDto>()
        } catch (e: Exception) {
            null
        }
    }
}

/**
 * DTO for inserting a new user row into the 'users' table.
 */
@kotlinx.serialization.Serializable
data class UserInsertDto(
    val id: String,
    val email: String,
    val name: String,
    val role: String = "creator"
)

/**
 * DTO matching the Supabase 'users' table schema.
 */
@kotlinx.serialization.Serializable
data class UserDto(
    val id: String,
    val email: String,
    val name: String,
    val handle: String? = null,
    val avatar: String? = null,
    val role: String = "creator",
    val is_verified: Boolean = false,
    val bio: String? = null,
    val created_at: String = ""
)

/**
 * DTO matching the Supabase 'creator_profiles' table schema.
 */
@kotlinx.serialization.Serializable
data class CreatorProfileDto(
    val user_id: String,
    val category: String? = "Lifestyle",
    val followers: Int = 0,
    val engagement_rate: Double = 0.0,
    val completed_campaigns: Int = 0,
    val rating: Double = 5.0,
    val instagram_handle: String? = null,
    val youtube_channel: String? = null
)

/**
 * DTO matching the Supabase 'wallets' table schema.
 */
@kotlinx.serialization.Serializable
data class WalletDto(
    val user_id: String,
    val available_balance: Double = 0.0,
    val total_earnings: Double = 0.0,
    val total_withdrawn: Double = 0.0
)
