package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.ui.viewmodel.*
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable

/**
 * Shop Repository
 * Handles product catalog, cart, and order operations with Supabase.
 * No mock data fallback - shows proper error/empty states.
 */
class ShopRepository {

    private fun getCurrentUserId(): String? {
        return SupabaseClient.auth.currentUserOrNull()?.id
    }

    /**
     * Fetch all products from Supabase 'store_products' table.
     */
    suspend fun getProducts(
        category: String = "All",
        searchQuery: String = ""
    ): List<ProductData> = withContext(Dispatchers.IO) {
        val results = SupabaseClient.client.from("store_products").select()
            .decodeList<StoreProductDto>()

        results
            .filter { dto ->
                if (category != "All") dto.category.equals(category, ignoreCase = true) else true
            }
            .filter { dto ->
                if (searchQuery.isNotBlank()) {
                    dto.title.contains(searchQuery, ignoreCase = true) ||
                        (dto.description ?: "").contains(searchQuery, ignoreCase = true)
                } else true
            }
            .map { it.toProductData() }
    }

    /**
     * Fetch a single product by ID.
     */
    suspend fun getProductById(productId: String): ProductData? = withContext(Dispatchers.IO) {
        try {
            val dto = SupabaseClient.client.from("store_products").select {
                filter { eq("id", productId) }
            }.decodeSingle<StoreProductDto>()
            dto.toProductData()
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Fetch unique product categories.
     */
    suspend fun getCategories(): List<String> = withContext(Dispatchers.IO) {
        val results = SupabaseClient.client.from("store_products").select()
            .decodeList<StoreProductDto>()
        val categories = results.map { it.category }.distinct().sorted()
        listOf("All") + categories
    }

    /**
     * Place an order in the 'store_orders' table.
     */
    suspend fun placeOrder(
        items: List<CartItemData>,
        total: Double,
        shippingAddress: ShippingAddress,
        paymentMethod: String
    ): String = withContext(Dispatchers.IO) {
        val userId = getCurrentUserId()
            ?: throw Exception("Please sign in to place an order")

        val orderId = "ORD-${System.currentTimeMillis()}-${userId.take(8)}"
        val itemsJson = items.joinToString(", ") { "${it.name} x${it.quantity}" }

        val orderDto = StoreOrderInsertDto(
            id = orderId,
            user_id = userId,
            total_amount = total,
            status = "placed",
            shipping_address = "${shippingAddress.name}, ${shippingAddress.address}, ${shippingAddress.city}, ${shippingAddress.state} - ${shippingAddress.pincode}, Ph: ${shippingAddress.phone}",
            payment_method = paymentMethod,
            items_json = itemsJson
        )

        SupabaseClient.client.from("store_orders").insert(orderDto)
        orderId
    }

    /**
     * Fetch orders for the current user.
     */
    suspend fun getOrders(): List<OrderData> = withContext(Dispatchers.IO) {
        val userId = getCurrentUserId() ?: return@withContext emptyList()
        val results = SupabaseClient.client.from("store_orders").select {
            filter { eq("user_id", userId) }
        }.decodeList<StoreOrderDto>()

        results.map { it.toOrderData() }.sortedByDescending { it.createdAt }
    }

    /**
     * Fetch a single order by ID.
     */
    suspend fun getOrderById(orderId: String): OrderData? = withContext(Dispatchers.IO) {
        try {
            val dto = SupabaseClient.client.from("store_orders").select {
                filter { eq("id", orderId) }
            }.decodeSingle<StoreOrderDto>()
            dto.toOrderData()
        } catch (e: Exception) {
            null
        }
    }
}

/**
 * DTO matching Supabase 'store_products' table.
 */
@Serializable
data class StoreProductDto(
    val id: String,
    val title: String,
    val price: Double,
    val stock: Int = 0,
    val category: String = "",
    val description: String? = null,
    val cover_image: String? = null,
    val discount_price: Double? = null,
    val status: String = "active"
) {
    fun toProductData() = ProductData(
        id = id,
        title = title,
        price = price,
        stock = stock,
        category = category,
        description = description ?: "",
        coverImage = cover_image,
        discountPrice = discount_price,
        status = status
    )
}

/**
 * DTO for inserting an order into 'store_orders' table.
 */
@Serializable
data class StoreOrderInsertDto(
    val id: String,
    val user_id: String,
    val total_amount: Double,
    val status: String = "placed",
    val shipping_address: String,
    val payment_method: String,
    val items_json: String
)

/**
 * DTO for reading orders from 'store_orders' table.
 */
@Serializable
data class StoreOrderDto(
    val id: String,
    val user_id: String,
    val total_amount: Double,
    val status: String = "placed",
    val shipping_address: String? = null,
    val payment_method: String? = null,
    val items_json: String? = null,
    val created_at: String? = null
) {
    fun toOrderData() = OrderData(
        id = id,
        items = items_json?.split(", ") ?: emptyList(),
        total = total_amount,
        status = status,
        createdAt = created_at ?: "",
        shippingAddress = shipping_address ?: "",
        paymentMethod = payment_method ?: ""
    )
}
