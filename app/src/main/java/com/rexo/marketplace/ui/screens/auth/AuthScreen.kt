package com.rexo.marketplace.ui.screens.auth

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Modern Auth Screen with completely new UI/UX
 * Features:
 * - Animated gradient background
 * - Glassmorphism effects
 * - Smooth transitions between login/signup
 * - Spring animations
 * - Clean minimalist design
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AuthScreen(
    onNavigateToHome: () -> Unit = {}
) {
    var isLogin by remember { mutableStateOf(true) }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var fullName by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    
    val focusManager = LocalFocusManager.current
    val scope = rememberCoroutineScope()

    // Animated background colors
    val infiniteTransition = rememberInfiniteTransition(label = "background")
    val animatedOffset by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(6000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "gradient"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        RexoTheme.colorScheme.primary.copy(alpha = 0.3f + animatedOffset * 0.2f),
                        RexoTheme.colorScheme.secondary.copy(alpha = 0.2f + animatedOffset * 0.3f),
                        RexoTheme.colorScheme.tertiary.copy(alpha = 0.4f + animatedOffset * 0.2f)
                    )
                )
            )
    ) {
        // Blurred background circles for depth
        Box(
            modifier = Modifier
                .size(300.dp)
                .offset(x = (-50).dp, y = 100.dp)
                .scale(1f + animatedOffset * 0.2f)
                .clip(RoundedCornerShape(50))
                .background(RexoTheme.colorScheme.primary.copy(alpha = 0.3f))
                .blur(80.dp)
        )
        
        Box(
            modifier = Modifier
                .size(250.dp)
                .align(Alignment.TopEnd)
                .offset(x = 50.dp, y = (-50).dp)
                .scale(1f + (1f - animatedOffset) * 0.2f)
                .clip(RoundedCornerShape(50))
                .background(RexoTheme.colorScheme.secondary.copy(alpha = 0.3f))
                .blur(80.dp)
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // App Logo/Title with animation
            val logoScale by animateFloatAsState(
                targetValue = if (isLogin) 1f else 0.9f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioMediumBouncy,
                    stiffness = Spring.StiffnessLow
                ),
                label = "logo"
            )
            
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.scale(logoScale)
            ) {
                Icon(
                    imageVector = Icons.Filled.Store,
                    contentDescription = "Rexo Logo",
                    modifier = Modifier.size(64.dp),
                    tint = RexoTheme.colorScheme.onBackground
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "Rexo",
                    style = RexoTheme.typography.displayLarge,
                    fontWeight = FontWeight.Bold,
                    color = RexoTheme.colorScheme.onBackground
                )
                
                Text(
                    text = "Marketplace",
                    style = RexoTheme.typography.titleMedium,
                    color = RexoTheme.colorScheme.onBackground.copy(alpha = 0.7f)
                )
            }
            
            Spacer(modifier = Modifier.height(48.dp))
            
            // Glassmorphism Card
            GlassSurface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(28.dp),
                backgroundColor = RexoTheme.colorScheme.surface.copy(alpha = 0.7f)
            ) {
                Column(
                    modifier = Modifier.padding(24.dp)
                ) {
                    // Toggle Tabs
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        AuthTab(
                            text = "Login",
                            isSelected = isLogin,
                            onClick = { isLogin = true },
                            modifier = Modifier.weight(1f)
                        )
                        
                        AuthTab(
                            text = "Sign Up",
                            isSelected = !isLogin,
                            onClick = { isLogin = false },
                            modifier = Modifier.weight(1f)
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Animated Form
                    AnimatedContent(
                        targetState = isLogin,
                        transitionSpec = {
                            slideInHorizontally { width -> if (targetState) -width else width } + fadeIn() togetherWith
                            slideOutHorizontally { width -> if (targetState) width else -width } + fadeOut()
                        },
                        label = "form"
                    ) { loginMode ->
                        Column {
                            if (!loginMode) {
                                // Full Name (Signup only)
                                ModernTextField(
                                    value = fullName,
                                    onValueChange = { fullName = it },
                                    label = "Full Name",
                                    icon = Icons.Outlined.Person,
                                    keyboardOptions = KeyboardOptions(
                                        keyboardType = KeyboardType.Text,
                                        imeAction = ImeAction.Next
                                    ),
                                    keyboardActions = KeyboardActions(
                                        onNext = { focusManager.moveFocus(FocusDirection.Down) }
                                    )
                                )
                                
                                Spacer(modifier = Modifier.height(16.dp))
                            }
                            
                            // Email
                            ModernTextField(
                                value = email,
                                onValueChange = { email = it },
                                label = "Email",
                                icon = Icons.Outlined.Email,
                                keyboardOptions = KeyboardOptions(
                                    keyboardType = KeyboardType.Email,
                                    imeAction = ImeAction.Next
                                ),
                                keyboardActions = KeyboardActions(
                                    onNext = { focusManager.moveFocus(FocusDirection.Down) }
                                )
                            )
                            
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            if (!loginMode) {
                                // Phone (Signup only)
                                ModernTextField(
                                    value = phone,
                                    onValueChange = { phone = it },
                                    label = "Phone Number",
                                    icon = Icons.Outlined.Phone,
                                    keyboardOptions = KeyboardOptions(
                                        keyboardType = KeyboardType.Phone,
                                        imeAction = ImeAction.Next
                                    ),
                                    keyboardActions = KeyboardActions(
                                        onNext = { focusManager.moveFocus(FocusDirection.Down) }
                                    )
                                )
                                
                                Spacer(modifier = Modifier.height(16.dp))
                            }
                            
                            // Password
                            ModernTextField(
                                value = password,
                                onValueChange = { password = it },
                                label = "Password",
                                icon = Icons.Outlined.Lock,
                                isPassword = true,
                                passwordVisible = passwordVisible,
                                onPasswordVisibilityToggle = { passwordVisible = !passwordVisible },
                                keyboardOptions = KeyboardOptions(
                                    keyboardType = KeyboardType.Password,
                                    imeAction = ImeAction.Done
                                ),
                                keyboardActions = KeyboardActions(
                                    onDone = { focusManager.clearFocus() }
                                )
                            )
                            
                            if (loginMode) {
                                Spacer(modifier = Modifier.height(8.dp))
                                
                                Text(
                                    text = "Forgot Password?",
                                    style = RexoTheme.typography.bodySmall,
                                    color = RexoTheme.colorScheme.primary,
                                    modifier = Modifier
                                        .align(Alignment.End)
                                        .clickable { /* TODO: Forgot password */ }
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(24.dp))
                            
                            // Submit Button
                            ModernButton(
                                text = if (loginMode) "Login" else "Create Account",
                                onClick = {
                                    scope.launch {
                                        isLoading = true
                                        delay(2000) // Simulate API call
                                        isLoading = false
                                        onNavigateToHome()
                                    }
                                },
                                isLoading = isLoading,
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Social Login Divider
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Divider(modifier = Modifier.weight(1f), color = RexoTheme.colorScheme.onBackground.copy(alpha = 0.3f))
                Text(
                    text = "OR",
                    modifier = Modifier.padding(horizontal = 16.dp),
                    style = RexoTheme.typography.bodySmall,
                    color = RexoTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                )
                Divider(modifier = Modifier.weight(1f), color = RexoTheme.colorScheme.onBackground.copy(alpha = 0.3f))
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Social Login Buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                SocialLoginButton(
                    icon = Icons.Outlined.Email,
                    text = "Google",
                    onClick = { /* TODO */ },
                    modifier = Modifier.weight(1f)
                )
                
                SocialLoginButton(
                    icon = Icons.Outlined.Phone,
                    text = "Phone",
                    onClick = { /* TODO */ },
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
fun AuthTab(
    text: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val backgroundColor by animateColorAsState(
        targetValue = if (isSelected) RexoTheme.colorScheme.primary else Color.Transparent,
        animationSpec = tween(300),
        label = "tab_bg"
    )
    
    val contentColor by animateColorAsState(
        targetValue = if (isSelected) RexoTheme.colorScheme.onPrimary else RexoTheme.colorScheme.onSurface,
        animationSpec = tween(300),
        label = "tab_content"
    )
    
    val scale by animateFloatAsState(
        targetValue = if (isSelected) 1f else 0.95f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "tab_scale"
    )
    
    Surface(
        modifier = modifier
            .scale(scale)
            .clip(RoundedCornerShape(16.dp))
            .clickable(onClick = onClick),
        color = backgroundColor,
        shape = RoundedCornerShape(16.dp)
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(vertical = 12.dp),
            style = RexoTheme.typography.titleMedium,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            color = contentColor,
            textAlign = TextAlign.Center
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ModernTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    isPassword: Boolean = false,
    passwordVisible: Boolean = false,
    onPasswordVisibilityToggle: () -> Unit = {},
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label) },
        leadingIcon = {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = RexoTheme.colorScheme.primary
            )
        },
        trailingIcon = if (isPassword) {
            {
                IconButton(onClick = onPasswordVisibilityToggle) {
                    Icon(
                        imageVector = if (passwordVisible) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
                        contentDescription = "Toggle password visibility"
                    )
                }
            }
        } else null,
        visualTransformation = if (isPassword && !passwordVisible) PasswordVisualTransformation() else VisualTransformation.None,
        keyboardOptions = keyboardOptions,
        keyboardActions = keyboardActions,
        singleLine = true,
        shape = RoundedCornerShape(16.dp),
        colors = TextFieldDefaults.outlinedTextFieldColors(
            containerColor = RexoTheme.colorScheme.surface.copy(alpha = 0.5f),
            focusedBorderColor = RexoTheme.colorScheme.primary,
            unfocusedBorderColor = RexoTheme.colorScheme.outline.copy(alpha = 0.3f)
        ),
        modifier = modifier.fillMaxWidth()
    )
}

@Composable
fun ModernButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isLoading: Boolean = false
) {
    val scale by animateFloatAsState(
        targetValue = if (isLoading) 0.95f else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "button_scale"
    )
    
    Button(
        onClick = onClick,
        modifier = modifier
            .height(56.dp)
            .scale(scale),
        enabled = !isLoading,
        shape = RoundedCornerShape(16.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = RexoTheme.colorScheme.primary,
            contentColor = RexoTheme.colorScheme.onPrimary
        )
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(24.dp),
                color = RexoTheme.colorScheme.onPrimary,
                strokeWidth = 2.dp
            )
        } else {
            Text(
                text = text,
                style = RexoTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun SocialLoginButton(
    icon: ImageVector,
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier.height(56.dp),
        shape = RoundedCornerShape(16.dp),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = RexoTheme.colorScheme.surface.copy(alpha = 0.5f)
        ),
        border = ButtonDefaults.outlinedButtonBorder.copy(
            width = 1.dp,
            brush = Brush.linearGradient(
                colors = listOf(
                    RexoTheme.colorScheme.primary.copy(alpha = 0.3f),
                    RexoTheme.colorScheme.secondary.copy(alpha = 0.3f)
                )
            )
        )
    ) {
        Icon(
            imageVector = icon,
            contentDescription = text,
            modifier = Modifier.size(20.dp)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(text = text, style = RexoTheme.typography.bodyMedium)
    }
}
