package com.rexo.marketplace.ui.screens.chat

import androidx.compose.foundation.clickable
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.ChatMessageData
import com.rexo.marketplace.ui.viewmodel.ChatViewModel
import com.rexo.marketplace.ui.viewmodel.ConversationData

/**
 * Chat List Screen
 * Shows all conversations from Supabase messages table.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatListScreen(
    onNavigateBack: () -> Unit = {},
    onNavigateToChat: (String) -> Unit = {},
    viewModel: ChatViewModel
) {
    val uiState by viewModel.uiState.collectAsState()
    val conversations by viewModel.conversations.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadConversations()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Messages",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        }
    ) { paddingValues ->
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = RexoColors.AccentOrange)
                }
            }
            uiState.error != null -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Outlined.ErrorOutline,
                            contentDescription = "Error",
                            modifier = Modifier.size(64.dp),
                            tint = RexoColors.Error
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = uiState.error ?: "Something went wrong",
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextSecondary
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = { viewModel.loadConversations() }) {
                            Text("Retry")
                        }
                    }
                }
            }
            conversations.isEmpty() -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Outlined.Chat,
                            contentDescription = "No messages",
                            modifier = Modifier.size(80.dp),
                            tint = RexoColors.Gray300
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "No conversations yet",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Start a conversation with a brand or creator",
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextSecondary
                        )
                    }
                }
            }
            else -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentPadding = PaddingValues(horizontal = 20.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(conversations, key = { it.id }) { conversation ->
                        ConversationItem(
                            conversation = conversation,
                            onClick = { onNavigateToChat(conversation.otherUserId) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ConversationItem(
    conversation: ConversationData,
    onClick: () -> Unit
) {
    GlassSurface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Avatar
            Surface(
                modifier = Modifier.size(48.dp),
                shape = CircleShape,
                color = RexoColors.AccentOrange.copy(alpha = 0.1f)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = conversation.otherUserName.firstOrNull()?.uppercase() ?: "?",
                        style = RexoTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.AccentOrange
                    )
                }
            }

            // Content
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = conversation.otherUserName,
                        style = RexoTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Bold
                    )
                    if (conversation.lastMessageTime.isNotEmpty()) {
                        Text(
                            text = conversation.lastMessageTime.take(10),
                            style = RexoTheme.typography.labelSmall,
                            color = RexoColors.TextSecondary
                        )
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = conversation.lastMessage,
                        style = RexoTheme.typography.bodyMedium,
                        color = RexoColors.TextSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )
                    if (conversation.unreadCount > 0) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Surface(
                            shape = CircleShape,
                            color = RexoColors.AccentOrange
                        ) {
                            Text(
                                text = conversation.unreadCount.toString(),
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                style = RexoTheme.typography.labelSmall,
                                color = Color.White,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        }
    }
}

/**
 * Chat Detail Screen
 * Shows messages with a specific recipient and allows sending new messages.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatDetailScreen(
    recipientId: String,
    onNavigateBack: () -> Unit = {},
    viewModel: ChatViewModel
) {
    val uiState by viewModel.uiState.collectAsState()
    val messages by viewModel.messages.collectAsState()
    var messageText by remember { mutableStateOf("") }
    val listState = rememberLazyListState()

    LaunchedEffect(recipientId) {
        viewModel.loadMessages(recipientId)
    }

    // Scroll to bottom when new messages arrive
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
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
                            modifier = Modifier.size(40.dp),
                            shape = CircleShape,
                            color = RexoColors.AccentOrange.copy(alpha = 0.1f)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    text = recipientId.firstOrNull()?.uppercase() ?: "?",
                                    style = RexoTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = RexoColors.AccentOrange
                                )
                            }
                        }
                        Text(
                            text = recipientId.take(8),
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        },
        bottomBar = {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shadowElevation = 8.dp,
                color = RexoTheme.colorScheme.surface
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    verticalAlignment = Alignment.Bottom,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = messageText,
                        onValueChange = { messageText = it },
                        modifier = Modifier.weight(1f),
                        placeholder = { Text("Type a message...") },
                        shape = RoundedCornerShape(24.dp),
                        maxLines = 4
                    )

                    IconButton(
                        onClick = {
                            if (messageText.isNotBlank()) {
                                viewModel.sendMessage(messageText)
                                messageText = ""
                            }
                        },
                        enabled = messageText.isNotBlank(),
                        modifier = Modifier.size(48.dp)
                    ) {
                        Surface(
                            shape = CircleShape,
                            color = if (messageText.isNotBlank())
                                RexoColors.AccentOrange
                            else
                                RexoColors.Gray200
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Send,
                                contentDescription = "Send",
                                modifier = Modifier.padding(12.dp),
                                tint = if (messageText.isNotBlank())
                                    Color.White
                                else
                                    RexoColors.Gray400
                            )
                        }
                    }
                }
            }
        }
    ) { paddingValues ->
        when {
            uiState.isLoading && messages.isEmpty() -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = RexoColors.AccentOrange)
                }
            }
            uiState.error != null && messages.isEmpty() -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Outlined.ErrorOutline,
                            contentDescription = "Error",
                            modifier = Modifier.size(64.dp),
                            tint = RexoColors.Error
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = uiState.error ?: "Failed to load messages",
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextSecondary
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = { viewModel.loadMessages(recipientId) }) {
                            Text("Retry")
                        }
                    }
                }
            }
            messages.isEmpty() -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Outlined.Chat,
                            contentDescription = "No messages",
                            modifier = Modifier.size(64.dp),
                            tint = RexoColors.Gray300
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "No messages yet",
                            style = RexoTheme.typography.titleMedium,
                            color = RexoColors.TextSecondary
                        )
                        Text(
                            text = "Send the first message!",
                            style = RexoTheme.typography.bodyMedium,
                            color = RexoColors.TextSecondary
                        )
                    }
                }
            }
            else -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    state = listState,
                    contentPadding = PaddingValues(20.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(messages, key = { it.id }) { message ->
                        MessageBubble(message = message)
                    }
                }
            }
        }
    }
}

@Composable
fun MessageBubble(message: ChatMessageData) {
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
                    RexoColors.AccentOrange
                else
                    RexoColors.Gray100,
                shadowElevation = 1.dp
            ) {
                Text(
                    text = message.text,
                    modifier = Modifier.padding(12.dp),
                    style = RexoTheme.typography.bodyMedium,
                    color = if (message.isCurrentUser) Color.White else RexoColors.TextPrimary
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            Row(
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (message.timestamp.isNotEmpty()) {
                    Text(
                        text = message.timestamp.takeLast(8).take(5),
                        style = RexoTheme.typography.labelSmall,
                        color = RexoColors.TextSecondary
                    )
                }
                if (message.isCurrentUser) {
                    Icon(
                        imageVector = if (message.isRead) Icons.Outlined.DoneAll else Icons.Outlined.Done,
                        contentDescription = if (message.isRead) "Read" else "Sent",
                        modifier = Modifier.size(14.dp),
                        tint = if (message.isRead) RexoColors.AccentOrange else RexoColors.Gray400
                    )
                }
            }
        }
    }
}
