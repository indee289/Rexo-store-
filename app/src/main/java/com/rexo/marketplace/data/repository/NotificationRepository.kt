package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.remote.SupabaseClient
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable

/**
 * Notification Repository
 * Fetches and manages notifications from Supabase 'notifications' table.
 */
class NotificationRepository {

    /**
     * Fetch notifications for the current user, ordered by created_at DESC.
     * Returns empty list if user is not authenticated or no notifications exist.
     */
    suspend fun getNotifications(): List<NotificationDto> = withContext(Dispatchers.IO) {
        val userId = SupabaseClient.auth.currentUserOrNull()?.id
            ?: return@withContext emptyList()

        try {
            val results = SupabaseClient.client.from("notifications")
                .select {
                    filter {
                        eq("user_id", userId)
                    }
                }
                .decodeList<NotificationDto>()

            results.sortedByDescending { it.created_at }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * Mark a notification as read by updating is_read to true.
     */
    suspend fun markAsRead(notificationId: String) = withContext(Dispatchers.IO) {
        SupabaseClient.client.from("notifications")
            .update(mapOf("is_read" to true)) {
                filter {
                    eq("id", notificationId)
                }
            }
    }

    /**
     * Mark all notifications as read for the current user.
     */
    suspend fun markAllAsRead() = withContext(Dispatchers.IO) {
        val userId = SupabaseClient.auth.currentUserOrNull()?.id
            ?: return@withContext

        SupabaseClient.client.from("notifications")
            .update(mapOf("is_read" to true)) {
                filter {
                    eq("user_id", userId)
                    eq("is_read", false)
                }
            }
    }
}

/**
 * DTO matching the Supabase 'notifications' table schema.
 */
@Serializable
data class NotificationDto(
    val id: String,
    val user_id: String,
    val title: String,
    val body: String = "",
    val type: String = "general",
    val payload: String? = null,
    val is_read: Boolean = false,
    val delivery_status: String? = null,
    val created_at: String? = null
)
