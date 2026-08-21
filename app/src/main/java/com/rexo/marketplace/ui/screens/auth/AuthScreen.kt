package com.rexo.marketplace.ui.screens.auth

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusDirection
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
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme
import com.rexo.marketplace.ui.viewmodel.AuthUiState
import com.rexo.marketplace.ui.viewmodel.AuthViewModel

/**
 * Premium Clean Auth Screen
 * White background, orange-red accent CTA, modern form design.
 * Supports Login and Sign Up tabs with real Supabase authentication.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AuthScreen(
    onNavigateToHome: () -> Unit = {},
    authViewModel: AuthViewModel = viewModel()
) {
    var isLogin by remember { mutableStateOf(true) }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var fullName by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }

    val focusManager = LocalFocusManager.current
    val uiState by authViewModel.uiState.collectAsState()

    // Navigate to home when authenticated
    LaunchedEffect(uiState) {
        if (uiState is AuthUiState.Authenticated) {
            onNavigateToHome()
        }
    }

    val isLoading = uiState is AuthUiState.Loading
    val errorMessage = (uiState as? AuthUiState.Error)?.message

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(top = 64.dp, bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Logo
            Box(
                modifier = Modifier
                    .size(72.dp)
                    .clip(CircleShape)
                    .background(RexoColors.AccentOrange),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "R",
                    style = RexoTheme.typography.displaySmall,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "Rexo",
                style = RexoTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            Text(
                text = "Marketplace",
                style = RexoTheme.typography.titleMedium,
                color = RexoColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(40.dp))

            // Login / Sign Up Tabs
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                AuthTabItem(
                    text = "Login",
                    isSelected = isLogin,
                    onClick = {
                        isLogin = true
                        authViewModel.resetState()
                    }
                )

                Spacer(modifier = Modifier.width(32.dp))

                AuthTabItem(
                    text = "Sign Up",
                    isSelected = !isLogin,
                    onClick = {
                        isLogin = false
                        authViewModel.resetState()
                    }
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Error message
            if (errorMessage != null) {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    color = RexoColors.ErrorLight,
                    border = androidx.compose.foundation.BorderStroke(1.dp, RexoColors.Error.copy(alpha = 0.3f))
                ) {
                    Text(
                        text = errorMessage,
                        modifier = Modifier.padding(12.dp),
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.Error,
                        textAlign = TextAlign.Center
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))
            }

            // Form fields
            AnimatedContent(
                targetState = isLogin,
                transitionSpec = {
                    fadeIn() togetherWith fadeOut()
                },
                label = "auth_form"
            ) { loginMode ->
                Column {
                    if (!loginMode) {
                        // Full Name field (Sign Up only)
                        CleanTextField(
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

                    // Email field
                    CleanTextField(
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
                        // Phone field (Sign Up only)
                        CleanTextField(
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

                    // Password field
                    CleanTextField(
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
                            color = RexoColors.AccentOrange,
                            fontWeight = FontWeight.Medium,
                            modifier = Modifier
                                .align(Alignment.End)
                                .clickable {
                                    if (email.isNotBlank()) {
                                        authViewModel.sendPasswordResetEmail(email.trim())
                                    }
                                }
                        )
                    }

                    Spacer(modifier = Modifier.height(32.dp))

                    // Primary action button
                    Button(
                        onClick = {
                            if (loginMode) {
                                authViewModel.signIn(email.trim(), password)
                            } else {
                                authViewModel.signUp(
                                    email.trim(),
                                    password,
                                    fullName.trim(),
                                    phone.trim()
                                )
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp),
                        enabled = !isLoading && email.isNotBlank() && password.isNotBlank(),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = RexoColors.AccentOrange,
                            contentColor = Color.White
                        )
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(22.dp),
                                color = Color.White,
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text(
                                text = if (loginMode) "Sign In" else "Create Account",
                                style = RexoTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }

                    // Password reset success
                    if (uiState is AuthUiState.PasswordResetSent) {
                        Spacer(modifier = Modifier.height(16.dp))
                        Surface(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp),
                            color = RexoColors.SuccessLight,
                            border = androidx.compose.foundation.BorderStroke(1.dp, RexoColors.Success.copy(alpha = 0.3f))
                        ) {
                            Text(
                                text = "Password reset link sent to your email.",
                                modifier = Modifier.padding(12.dp),
                                style = RexoTheme.typography.bodySmall,
                                color = RexoColors.Success,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }
        }
    }
}

/**
 * Tab item with underline indicator for Login/Sign Up toggle
 */
@Composable
private fun AuthTabItem(
    text: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.clickable(onClick = onClick)
    ) {
        Text(
            text = text,
            style = RexoTheme.typography.titleMedium,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            color = if (isSelected) RexoColors.TextPrimary else RexoColors.Gray400
        )

        Spacer(modifier = Modifier.height(4.dp))

        // Underline indicator
        Box(
            modifier = Modifier
                .width(32.dp)
                .height(3.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(
                    if (isSelected) RexoColors.AccentOrange else Color.Transparent
                )
        )
    }
}

/**
 * Clean outlined text field with premium styling
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CleanTextField(
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
                tint = RexoColors.Gray400
            )
        },
        trailingIcon = if (isPassword) {
            {
                IconButton(onClick = onPasswordVisibilityToggle) {
                    Icon(
                        imageVector = if (passwordVisible) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
                        contentDescription = "Toggle password visibility",
                        tint = RexoColors.Gray400
                    )
                }
            }
        } else null,
        visualTransformation = if (isPassword && !passwordVisible) PasswordVisualTransformation() else VisualTransformation.None,
        keyboardOptions = keyboardOptions,
        keyboardActions = keyboardActions,
        singleLine = true,
        shape = RoundedCornerShape(14.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = Color.White,
            unfocusedContainerColor = RexoColors.Gray50,
            focusedBorderColor = RexoColors.AccentOrange,
            unfocusedBorderColor = RexoColors.CardBorder,
            focusedLabelColor = RexoColors.AccentOrange,
            unfocusedLabelColor = RexoColors.TextSecondary,
            cursorColor = RexoColors.AccentOrange
        ),
        modifier = modifier.fillMaxWidth()
    )
}
