package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.repository.ChatRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

/**
 * Chat ViewModel
 * Manages conversations and messaging.
 * Default constructor with repository defaulting to ChatRepository().
 */
class ChatViewModel(
    private val repository: ChatRepository = ChatRepository()
) : ViewModel() {

    // UI State
    private val _uiState = MutableStateFlow(ChatUiState())
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    // Conversations list
    private val _conversations = MutableStateFlow<List<ConversationData>>(emptyList())
    val conversations: StateFlow<List<ConversationData>> = _conversations.asStateFlow()

    // Messages in current conversation
    private val _messages = MutableStateFlow<List<ChatMessageData>>(emptyList())
    val messages: StateFlow<List<ChatMessageData>> = _messages.asStateFlow()

    // Current recipient ID
    private val _currentRecipientId = MutableStateFlow<String?>(null)
    val currentRecipientId: StateFlow<String?> = _currentRecipientId.asStateFlow()

    init {
        loadConversations()
    }

    fun loadConversations() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                _conversations.value = repository.getConversations()
                _uiState.update { it.copy(isLoading = false) }
            } catch (e: Exception) {
                _conversations.value = emptyList()
                _uiState.update {
                    it.copy(isLoading = false, error = e.message ?: "Failed to load conversations")
                }
            }
        }
    }

    fun loadMessages(recipientId: String) {
        _currentRecipientId.value = recipientId
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                _messages.value = repository.getMessages(recipientId)
                _uiState.update { it.copy(isLoading = false) }
            } catch (e: Exception) {
                _messages.value = emptyList()
                _uiState.update {
                    it.copy(isLoading = false, error = e.message ?: "Failed to load messages")
                }
            }
        }
    }

    fun sendMessage(text: String) {
        val recipientId = _currentRecipientId.value ?: return
        if (text.isBlank()) return

        viewModelScope.launch {
            try {
                // Optimistic update
                val optimisticMessage = ChatMessageData(
                    id = "temp_${System.currentTimeMillis()}",
                    recipientId = recipientId,
                    text = text,
                    isCurrentUser = true,
                    timestamp = "",
                    isRead = false
                )
                _messages.update { it + optimisticMessage }

                // Send to Supabase
                repository.sendMessage(recipientId, text)

                // Reload messages to get server-assigned ID and timestamp
                _messages.value = repository.getMessages(recipientId)
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message ?: "Failed to send message") }
            }
        }
    }

    fun markAsRead(messageId: String) {
        viewModelScope.launch {
            try {
                repository.markAsRead(messageId)
                _messages.update { messages ->
                    messages.map {
                        if (it.id == messageId) it.copy(isRead = true) else it
                    }
                }
            } catch (_: Exception) {
                // Silent fail
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class ChatUiState(
    val isLoading: Boolean = false,
    val error: String? = null
)

data class ChatMessageData(
    val id: String,
    val recipientId: String,
    val text: String,
    val isCurrentUser: Boolean,
    val timestamp: String,
    val isRead: Boolean
)

data class ConversationData(
    val id: String,
    val otherUserId: String,
    val otherUserName: String,
    val otherUserAvatar: String?,
    val lastMessage: String,
    val lastMessageTime: String,
    val unreadCount: Int,
    val isOnline: Boolean
)
