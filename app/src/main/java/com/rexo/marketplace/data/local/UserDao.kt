package com.rexo.marketplace.data.local

import androidx.room.*
import com.rexo.marketplace.data.model.UserProfile
import kotlinx.coroutines.flow.Flow

/**
 * User Data Access Object
 */
@Dao
interface UserDao {
    
    @Query("SELECT * FROM users WHERE id = :userId")
    suspend fun getUserById(userId: String): UserProfile?
    
    @Query("SELECT * FROM users WHERE id = :userId")
    fun getUserByIdFlow(userId: String): Flow<UserProfile?>
    
    @Query("SELECT * FROM users")
    fun getAllUsersFlow(): Flow<List<UserProfile>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserProfile)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUsers(users: List<UserProfile>)
    
    @Update
    suspend fun updateUser(user: UserProfile)
    
    @Delete
    suspend fun deleteUser(user: UserProfile)
    
    @Query("DELETE FROM users WHERE id = :userId")
    suspend fun deleteUserById(userId: String)
    
    @Query("DELETE FROM users")
    suspend fun deleteAllUsers()
}
