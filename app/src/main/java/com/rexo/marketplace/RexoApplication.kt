package com.rexo.marketplace

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import com.rexo.marketplace.data.local.RexoDatabase
import com.rexo.marketplace.data.remote.SupabaseClient

/**
 * Rexo Marketplace Application Class
 * 
 * Initializes:
 * - Room Database
 * - Supabase Client
 * - Notification Channels
 * - Firebase
 */
class RexoApplication : Application() {
    
    // Database instance
    val database: RexoDatabase by lazy { 
        RexoDatabase.getDatabase(this) 
    }
    
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Supabase Client
        SupabaseClient.initialize(applicationContext)
        
        // Create notification channels for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannels()
        }
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            
            // Main notification channel
            val mainChannel = NotificationChannel(
                getString(R.string.default_notification_channel_id),
                getString(R.string.default_notification_channel_name),
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = getString(R.string.notification_channel_description)
                enableVibration(true)
                enableLights(true)
                lightColor = resources.getColor(R.color.notification_color, null)
            }
            
            notificationManager.createNotificationChannel(mainChannel)
        }
    }
}
