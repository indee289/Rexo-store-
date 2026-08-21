package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.ui.viewmodel.*
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable

/**
 * Chat Repository
 * Handles messaging with Supabase.
 * Uses SupabaseClient singleton directly (no constructor params).
 */
class ChatRepository {

    private fun getCurrentUserId(): String? {
        return SupabaseClient.auth.currentUserOrNull()?.id
    }

    /**
     * Fetch conversations by querying the messages table and grouping by
     * the other participant. Returns a list of conversations with last message info.
     */
    suspend fun getConversations(): List<ConversationData> = withContext(Dispatchers.IO) {
        val userId = getCurrentUserId() ?: return@withContext emptyList()

        // Fetch all messages involving current user
        val sentMessages = SupabaseClient.client.from("messages").select {
            filter { eq("sender_id", userId) }
        }.decodeList<MessageDto>()

        val receivedMessages = SupabaseClient.client.from("messages").select {
            filter { eq("receiver_id", userId) }
        }.decodeList<MessageDto>()

        val allMessages = (sentMessages + receivedMessages).sortedByDescending { it.created_at }

        // Group by the other user
        val conversationMap = mutableMapOf<String, MutableList<MessageDto>>()
        for (msg in allMessages) {
            val otherUserId = if (msg.sender_id == userId) msg.receiver_id else msg.sender_id
            conversationMap.getOrPut(otherUserId) { mutableListOf() }.add(msg)
        }

        conversationMap.map { (otherUserId, messages) ->
            val lastMsg = messages.first()
            val unread = messages.count { it.receiver_id == userId && !it.read }
            ConversationData(
                id = otherUserId,
                otherUserId = otherUserId,
                otherUserName = otherUserId.take(8),
                otherUserAvatar = null,
                lastMessage = lastMsg.content,
                lastMessageTime = lastMsg.created_at,
                unreadCount = unread,
                isOnline = false
            )
        }
    }

    /**
     * Fetch messages between current user and a specific recipient.
     */
    suspend fun getMessages(recipientId: String): List<ChatMessageData> = withContext(Dispatchers.IO) {
        val userId = getCurrentUserId() ?: return@withContext emptyList()

        // Messages sent by current user to recipient
        val sent = SupabaseClient.client.from("messages").select {
            filter {
                eq("sender_id", userId)
                eq("receiver_id", recipientId)
            }
        }.decodeList<MessageDto>()

        // Messages received from recipient
        val received = SupabaseClient.client.from("messages").select {
            filter {
                eq("sender_id", recipientId)
                eq("receiver_id", userId)
            }
        }.decodeList<MessageDto>()

        (sent + received)
            .sortedBy { it.created_at }
            .map { dto ->
                ChatMessageData(
                    id = dto.id,
                    recipientId = if (dto.sender_id == userId) dto.receiver_id else dto.sender_id,
                    text = dto.content,
                    isCurrentUser = dto.sender_id == userId,
                    timestamp = dto.created_at,
                    isRead = dto.read
                )
            }
    }

    /**
     * Send a message to a recipient.
     */
    suspend fun sendMessage(recipientId: String, content: String) = withContext(Dispatchers.IO) {
        val userId = getCurrentUserId()
            ?: throw Exception("Please sign in to send messages")

        val messageInsert = MessageInsertDto(
            sender_id = userId,
            receiver_id = recipientId,
            content = content,
            read = false
        )

        SupabaseClient.client.from("messages").insert(messageInsert)
    }

    /**
     * Mark a message as read.
     */
    suspend fun markAsRead(messageId: String) = withContext(Dispatchers.IO) {
        try {
            SupabaseClient.client.from("messages").update(
                mapOf("read" to true)
            ) {
                filter { eq("id", messageId) }
            }
        } catch (_: Exception) {
            // Silent fail
        }
    }
}

/**
 * DTO matching Supabase 'messages' table.
 */
@Serializable
data class MessageDto(
    val id: String,
    val sender_id: String,
    val receiver_id: String,
    val content: String,
    val created_at: String = "",
    val read: Boolean = false
)

/**
 * DTO for inserting a message into 'messages' table.
 */
@Serializable
data class MessageInsertDto(
    val sender_id: String,
    val receiver_id: String,
    val content: String,
    val read: Boolean = false
)
