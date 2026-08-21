package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.repository.NotificationDto
import com.rexo.marketplace.data.repository.NotificationRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Notification ViewModel
 * Manages notification list with loading/error/empty states.
 */
class NotificationViewModel(
    private val repository: NotificationRepository = NotificationRepository()
) : ViewModel() {

    private val _uiState = MutableStateFlow(NotificationUiState())
    val uiState: StateFlow<NotificationUiState> = _uiState.asStateFlow()

    private val _notifications = MutableStateFlow<List<NotificationDto>>(emptyList())
    val notifications: StateFlow<List<NotificationDto>> = _notifications.asStateFlow()

    val unreadCount: StateFlow<Int>
        get() = MutableStateFlow(_notifications.value.count { !it.is_read }).also { flow ->
            viewModelScope.launch {
                _notifications.collect { list ->
                    (flow as MutableStateFlow).value = list.count { !it.is_read }
                }
            }
        }

    init {
        loadNotifications()
    }

    fun loadNotifications() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val result = repository.getNotifications()
                _notifications.value = result
                _uiState.update { it.copy(isLoading = false, error = null) }
            } catch (e: Exception) {
                _notifications.value = emptyList()
                // Never show "User not authenticated" - just show empty state
                val errorMsg = e.message ?: ""
                if (errorMsg.contains("authenticated", ignoreCase = true) ||
                    errorMsg.contains("auth", ignoreCase = true)) {
                    _uiState.update { it.copy(isLoading = false, error = null) }
                } else {
                    _uiState.update {
                        it.copy(isLoading = false, error = "Could not load notifications")
                    }
                }
            }
        }
    }

    fun markAsRead(notificationId: String) {
        viewModelScope.launch {
            try {
                repository.markAsRead(notificationId)
                // Update local state
                _notifications.update { list ->
                    list.map { if (it.id == notificationId) it.copy(is_read = true) else it }
                }
            } catch (_: Exception) {
                // Silently fail for mark as read
            }
        }
    }

    fun markAllAsRead() {
        viewModelScope.launch {
            try {
                repository.markAllAsRead()
                _notifications.update { list ->
                    list.map { it.copy(is_read = true) }
                }
            } catch (_: Exception) {
                // Silently fail
            }
        }
    }
}

data class NotificationUiState(
    val isLoading: Boolean = false,
    val error: String? = null
)
