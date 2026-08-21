package com.rexo.marketplace.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.rexo.marketplace.data.model.*

/**
 * Room Database for Offline Caching
 * 
 * Stores all data locally for offline-first architecture
 */
@Database(
    entities = [
        UserProfile::class,
        Campaign::class,
        CampaignApplication::class,
        Wallet::class,
        WalletTransaction::class,
        WithdrawalRequest::class,
        DepositRequest::class,
        AppNotification::class,
        UserDevice::class,
        StoreProduct::class,
        StoreOrder::class
    ],
    version = 1,
    exportSchema = false
)
abstract class RexoDatabase : RoomDatabase() {
    
    abstract fun userDao(): UserDao
    abstract fun campaignDao(): CampaignDao
    abstract fun walletDao(): WalletDao
    abstract fun notificationDao(): NotificationDao
    abstract fun shopDao(): ShopDao
    
    companion object {
        @Volatile
        private var INSTANCE: RexoDatabase? = null
        
        fun getDatabase(context: Context): RexoDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    RexoDatabase::class.java,
                    "rexo_database"
                )
                    .fallbackToDestructiveMigration()
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
