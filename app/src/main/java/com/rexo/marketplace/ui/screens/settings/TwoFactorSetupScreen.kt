package com.rexo.marketplace.ui.screens.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Two-Factor Authentication Setup Screen
 * Features:
 * - Enable/disable 2FA
 * - TOTP setup
 * - Backup codes
 * - SMS/Email verification
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TwoFactorSetupScreen(
    onNavigateBack: () -> Unit = {}
) {
    var is2FAEnabled by remember { mutableStateOf(false) }
    var setupStep by remember { mutableStateOf(TwoFactorStep.INITIAL) }
    var verificationCode by remember { mutableStateOf("") }
    var backupCodes by remember { mutableStateOf(emptyList<String>()) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Two-Factor Authentication",
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
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Status Card
            item {
                FloatingGlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp),
                    backgroundColor = if (is2FAEnabled)
                        Color(0xFF10B981).copy(alpha = 0.1f)
                    else
                        Color(0xFFF59E0B).copy(alpha = 0.1f)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(20.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Icon(
                                imageVector = if (is2FAEnabled) Icons.Outlined.Security else Icons.Outlined.LockOpen,
                                contentDescription = "Status",
                                tint = if (is2FAEnabled) Color(0xFF10B981) else Color(0xFFF59E0B),
                                modifier = Modifier.size(32.dp)
                            )
                            Column {
                                Text(
                                    text = if (is2FAEnabled) "2FA Enabled" else "2FA Disabled",
                                    style = RexoTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = if (is2FAEnabled) "Your account is secured" else "Enable for better security",
                                    style = RexoTheme.typography.bodySmall,
                                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                )
                            }
                        }
                        
                        Switch(
                            checked = is2FAEnabled,
                            onCheckedChange = {
                                if (!it) {
                                    is2FAEnabled = false
                                    setupStep = TwoFactorStep.INITIAL
                                } else {
                                    setupStep = TwoFactorStep.CHOOSE_METHOD
                                }
                            }
                        )
                    }
                }
            }
            
            // Setup Content
            when (setupStep) {
                TwoFactorStep.INITIAL -> {
                    if (!is2FAEnabled) {
                        item {
                            BenefitsSection()
                        }
                    } else {
                        item {
                            ActiveMethodsSection(
                                onManageBackupCodes = { setupStep = TwoFactorStep.BACKUP_CODES }
                            )
                        }
                    }
                }
                
                TwoFactorStep.CHOOSE_METHOD -> {
                    item {
                        Text(
                            text = "Choose Authentication Method",
                            style = RexoTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    
                    item {
                        AuthMethodCard(
                            title = "Authenticator App",
                            description = "Use Google Authenticator, Authy, or similar apps",
                            icon = Icons.Outlined.PhoneAndroid,
                            recommended = true,
                            onClick = { setupStep = TwoFactorStep.SETUP_TOTP }
                        )
                    }
                    
                    item {
                        AuthMethodCard(
                            title = "SMS Verification",
                            description = "Receive codes via SMS",
                            icon = Icons.Outlined.Message,
                            onClick = { setupStep = TwoFactorStep.SETUP_SMS }
                        )
                    }
                    
                    item {
                        AuthMethodCard(
                            title = "Email Verification",
                            description = "Receive codes via email",
                            icon = Icons.Outlined.Email,
                            onClick = { setupStep = TwoFactorStep.SETUP_EMAIL }
                        )
                    }
                }
                
                TwoFactorStep.SETUP_TOTP -> {
                    item {
                        TOTPSetupSection(
                            onVerify = {
                                is2FAEnabled = true
                                backupCodes = generateBackupCodes()
                                setupStep = TwoFactorStep.BACKUP_CODES
                            },
                            onCancel = { setupStep = TwoFactorStep.CHOOSE_METHOD }
                        )
                    }
                }
                
                TwoFactorStep.SETUP_SMS -> {
                    item {
                        SMSSetupSection(
                            onVerify = {
                                is2FAEnabled = true
                                backupCodes = generateBackupCodes()
                                setupStep = TwoFactorStep.BACKUP_CODES
                            },
                            onCancel = { setupStep = TwoFactorStep.CHOOSE_METHOD }
                        )
                    }
                }
                
                TwoFactorStep.SETUP_EMAIL -> {
                    item {
                        EmailSetupSection(
                            onVerify = {
                                is2FAEnabled = true
                                backupCodes = generateBackupCodes()
                                setupStep = TwoFactorStep.BACKUP_CODES
                            },
                            onCancel = { setupStep = TwoFactorStep.CHOOSE_METHOD }
                        )
                    }
                }
                
                TwoFactorStep.BACKUP_CODES -> {
                    item {
                        BackupCodesSection(
                            codes = backupCodes,
                            onDone = { setupStep = TwoFactorStep.INITIAL }
                        )
                    }
                }
            }
        }
    }
}

