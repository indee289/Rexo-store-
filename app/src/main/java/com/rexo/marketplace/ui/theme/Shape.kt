package com.rexo.marketplace.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

// Rexo Design System uses heavily rounded corners (Tailwind: rounded-2xl, rounded-3xl)
val RexoShapes = Shapes(
    // Small components (buttons, chips)
    extraSmall = RoundedCornerShape(8.dp),   // rounded-lg
    small = RoundedCornerShape(12.dp),        // rounded-xl
    
    // Medium components (cards, inputs)
    medium = RoundedCornerShape(16.dp),       // rounded-2xl
    
    // Large components (modals, bottom sheets)
    large = RoundedCornerShape(24.dp),        // rounded-3xl
    extraLarge = RoundedCornerShape(28.dp)    // Extra rounded for special cards
)

// Custom shape extensions for Rexo components
object RexoCustomShapes {
    val CardShape = RoundedCornerShape(24.dp)           // Main cards
    val ButtonShape = RoundedCornerShape(12.dp)         // Buttons
    val InputShape = RoundedCornerShape(16.dp)          // Text inputs
    val ModalShape = RoundedCornerShape(24.dp)          // Modals/dialogs
    val BottomSheetShape = RoundedCornerShape(
        topStart = 24.dp, 
        topEnd = 24.dp
    )
    val ChipShape = RoundedCornerShape(999.dp)          // Fully rounded pills
    val BadgeShape = RoundedCornerShape(6.dp)           // Small badges
}
