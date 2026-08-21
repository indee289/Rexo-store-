package com.rexo.marketplace.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoCustomShapes

/**
 * Glass Surface Component
 * 
 * Creates a frosted glass/glassmorphism effect with:
 * - Blur background
 * - Semi-transparent surface
 * - Gradient overlay
 * - Border
 * 
 * Based on React app's glass/blur surfaces
 */
@Composable
fun GlassSurface(
    modifier: Modifier = Modifier,
    shape: Shape = RexoCustomShapes.CardShape,
    blurRadius: Dp = 20.dp,
    backgroundColor: Color = MaterialTheme.colorScheme.surface.copy(alpha = 0.7f),
    borderColor: Color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f),
    content: @Composable () -> Unit
) {
    Surface(
        modifier = modifier,
        shape = shape,
        color = backgroundColor,
        border = androidx.compose.foundation.BorderStroke(
            width = 1.dp,
            color = borderColor
        ),
        shadowElevation = 4.dp
    ) {
        Box(
            modifier = Modifier
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            Color.White.copy(alpha = 0.1f),
                            Color.White.copy(alpha = 0.05f)
                        )
                    )
                )
        ) {
            content()
        }
    }
}

/**
 * Floating Card with Glass Effect
 * Used for bottom navigation, floating action buttons, etc.
 */
@Composable
fun FloatingGlassCard(
    modifier: Modifier = Modifier,
    shape: Shape = RexoCustomShapes.CardShape,
    content: @Composable () -> Unit
) {
    Surface(
        modifier = modifier,
        shape = shape,
        color = RexoColors.GlassLight.copy(alpha = 0.8f),
        shadowElevation = 8.dp,
        border = androidx.compose.foundation.BorderStroke(
            width = 1.dp,
            color = Color.White.copy(alpha = 0.4f)
        )
    ) {
        content()
    }
}
