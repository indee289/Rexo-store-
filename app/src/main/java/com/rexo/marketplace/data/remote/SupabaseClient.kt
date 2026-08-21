package com.rexo.marketplace.data.remote

import android.content.Context
import com.rexo.marketplace.BuildConfig
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.realtime.Realtime
import io.github.jan.supabase.realtime.realtime
import io.github.jan.supabase.storage.Storage
import io.github.jan.supabase.storage.storage

/**
 * Supabase Client Singleton
 * Provides access to Supabase services:
 * - Auth: Authentication
 * - Postgrest: Database queries
 * - Realtime: Real-time subscriptions
 * - Storage: File upload/download
 */
object SupabaseClient {
    
    private var _client: SupabaseClient? = null
    
    /**
     * Initialize Supabase client
     * Call this from Application.onCreate()
     */
    fun initialize(context: Context) {
        if (_client == null) {
            _client = createSupabaseClient(
                supabaseUrl = BuildConfig.SUPABASE_URL,
                supabaseKey = BuildConfig.SUPABASE_ANON_KEY
            ) {
                install(Auth) {
                    // Auth configuration
                    autoLoadFromStorage = true
                    autoSaveToStorage = true
                }
                install(Postgrest) {
                    // Database configuration
                }
                install(Realtime) {
                    // Real-time configuration
                }
                install(Storage) {
                    // Storage configuration
                }
            }
        }
    }
    
    /**
     * Get Supabase client instance
     * @throws IllegalStateException if client is not initialized
     */
    val client: SupabaseClient
        get() = _client ?: throw IllegalStateException(
            "SupabaseClient not initialized. Call SupabaseClient.initialize() first."
        )
    
    /**
     * Auth service for authentication
     */
    val auth: Auth
        get() = client.auth
    
    /**
     * Postgrest service for database queries
     */
    val postgrest: Postgrest
        get() = client.postgrest
    
    /**
     * Realtime service for subscriptions
     */
    val realtime: Realtime
        get() = client.realtime
    
    /**
     * Storage service for file operations
     */
    val storage: Storage
        get() = client.storage
    
    /**
     * Check if client is initialized
     */
    val isInitialized: Boolean
        get() = _client != null
}
