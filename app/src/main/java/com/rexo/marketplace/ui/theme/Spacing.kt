package com.rexo.marketplace.ui.theme

import androidx.compose.ui.unit.dp

/**
 * Rexo Design System Spacing Scale
 * Based on Tailwind CSS spacing system
 */
object RexoSpacing {
    val none = 0.dp
    val xs = 4.dp      // space-1
    val sm = 8.dp      // space-2
    val md = 12.dp     // space-3
    val lg = 16.dp     // space-4
    val xl = 20.dp     // space-5
    val xxl = 24.dp    // space-6
    val xxxl = 32.dp   // space-8
    
    // Component-specific spacing
    val cardPadding = 16.dp
    val screenPadding = 16.dp
    val sectionSpacing = 20.dp
    val itemSpacing = 12.dp
}

/**
 * Elevation scale for shadows
 */
object RexoElevation {
    val none = 0.dp
    val xs = 1.dp      // shadow-sm
    val sm = 2.dp      // shadow
    val md = 4.dp      // shadow-md
    val lg = 8.dp      // shadow-lg
    val xl = 12.dp     // shadow-xl
    val xxl = 24.dp    // shadow-2xl
}
