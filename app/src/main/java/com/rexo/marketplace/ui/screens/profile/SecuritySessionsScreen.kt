package com.rexo.marketplace.ui.screens.profile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.theme.RexoTheme
import java.text.SimpleDateFormat
import java.util.*

/**
 * Security Sessions Screen
 * Features:
 * - Active sessions
 * - Device management
 * - Location tracking
 * - Terminate sessions
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SecuritySessionsScreen(
    onNavigateBack: () -> Unit = {}
) {
    val sessions = remember {
        mutableStateListOf(
            DeviceSession(
                "1",
                "Android Phone",
                "OnePlus 9 Pro",
                "Mumbai, India",
                Date(),
                true
            ),
            DeviceSession(
                "2",
                "Desktop",
                "Chrome on Windows",
                "Delhi, India",
                Date(System.currentTimeMillis() - 86400000),
                false
            ),
            DeviceSession(
                "3",
                "Tablet",
                "iPad Pro",
                "Bangalore, India",
                Date(System.currentTimeMillis() - 7 * 86400000),
                false
            )
        )
    }
    
    var showTerminateDialog by remember { mutableStateOf(false) }
    var sessionToTerminate by remember { mutableStateOf<DeviceSession?>(null) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Active Sessions",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (sessions.size > 1) {
                        TextButton(
                            onClick = {
                                sessions.removeAll { !it.isCurrentDevice }
                            }
                        ) {
                            Text("Terminate All")
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Security Info
            item {
                FloatingGlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    backgroundColor = Color(0xFF6366F1).copy(alpha = 0.1f)
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Security,
                            contentDescription = "Security",
                            tint = Color(0xFF6366F1)
                        )
                        Text(
                            text = "You're signed in to ${sessions.size} ${if (sessions.size == 1) "device" else "devices"}. " +
                                   "If you see any unfamiliar sessions, terminate them immediately.",
                            style = RexoTheme.typography.bodySmall,
                            color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                }
            }
            
            // Sessions List
            items(sessions) { session ->
                DeviceSessionCard(
                    session = session,
                    onTerminate = {
                        sessionToTerminate = session
                        showTerminateDialog = true
                    }
                )
            }
        }
    }
    
    // Terminate Confirmation Dialog
    if (showTerminateDialog && sessionToTerminate != null) {
        AlertDialog(
            onDismissRequest = { showTerminateDialog = false },
            icon = {
                Icon(
                    imageVector = Icons.Outlined.Warning,
                    contentDescription = "Warning",
                    tint = Color(0xFFF59E0B)
                )
            },
            title = { Text("Terminate Session?") },
            text = {
                Text("This will sign you out from ${sessionToTerminate?.deviceName}. You'll need to sign in again to use the app on that device.")
            },
            confirmButton = {
                Button(
                    onClick = {
                        sessionToTerminate?.let { sessions.remove(it) }
                        showTerminateDialog = false
                        sessionToTerminate = null
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFEF4444)
                    )
                ) {
                    Text("Terminate")
                }
            },
            dismissButton = {
                TextButton(onClick = { showTerminateDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

data class DeviceSession(
    val id: String,
    val deviceType: String,
    val deviceName: String,
    val location: String,
    val lastActive: Date,
    val isCurrentDevice: Boolean
)

@Composable
fun DeviceSessionCard(
    session: DeviceSession,
    onTerminate: () -> Unit
) {
    val dateFormat = remember { SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault()) }
    
    val deviceIcon = when {
        session.deviceType.contains("Phone", ignoreCase = true) -> Icons.Outlined.PhoneAndroid
        session.deviceType.contains("Tablet", ignoreCase = true) -> Icons.Outlined.Tablet
        session.deviceType.contains("Desktop", ignoreCase = true) -> Icons.Outlined.Computer
        else -> Icons.Outlined.Devices
    }
    
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        backgroundColor = if (session.isCurrentDevice)
            RexoTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
        else
            Color.Transparent
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Device Icon
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = if (session.isCurrentDevice)
                    RexoTheme.colorScheme.primaryContainer
                else
                    RexoTheme.colorScheme.surfaceVariant
            ) {
                Icon(
                    imageVector = deviceIcon,
                    contentDescription = session.deviceType,
                    modifier = Modifier.padding(12.dp),
                    tint = if (session.isCurrentDevice)
                        RexoTheme.colorScheme.primary
                    else
                        RexoTheme.colorScheme.onSurfaceVariant
                )
            }
            
            // Details
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = session.deviceName,
                        style = RexoTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Bold
                    )
                    
                    if (session.isCurrentDevice) {
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = Color(0xFF10B981).copy(alpha = 0.15f)
                        ) {
                            Text(
                                text = "Current",
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                style = RexoTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF10B981)
                            )
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Icon(
                        imageVector = Icons.Outlined.LocationOn,
                        contentDescription = "Location",
                        modifier = Modifier.size(14.dp),
                        tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                    Text(
                        text = session.location,
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
                
                Spacer(modifier = Modifier.height(2.dp))
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Schedule,
                        contentDescription = "Last Active",
                        modifier = Modifier.size(14.dp),
                        tint = RexoTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                    Text(
                        text = "Last active: ${dateFormat.format(session.lastActive)}",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
                
                if (!session.isCurrentDevice) {
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    OutlinedButton(
                        onClick = onTerminate,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = Color(0xFFEF4444)
                        ),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.PowerSettingsNew,
                            contentDescription = "Terminate",
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Terminate Session")
                    }
                }
            }
        }
    }
}
