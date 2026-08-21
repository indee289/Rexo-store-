package com.rexo.marketplace.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.pulltorefresh.PullToRefreshDefaults
import androidx.compose.material3.pulltorefresh.pullToRefresh
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import kotlinx.coroutines.launch

/**
 * Pull to Refresh Component
 * Material 3 implementation with haptic feedback
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PullToRefreshBox(
    isRefreshing: Boolean,
    onRefresh: suspend () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val state = rememberPullToRefreshState()
    val scope = rememberCoroutineScope()
    val haptic = rememberHapticFeedback()

    Box(
        modifier = modifier
            .fillMaxSize()
            .pullToRefresh(
                isRefreshing = isRefreshing,
                state = state,
                onRefresh = {
                    haptic.perform(HapticFeedbackType.SUCCESS)
                    scope.launch { onRefresh() }
                }
            )
    ) {
        content()

        PullToRefreshDefaults.Indicator(
            state = state,
            isRefreshing = isRefreshing,
            modifier = Modifier.align(Alignment.TopCenter)
        )
    }
}

// Simpler version with manual state management
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SimplePullToRefresh(
    isRefreshing: Boolean,
    onRefresh: () -> Unit,
    content: @Composable () -> Unit
) {
    var refreshing by remember { mutableStateOf(isRefreshing) }
    
    LaunchedEffect(isRefreshing) {
        refreshing = isRefreshing
    }
    
    PullToRefreshBox(
        isRefreshing = refreshing,
        onRefresh = {
            refreshing = true
            onRefresh()
        }
    ) {
        content()
    }
}
