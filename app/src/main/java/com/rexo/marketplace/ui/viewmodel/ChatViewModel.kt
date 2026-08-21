package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.repository.ChatRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.Date

/**
 * Chat ViewModel
 * Manages real-time messaging
 */
class ChatViewModel(
    private val repository: ChatRepository
) : ViewModel() {

    // UI State
    private val _uiState = MutableStateFlow(ChatUiState())
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    // Messages
    private val _messages = MutableStateFlow<List<ChatMessageData>>(emptyList())
    val messages: StateFlow<List<ChatMessageData>> = _messages.asStateFlow()

    // Conversations
    private val _conversations = MutableStateFlow<List<ConversationData>>(emptyList())
    val conversations: StateFlow<List<ConversationData>> = _conversations.asStateFlow()

    // Current conversation
    private val _currentConversationId = MutableStateFlow<String?>(null)
    val currentConversationId: StateFlow<String?> = _currentConversationId.asStateFlow()

    // Typing indicator
    private val _isOtherUserTyping = MutableStateFlow(false)
    val isOtherUserTyping: StateFlow<Boolean> = _isOtherUserTyping.asStateFlow()

    fun loadConversations() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                _conversations.value = repository.getConversations()
                _uiState.update { it.copy(isLoading = false) }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(isLoading = false, error = e.message) 
                }
            }
        }
    }

    fun loadMessages(conversationId: String) {
        viewModelScope.launch {
            _currentConversationId.value = conversationId
            _uiState.update { it.copy(isLoading = true) }
            try {
                _messages.value = repository.getMessages(conversationId)
                
                // Subscribe to real-time updates
                repository.subscribeToMessages(conversationId) { newMessage ->
                    _messages.update { it + newMessage }
                }
                
                _uiState.update { it.copy(isLoading = false) }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(isLoading = false, error = e.message) 
                }
            }
        }
    }

    fun sendMessage(text: String) {
        val conversationId = _currentConversationId.value ?: return
        
        viewModelScope.launch {
            try {
                val message = ChatMessageData(
                    id = java.util.UUID.randomUUID().toString(),
                    conversationId = conversationId,
                    text = text,
                    isCurrentUser = true,
                    timestamp = Date(),
                    isRead = false
                )
                
                // Optimistic update
                _messages.update { it + message }
                
                // Send to server
                repository.sendMessage(conversationId, text)
                
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
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
            } catch (e: Exception) {
                // Silent fail
            }
        }
    }

    fun sendTypingIndicator(isTyping: Boolean) {
        val conversationId = _currentConversationId.value ?: return
        viewModelScope.launch {
            try {
                repository.sendTypingIndicator(conversationId, isTyping)
            } catch (e: Exception) {
                // Silent fail
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    override fun onCleared() {
        super.onCleared()
        // Unsubscribe from real-time
        _currentConversationId.value?.let { repository.unsubscribe(it) }
    }
}

data class ChatUiState(
    val isLoading: Boolean = false,
    val error: String? = null
)

data class ChatMessageData(
    val id: String,
    val conversationId: String,
    val text: String,
    val isCurrentUser: Boolean,
    val timestamp: Date,
    val isRead: Boolean,
    val attachmentUrl: String? = null
)

data class ConversationData(
    val id: String,
    val otherUserId: String,
    val otherUserName: String,
    val otherUserAvatar: String?,
    val lastMessage: String,
    val lastMessageTime: Date,
    val unreadCount: Int,
    val isOnline: Boolean
)
