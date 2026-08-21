package com.rexo.marketplace.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

// Rexo Design System - Subtle, clean corner radii
val RexoShapes = Shapes(
    // Small components (chips, badges)
    extraSmall = RoundedCornerShape(6.dp),
    small = RoundedCornerShape(8.dp),

    // Medium components (buttons, inputs)
    medium = RoundedCornerShape(12.dp),

    // Large components (cards)
    large = RoundedCornerShape(16.dp),
    extraLarge = RoundedCornerShape(20.dp)
)

// Custom shape extensions for Rexo components
object RexoCustomShapes {
    val CardShape = RoundedCornerShape(16.dp)            // Main cards - subtle rounding
    val ButtonShape = RoundedCornerShape(10.dp)          // Buttons
    val InputShape = RoundedCornerShape(10.dp)           // Text inputs
    val ModalShape = RoundedCornerShape(16.dp)           // Modals/dialogs
    val BottomSheetShape = RoundedCornerShape(
        topStart = 16.dp,
        topEnd = 16.dp
    )
    val ChipShape = RoundedCornerShape(999.dp)           // Fully rounded pills
    val BadgeShape = RoundedCornerShape(6.dp)            // Small badges
}