enum class TwoFactorStep {
    INITIAL, CHOOSE_METHOD, SETUP_TOTP, SETUP_SMS, SETUP_EMAIL, BACKUP_CODES
}

@Composable
fun BenefitsSection() {
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Why enable 2FA?",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            BenefitItem(
                icon = Icons.Outlined.Security,
                title = "Extra Security",
                description = "Adds an extra layer of protection to your account"
            )
            
            BenefitItem(
                icon = Icons.Outlined.Block,
                title = "Prevent Unauthorized Access",
                description = "Protect against hackers even if your password is compromised"
            )
            
            BenefitItem(
                icon = Icons.Outlined.Notifications,
                title = "Login Alerts",
                description = "Get notified of any login attempts on your account"
            )
        }
    }
}

@Composable
fun BenefitItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    description: String
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = title,
            tint = RexoTheme.colorScheme.primary
        )
        Column {
            Text(
                text = title,
                style = RexoTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = description,
                style = RexoTheme.typography.bodySmall,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
        }
    }
}

@Composable
fun ActiveMethodsSection(
    onManageBackupCodes: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text(
            text = "Active Methods",
            style = RexoTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        
        GlassSurface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                ActiveMethodItem(
                    icon = Icons.Outlined.PhoneAndroid,
                    title = "Authenticator App",
                    enabled = true
                )
                
                HorizontalDivider()
                
                Button(
                    onClick = onManageBackupCodes,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.outlinedButtonColors()
                ) {
                    Icon(Icons.Outlined.Key, contentDescription = "Backup Codes")
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Manage Backup Codes")
                }
            }
        }
    }
}

@Composable
fun ActiveMethodItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    enabled: Boolean
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(imageVector = icon, contentDescription = title)
            Text(text = title, style = RexoTheme.typography.bodyMedium)
        }
        
        if (enabled) {
            Icon(
                imageVector = Icons.Outlined.CheckCircle,
                contentDescription = "Enabled",
                tint = Color(0xFF10B981)
            )
        }
    }
}

@Composable
fun AuthMethodCard(
    title: String,
    description: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    recommended: Boolean = false,
    onClick: () -> Unit
) {
    GlassSurface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = RexoTheme.colorScheme.primaryContainer
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    modifier = Modifier.padding(12.dp),
                    tint = RexoTheme.colorScheme.primary
                )
            }
            
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = title,
                        style = RexoTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Bold
                    )
                    if (recommended) {
                        Surface(
                            shape = RoundedCornerShape(4.dp),
                            color = Color(0xFF10B981).copy(alpha = 0.15f)
                        ) {
                            Text(
                                text = "RECOMMENDED",
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                style = RexoTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF10B981)
                            )
                        }
                    }
                }
                Text(
                    text = description,
                    style = RexoTheme.typography.bodySmall,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
            
            Icon(
                imageVector = Icons.Outlined.ChevronRight,
                contentDescription = "Select"
            )
        }
    }
}

