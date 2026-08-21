package com.rexo.marketplace.ui.components

import android.view.HapticFeedbackConstants
import androidx.compose.animation.core.*
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.material3.ripple
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalView

/**
 * Touch Feedback & Haptics
 * - Haptic feedback on touch
 * - Scale animation on press
 * - Ripple effect
 */

// Haptic Feedback Types
enum class HapticFeedbackType {
    CLICK,           // Light click
    LONG_PRESS,      // Strong feedback
    SUCCESS,         // Success haptic
    ERROR,           // Error haptic
    SELECTION        // Selection change
}

// Haptic Manager Composable
@Composable
fun rememberHapticFeedback(): HapticFeedback {
    val view = LocalView.current
    return remember { HapticFeedback(view) }
}

class HapticFeedback(private val view: android.view.View) {
    fun perform(type: HapticFeedbackType) {
        val feedbackConstant = when (type) {
            HapticFeedbackType.CLICK -> HapticFeedbackConstants.VIRTUAL_KEY
            HapticFeedbackType.LONG_PRESS -> HapticFeedbackConstants.LONG_PRESS
            HapticFeedbackType.SUCCESS -> HapticFeedbackConstants.CONFIRM
            HapticFeedbackType.ERROR -> HapticFeedbackConstants.REJECT
            HapticFeedbackType.SELECTION -> HapticFeedbackConstants.CLOCK_TICK
        }
        view.performHapticFeedback(feedbackConstant)
    }
}

// Clickable with Haptic Feedback
fun Modifier.clickableWithFeedback(
    hapticType: HapticFeedbackType = HapticFeedbackType.CLICK,
    enabled: Boolean = true,
    onClick: () -> Unit
) = composed {
    val haptic = rememberHapticFeedback()
    val interactionSource = remember { MutableInteractionSource() }
    
    this.clickable(
        interactionSource = interactionSource,
        indication = ripple(),
        enabled = enabled,
        onClick = {
            haptic.perform(hapticType)
            onClick()
        }
    )
}

// Touch Scale Effect
fun Modifier.touchScaleEffect(
    scaleDown: Float = 0.95f
) = composed {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) scaleDown else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "scale"
    )
    
    this
        .clickable(interactionSource = interactionSource, indication = null) {}
        .scale(scale)
}

// Press and Hold Effect
fun Modifier.pressAndHold(
    scaleDown: Float = 0.92f,
    hapticOnPress: Boolean = true,
    onClick: () -> Unit = {}
) = composed {
    val haptic = rememberHapticFeedback()
    var isPressed by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) scaleDown else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "pressScale"
    )
    
    this
        .scale(scale)
        .pointerInput(Unit) {
            detectTapGestures(
                onPress = {
                    isPressed = true
                    if (hapticOnPress) {
                        haptic.perform(HapticFeedbackType.CLICK)
                    }
                    tryAwaitRelease()
                    isPressed = false
                },
                onTap = { onClick() }
            )
        }
}

// Bounce Animation on Click
fun Modifier.bounceClick(
    bounceScale: Float = 1.1f,
    onClick: () -> Unit
) = composed {
    val haptic = rememberHapticFeedback()
    var animationPlaying by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (animationPlaying) bounceScale else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessHigh
        ),
        finishedListener = { animationPlaying = false },
        label = "bounce"
    )
    
    this
        .scale(scale)
        .clickable {
            haptic.perform(HapticFeedbackType.CLICK)
            animationPlaying = true
            onClick()
        }
}

// Shake Animation (for errors)
fun Modifier.shake(
    enabled: Boolean,
    onAnimationComplete: () -> Unit = {}
) = composed {
    var currentState by remember { mutableStateOf(ShakeState.Initial) }
    
    val offsetX by animateFloatAsState(
        targetValue = when (currentState) {
            ShakeState.Initial -> 0f
            ShakeState.Left -> -20f
            ShakeState.Right -> 20f
        },
        animationSpec = tween(durationMillis = 50),
        finishedListener = {
            when (currentState) {
                ShakeState.Initial -> if (enabled) currentState = ShakeState.Left
                ShakeState.Left -> currentState = ShakeState.Right
                ShakeState.Right -> {
                    currentState = ShakeState.Initial
                    onAnimationComplete()
                }
            }
        },
        label = "shake"
    )
    
    LaunchedEffect(enabled) {
        if (enabled) {
            currentState = ShakeState.Left
        }
    }
    
    this.graphicsLayer {
        translationX = offsetX
    }
}

private enum class ShakeState {
    Initial, Left, Right
}

// Pulse Animation (for notifications)
fun Modifier.pulse(enabled: Boolean = true) = composed {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.15f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseScale"
    )
    
    val alpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 0.6f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseAlpha"
    )
    
    if (enabled) {
        this
            .scale(scale)
            .graphicsLayer { this.alpha = alpha }
    } else {
        this
    }
}

// Shimmer Effect (for loading states)
fun Modifier.shimmer(enabled: Boolean = true) = composed {
    if (!enabled) return@composed this
    
    val infiniteTransition = rememberInfiniteTransition(label = "shimmer")
    
    val offsetX by infiniteTransition.animateFloat(
        initialValue = -1000f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmerOffset"
    )
    
    this.graphicsLayer {
        translationX = offsetX
    }
}

// Rotation Animation
fun Modifier.rotateAnimation(
    enabled: Boolean = true,
    duration: Int = 1000
) = composed {
    if (!enabled) return@composed this
    
    val infiniteTransition = rememberInfiniteTransition(label = "rotate")
    
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(duration, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "rotation"
    )
    
    this.graphicsLayer {
        rotationZ = rotation
    }
}

// Slide In Animation
fun Modifier.slideInFromBottom(
    visible: Boolean,
    delay: Int = 0
) = composed {
    val offsetY by animateFloatAsState(
        targetValue = if (visible) 0f else 1000f,
        animationSpec = tween(
            durationMillis = 500,
            delayMillis = delay,
            easing = FastOutSlowInEasing
        ),
        label = "slideIn"
    )
    
    val alpha by animateFloatAsState(
        targetValue = if (visible) 1f else 0f,
        animationSpec = tween(
            durationMillis = 500,
            delayMillis = delay
        ),
        label = "fadeIn"
    )
    
    this.graphicsLayer {
        translationY = offsetY
        this.alpha = alpha
    }
}
