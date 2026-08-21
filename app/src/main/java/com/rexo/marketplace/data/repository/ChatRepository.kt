package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.ui.viewmodel.*
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.realtime.RealtimeChannel
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.realtime
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Date

/**
 * Chat Repository
 * Handles real-time messaging with Supabase Realtime
 */
class ChatRepository(
    private val supabaseClient: SupabaseClient
) {
    private var realtimeChannel: RealtimeChannel? = null

    suspend fun getConversations(): List<ConversationData> = withContext(Dispatchers.IO) {
        try {
            val response = supabaseClient.client
                .from("conversations")
                .select()
                .decodeList<ConversationDto>()
            
            response.map { it.toConversationData() }
        } catch (e: Exception) {
            // Mock data
            emptyList()
        }
    }

    suspend fun getMessages(conversationId: String): List<ChatMessageData> = withContext(Dispatchers.IO) {
        try {
            val response = supabaseClient.client
                .from("messages")
                .select()
                .eq("conversation_id", conversationId)
                .order("created_at", ascending = true)
                .decodeList<MessageDto>()
            
            response.map { it.toChatMessage() }
        } catch (e: Exception) {
            // Mock data
            emptyList()
        }
    }

    suspend fun subscribeToMessages(
        conversationId: String,
        onNewMessage: (ChatMessageData) -> Unit
    ) = withContext(Dispatchers.IO) {
        try {
            realtimeChannel = supabaseClient.client.realtime.channel("messages_$conversationId")
            
            // Subscribe to INSERT events
            realtimeChannel?.on<MessageDto>(
                event = "INSERT",
                filter = "conversation_id=eq.$conversationId"
            ) { message ->
                onNewMessage(message.toChatMessage())
            }?.subscribe()
        } catch (e: Exception) {
            // Handle subscription error
        }
    }

    suspend fun sendMessage(conversationId: String, text: String) = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("messages").insert(
                mapOf(
                    "conversation_id" to conversationId,
                    "text" to text,
                    "is_read" to false
                )
            )
        } catch (e: Exception) {
            throw Exception("Failed to send message: ${e.message}")
        }
    }

    suspend fun markAsRead(messageId: String) = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("messages").update(
                mapOf("is_read" to true)
            ) {
                filter { eq("id", messageId) }
            }
        } catch (e: Exception) {
            // Silent fail
        }
    }

    suspend fun sendTypingIndicator(conversationId: String, isTyping: Boolean) = withContext(Dispatchers.IO) {
        try {
            // Send typing status to Supabase presence
            realtimeChannel?.track(mapOf("typing" to isTyping))
        } catch (e: Exception) {
            // Silent fail
        }
    }

    fun unsubscribe(conversationId: String) {
        realtimeChannel?.unsubscribe()
        realtimeChannel = null
    }
}

@kotlinx.serialization.Serializable
data class ConversationDto(
    val id: String,
    val other_user_id: String,
    val other_user_name: String,
    val other_user_avatar: String? = null,
    val last_message: String,
    val last_message_time: String,
    val unread_count: Int = 0,
    val is_online: Boolean = false
) {
    fun toConversationData() = ConversationData(
        id, other_user_id, other_user_name, other_user_avatar,
        last_message, Date(), unread_count, is_online
    )
}

@kotlinx.serialization.Serializable
data class MessageDto(
    val id: String,
    val conversation_id: String,
    val text: String,
    val sender_id: String,
    val is_read: Boolean,
    val created_at: String,
    val attachment_url: String? = null
) {
    fun toChatMessage() = ChatMessageData(
        id, conversation_id, text, 
        false, // Will be set based on current user
        Date(), is_read, attachment_url
    )
}