@Composable
fun TOTPSetupSection(
    onVerify: () -> Unit,
    onCancel: () -> Unit
) {
    var code by remember { mutableStateOf("") }
    
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Scan QR Code",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            // QR Code Placeholder
            Surface(
                modifier = Modifier.size(200.dp),
                shape = RoundedCornerShape(12.dp),
                color = Color.White
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text("QR CODE", style = RexoTheme.typography.bodyLarge)
                }
            }
            
            Text(
                text = "Manual Entry Key:",
                style = RexoTheme.typography.bodySmall,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
            
            Surface(
                shape = RoundedCornerShape(8.dp),
                color = RexoTheme.colorScheme.surfaceVariant
            ) {
                Text(
                    text = "ABCD EFGH IJKL MNOP",
                    modifier = Modifier.padding(12.dp),
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            OutlinedTextField(
                value = code,
                onValueChange = { if (it.length <= 6) code = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Enter 6-digit code") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true
            )
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onCancel,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Cancel")
                }
                
                Button(
                    onClick = onVerify,
                    modifier = Modifier.weight(1f),
                    enabled = code.length == 6
                ) {
                    Text("Verify")
                }
            }
        }
    }
}

@Composable
fun SMSSetupSection(
    onVerify: () -> Unit,
    onCancel: () -> Unit
) {
    var phoneNumber by remember { mutableStateOf("") }
    var code by remember { mutableStateOf("") }
    var codeSent by remember { mutableStateOf(false) }
    
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "SMS Verification Setup",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            if (!codeSent) {
                OutlinedTextField(
                    value = phoneNumber,
                    onValueChange = { phoneNumber = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Phone Number") },
                    placeholder = { Text("+91 XXXXX XXXXX") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                    leadingIcon = { Icon(Icons.Outlined.Phone, contentDescription = null) }
                )
                
                Button(
                    onClick = { codeSent = true },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = phoneNumber.isNotEmpty()
                ) {
                    Text("Send Code")
                }
            } else {
                OutlinedTextField(
                    value = code,
                    onValueChange = { if (it.length <= 6) code = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Enter 6-digit code") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true
                )
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = onCancel,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Cancel")
                    }
                    
                    Button(
                        onClick = onVerify,
                        modifier = Modifier.weight(1f),
                        enabled = code.length == 6
                    ) {
                        Text("Verify")
                    }
                }
            }
        }
    }
}

@Composable
fun EmailSetupSection(
    onVerify: () -> Unit,
    onCancel: () -> Unit
) {
    var code by remember { mutableStateOf("") }
    
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Email Verification Setup",
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = "We've sent a 6-digit code to your registered email address.",
                style = RexoTheme.typography.bodyMedium,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
            
            OutlinedTextField(
                value = code,
                onValueChange = { if (it.length <= 6) code = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Enter 6-digit code") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true
            )
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onCancel,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Cancel")
                }
                
                Button(
                    onClick = onVerify,
                    modifier = Modifier.weight(1f),
                    enabled = code.length == 6
                ) {
                    Text("Verify")
                }
            }
        }
    }
}

@Composable
fun BackupCodesSection(
    codes: List<String>,
    onDone: () -> Unit
) {
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        backgroundColor = Color(0xFF10B981).copy(alpha = 0.1f)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Outlined.CheckCircle,
                    contentDescription = "Success",
                    tint = Color(0xFF10B981),
                    modifier = Modifier.size(32.dp)
                )
                Text(
                    text = "2FA Enabled Successfully!",
                    style = RexoTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            Text(
                text = "Save these backup codes in a safe place. Each code can be used once if you lose access to your authentication method.",
                style = RexoTheme.typography.bodyMedium,
                color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
            
            GlassSurface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    codes.forEach { code ->
                        Text(
                            text = code,
                            modifier = Modifier.fillMaxWidth(),
                            style = RexoTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
            
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = { /* TODO: Download codes */ },
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Outlined.Download, contentDescription = "Download")
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Download")
                }
                
                Button(
                    onClick = onDone,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Done")
                }
            }
        }
    }
}

fun generateBackupCodes(): List<String> {
    return List(8) {
        "${(1000..9999).random()}-${(1000..9999).random()}"
    }
}
