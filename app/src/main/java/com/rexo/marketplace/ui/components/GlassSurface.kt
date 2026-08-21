package com.rexo.marketplace.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoCustomShapes

/**
 * Clean Card Surface Component
 *
 * Renders a clean white card with subtle light gray border.
 * No blur, no glass effects, no gradient overlays.
 * Replaces the previous glassmorphism effect.
 */
@Composable
fun GlassSurface(
    modifier: Modifier = Modifier,
    shape: Shape = RexoCustomShapes.CardShape,
    blurRadius: Dp = 0.dp,
    backgroundColor: Color = MaterialTheme.colorScheme.surface,
    borderColor: Color = RexoColors.CardBorder,
    content: @Composable () -> Unit
) {
    Surface(
        modifier = modifier,
        shape = shape,
        color = backgroundColor,
        border = BorderStroke(
            width = 1.dp,
            color = borderColor
        ),
        shadowElevation = 1.dp
    ) {
        content()
    }
}

/**
 * Elevated Card Component
 * Used for bottom navigation, floating action buttons, etc.
 * Clean white card with subtle border and minimal elevation.
 */
@Composable
fun FloatingGlassCard(
    modifier: Modifier = Modifier,
    shape: Shape = RexoCustomShapes.CardShape,
    backgroundColor: Color = RexoColors.GlassLight,
    content: @Composable () -> Unit
) {
    Surface(
        modifier = modifier,
        shape = shape,
        color = backgroundColor,
        shadowElevation = 2.dp,
        border = BorderStroke(
            width = 1.dp,
            color = RexoColors.CardBorder
        )
    ) {
        content()
    }
}

/**
 * Elevated Card Component with a Brush background
 */
@Composable
fun FloatingGlassCard(
    modifier: Modifier = Modifier,
    shape: Shape = RexoCustomShapes.CardShape,
    backgroundColor: Brush,
    content: @Composable () -> Unit
) {
    Surface(
        modifier = modifier,
        shape = shape,
        color = Color.Transparent,
        shadowElevation = 2.dp,
        border = BorderStroke(
            width = 1.dp,
            color = RexoColors.CardBorder
        )
    ) {
        Box(modifier = Modifier.background(backgroundColor)) {
            content()
        }
    }
}
