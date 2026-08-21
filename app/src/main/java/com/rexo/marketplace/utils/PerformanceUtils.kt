package com.rexo.marketplace.utils

import android.util.Log
import androidx.compose.runtime.*
import kotlinx.coroutines.delay
import kotlin.system.measureTimeMillis

/**
 * Performance Utilities
 * - Measure execution time
 * - Debounce search
 * - Throttle clicks
 * - Memory monitoring
 */

object PerformanceUtils {
    
    // Measure execution time
    inline fun <T> measureTime(tag: String, block: () -> T): T {
        var result: T
        val time = measureTimeMillis {
            result = block()
        }
        Log.d("Performance", "$tag took $time ms")
        return result
    }
    
    // Log memory usage
    fun logMemoryUsage(tag: String) {
        val runtime = Runtime.getRuntime()
        val usedMemory = (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024)
        val maxMemory = runtime.maxMemory() / (1024 * 1024)
        val availableMemory = maxMemory - usedMemory
        
        Log.d("Memory", "$tag - Used: ${usedMemory}MB / Max: ${maxMemory}MB / Available: ${availableMemory}MB")
    }
}

// Debounce for search
@Composable
fun <T> debounce(
    value: T,
    delayMillis: Long = 500L
): State<T> {
    val debouncedValue = remember { mutableStateOf(value) }
    
    LaunchedEffect(value) {
        delay(delayMillis)
        debouncedValue.value = value
    }
    
    return debouncedValue
}

// Throttle for clicks
class ClickThrottle(private val intervalMs: Long = 500L) {
    private var lastClickTime = 0L
    
    fun canClick(): Boolean {
        val currentTime = System.currentTimeMillis()
        return if (currentTime - lastClickTime >= intervalMs) {
            lastClickTime = currentTime
            true
        } else {
            false
        }
    }
}

@Composable
fun rememberClickThrottle(intervalMs: Long = 500L): ClickThrottle {
    return remember { ClickThrottle(intervalMs) }
}

// Pagination Helper
class PaginationState<T>(
    private val pageSize: Int = 20
) {
    private val _items = mutableStateListOf<T>()
    val items: List<T> get() = _items
    
    var isLoading by mutableStateOf(false)
        private set
    
    var hasMore by mutableStateOf(true)
        private set
    
    private var currentPage = 0
    
    suspend fun loadNextPage(loader: suspend (page: Int, size: Int) -> List<T>) {
        if (isLoading || !hasMore) return
        
        isLoading = true
        try {
            val newItems = loader(currentPage, pageSize)
            _items.addAll(newItems)
            currentPage++
            hasMore = newItems.size >= pageSize
        } catch (e: Exception) {
            // Handle error
        } finally {
            isLoading = false
        }
    }
    
    fun reset() {
        _items.clear()
        currentPage = 0
        hasMore = true
    }
}

@Composable
fun <T> rememberPaginationState(pageSize: Int = 20): PaginationState<T> {
    return remember { PaginationState(pageSize) }
}

// Image Loading State
sealed class ImageLoadState {
    object Loading : ImageLoadState()
    object Success : ImageLoadState()
    data class Error(val message: String) : ImageLoadState()
}

// Network State
sealed class NetworkState {
    object Available : NetworkState()
    object Unavailable : NetworkState()
    object Unknown : NetworkState()
}

// Cache Manager
object CacheManager {
    private val cache = mutableMapOf<String, Pair<Any, Long>>()
    private const val DEFAULT_TTL = 5 * 60 * 1000L // 5 minutes
    
    fun <T> get(key: String): T? {
        val cached = cache[key] ?: return null
        val (value, timestamp) = cached
        
        // Check if expired
        if (System.currentTimeMillis() - timestamp > DEFAULT_TTL) {
            cache.remove(key)
            return null
        }
        
        @Suppress("UNCHECKED_CAST")
        return value as? T
    }
    
    fun <T> put(key: String, value: T) {
        cache[key] = Pair(value as Any, System.currentTimeMillis())
    }
    
    fun clear() {
        cache.clear()
    }
    
    fun remove(key: String) {
        cache.remove(key)
    }
}
