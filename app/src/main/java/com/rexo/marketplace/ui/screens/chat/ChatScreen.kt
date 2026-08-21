package com.rexo.marketplace.ui.screens.chat

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme
import java.text.SimpleDateFormat
import java.util.*

/**
 * Chat Screen
 * Features:
 * - Real-time messaging
 * - Message history
 * - File attachments
 * - Read receipts
 * - Typing indicators
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
    conversationId: String = "1",
    otherUserName: String = "Brand XYZ",
    onNavigateBack: () -> Unit = {}
) {
    var messageText by remember { mutableStateOf("") }
    val listState = rememberLazyListState()
    
    val messages = remember {
        mutableStateListOf(
            ChatMessage(
                "1",
                "Hello! I'm interested in your campaign.",
                true,
                Date(System.currentTimeMillis() - 3600000),
                true
            ),
            ChatMessage(
                "2",
                "Hi! Great to hear from you. Let me share the details.",
                false,
                Date(System.currentTimeMillis() - 3000000),
                true
            ),
            ChatMessage(
                "3",
                "The campaign budget is ₹5000 and we need 3 Instagram posts.",
                false,
                Date(System.currentTimeMillis() - 2400000),
                true
            ),
            ChatMessage(
                "4",
                "That sounds perfect! When do you need it completed?",
                true,
                Date(System.currentTimeMillis() - 1800000),
                true
            ),
            ChatMessage(
                "5",
                "We'd like to have everything done within 7 days.",
                false,
                Date(System.currentTimeMillis() - 900000),
                true
            )
        )
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Surface(
                            shape = CircleShape,
                            color = RexoTheme.colorScheme.primaryContainer
                        ) {
                            Text(
                                text = otherUserName.first().toString(),
                                modifier = Modifier.padding(10.dp),
                                style = RexoTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        
                        Column {
                            Text(
                                text = otherUserName,
                                style = RexoTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "Online",
                                style = RexoTheme.typography.bodySmall,
                                color = Color(0xFF10B981)
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { /* TODO: More options */ }) {
                        Icon(Icons.Outlined.MoreVert, contentDescription = "More")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        },
        bottomBar = {
            ChatInputBar(
                message = messageText,
                onMessageChange = { messageText = it },
                onSend = {
                    if (messageText.isNotBlank()) {
                        messages.add(
                            ChatMessage(
                                UUID.randomUUID().toString(),
                                messageText,
                                true,
                                Date(),
                                false
                            )
                        )
                        messageText = ""
                    }
                },
                onAttachment = { /* TODO: Handle attachment */ }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            state = listState,
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            reverseLayout = false
        ) {
            items(messages) { message ->
                MessageBubble(message = message)
            }
        }
    }
}

data class ChatMessage(
    val id: String,
    val text: String,
    val isCurrentUser: Boolean,
    val timestamp: Date,
    val isRead: Boolean
)

@Composable
fun MessageBubble(
    message: ChatMessage
) {
    val dateFormat = remember { SimpleDateFormat("HH:mm", Locale.getDefault()) }
    
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (message.isCurrentUser) Arrangement.End else Arrangement.Start
    ) {
        Column(
            horizontalAlignment = if (message.isCurrentUser) Alignment.End else Alignment.Start,
            modifier = Modifier.widthIn(max = 280.dp)
        ) {
            Surface(
                shape = RoundedCornerShape(
                    topStart = 16.dp,
                    topEnd = 16.dp,
                    bottomStart = if (message.isCurrentUser) 16.dp else 4.dp,
                    bottomEnd = if (message.isCurrentUser) 4.dp else 16.dp
                ),
                color = if (message.isCurrentUser) 
                    RexoTheme.colorScheme.primary 
                else 
                    RexoTheme.colorScheme.surfaceVariant,
                shadowElevation = 2.dp
            ) {
                Text(
                    text = message.text,
                    modifier = Modifier.padding(12.dp),
                    style = RexoTheme.typography.bodyMedium,
                    color = if (message.isCurrentUser)
                        RexoTheme.colorScheme.onPrimary
                    else
                        RexoTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Spacer(modifier = Modifier.height(4.dp))
            
            Row(
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = dateFormat.format(message.timestamp),
                    style = RexoTheme.typography.labelSmall,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                )
                
                if (message.isCurrentUser) {
                    Icon(
                        imageVector = if (message.isRead) Icons.Outlined.DoneAll else Icons.Outlined.Done,
                        contentDescription = if (message.isRead) "Read" else "Sent",
                        modifier = Modifier.size(14.dp),
                        tint = if (message.isRead) Color(0xFF6366F1) else RexoTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                }
            }
        }
    }
}

@Composable
fun ChatInputBar(
    message: String,
    onMessageChange: (String) -> Unit,
    onSend: () -> Unit,
    onAttachment: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shadowElevation = 8.dp,
        color = RexoTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            IconButton(
                onClick = onAttachment,
                modifier = Modifier.size(40.dp)
            ) {
                Surface(
                    shape = CircleShape,
                    color = RexoTheme.colorScheme.surfaceVariant
                ) {
                    Icon(
                        imageVector = Icons.Outlined.AttachFile,
                        contentDescription = "Attach",
                        modifier = Modifier.padding(8.dp)
                    )
                }
            }
            
            GlassSurface(
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(24.dp)
            ) {
                TextField(
                    value = message,
                    onValueChange = onMessageChange,
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("Type a message...") },
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = Color.Transparent,
                        unfocusedContainerColor = Color.Transparent,
                        focusedIndicatorColor = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent
                    ),
                    maxLines = 4
                )
            }
            
            IconButton(
                onClick = onSend,
                enabled = message.isNotBlank(),
                modifier = Modifier.size(48.dp)
            ) {
                Surface(
                    shape = CircleShape,
                    color = if (message.isNotBlank()) 
                        RexoTheme.colorScheme.primary 
                    else 
                        RexoTheme.colorScheme.surfaceVariant
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Send,
                        contentDescription = "Send",
                        modifier = Modifier.padding(12.dp),
                        tint = if (message.isNotBlank())
                            RexoTheme.colorScheme.onPrimary
                        else
                            RexoTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}
