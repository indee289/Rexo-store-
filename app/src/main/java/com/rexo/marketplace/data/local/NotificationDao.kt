package com.rexo.marketplace.data.local

import androidx.room.*
import com.rexo.marketplace.data.model.AppNotification
import com.rexo.marketplace.data.model.UserDevice
import kotlinx.coroutines.flow.Flow

/**
 * Notification Data Access Object
 */
@Dao
interface NotificationDao {
    
    @Query("SELECT * FROM notifications WHERE userId = :userId OR userId = 'all' ORDER BY createdAt DESC")
    fun getNotificationsFlow(userId: String): Flow<List<AppNotification>>
    
    @Query("SELECT COUNT(*) FROM notifications WHERE userId = :userId AND isRead = 0")
    fun getUnreadCountFlow(userId: String): Flow<Int>
    
    @Query("SELECT * FROM notifications WHERE id = :notificationId")
    suspend fun getNotificationById(notificationId: String): AppNotification?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNotification(notification: AppNotification)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNotifications(notifications: List<AppNotification>)
    
    @Query("UPDATE notifications SET isRead = 1 WHERE id = :notificationId")
    suspend fun markAsRead(notificationId: String)
    
    @Query("UPDATE notifications SET isRead = 1 WHERE userId = :userId")
    suspend fun markAllAsRead(userId: String)
    
    @Delete
    suspend fun deleteNotification(notification: AppNotification)
    
    @Query("DELETE FROM notifications WHERE id = :notificationId")
    suspend fun deleteNotificationById(notificationId: String)
    
    // User Devices
    @Query("SELECT * FROM user_devices WHERE userId = :userId")
    suspend fun getUserDevices(userId: String): List<UserDevice>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertDevice(device: UserDevice)
    
    @Query("DELETE FROM user_devices WHERE userId = :userId AND fcmToken = :fcmToken")
    suspend fun deleteDevice(userId: String, fcmToken: String)
}
