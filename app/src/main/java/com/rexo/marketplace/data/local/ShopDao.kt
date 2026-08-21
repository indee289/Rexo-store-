package com.rexo.marketplace.data.local

import androidx.room.*
import com.rexo.marketplace.data.model.StoreOrder
import com.rexo.marketplace.data.model.StoreProduct
import kotlinx.coroutines.flow.Flow

/**
 * Shop Data Access Object
 */
@Dao
interface ShopDao {
    
    // Products
    @Query("SELECT * FROM store_products WHERE isVisible = 1 AND status = 'active' ORDER BY publishDate DESC")
    fun getActiveProductsFlow(): Flow<List<StoreProduct>>
    
    @Query("SELECT * FROM store_products WHERE id = :productId")
    suspend fun getProductById(productId: String): StoreProduct?
    
    @Query("SELECT * FROM store_products WHERE productType = :type AND isVisible = 1")
    fun getProductsByTypeFlow(type: String): Flow<List<StoreProduct>>
    
    @Query("SELECT * FROM store_products WHERE isFeatured = 1 AND isVisible = 1")
    fun getFeaturedProductsFlow(): Flow<List<StoreProduct>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProduct(product: StoreProduct)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProducts(products: List<StoreProduct>)
    
    @Update
    suspend fun updateProduct(product: StoreProduct)
    
    @Delete
    suspend fun deleteProduct(product: StoreProduct)
    
    // Orders
    @Query("SELECT * FROM store_orders WHERE userId = :userId ORDER BY createdAt DESC")
    fun getUserOrdersFlow(userId: String): Flow<List<StoreOrder>>
    
    @Query("SELECT * FROM store_orders WHERE id = :orderId")
    suspend fun getOrderById(orderId: String): StoreOrder?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrder(order: StoreOrder)
    
    @Update
    suspend fun updateOrder(order: StoreOrder)
}
