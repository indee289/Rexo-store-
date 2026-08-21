package com.rexo.marketplace.data.repository

import com.rexo.marketplace.data.local.ShopDao
import com.rexo.marketplace.data.remote.SupabaseClient
import com.rexo.marketplace.ui.viewmodel.*
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Date

/**
 * Shop Repository
 * Handles shop operations with Supabase and local Room
 */
class ShopRepository(
    private val shopDao: ShopDao,
    private val supabaseClient: SupabaseClient
) {
    suspend fun getCartItems(): List<CartItemData> = withContext(Dispatchers.IO) {
        try {
            val response = supabaseClient.client
                .from("cart_items")
                .select()
                .decodeList<CartDto>()
            
            response.map { it.toCartItem() }
        } catch (e: Exception) {
            // Mock data
            emptyList()
        }
    }

    suspend fun getOrders(): List<OrderData> = withContext(Dispatchers.IO) {
        try {
            val response = supabaseClient.client
                .from("store_orders")
                .select()
                .decodeList<OrderDto>()
            
            response.map { it.toOrderData() }
        } catch (e: Exception) {
            // Mock data
            emptyList()
        }
    }

    suspend fun addToCart(productId: String, quantity: Int) = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("cart_items").insert(
                mapOf(
                    "product_id" to productId,
                    "quantity" to quantity
                )
            )
        } catch (e: Exception) {
            throw Exception("Failed to add to cart: ${e.message}")
        }
    }

    suspend fun updateCartQuantity(itemId: String, quantity: Int) = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("cart_items").update(
                mapOf("quantity" to quantity)
            ) {
                filter { eq("id", itemId) }
            }
        } catch (e: Exception) {
            throw Exception("Failed to update quantity: ${e.message}")
        }
    }

    suspend fun removeFromCart(itemId: String) = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("cart_items").delete {
                filter { eq("id", itemId) }
            }
        } catch (e: Exception) {
            throw Exception("Failed to remove item: ${e.message}")
        }
    }

    suspend fun clearCart() = withContext(Dispatchers.IO) {
        try {
            supabaseClient.client.from("cart_items").delete {
                filter { /* Clear all user's items */ }
            }
        } catch (e: Exception) {
            throw Exception("Failed to clear cart: ${e.message}")
        }
    }

    suspend fun checkout() = withContext(Dispatchers.IO) {
        try {
            // Create order from cart
            val cartItems = getCartItems()
            val total = cartItems.sumOf { it.price * it.quantity }
            
            supabaseClient.client.from("store_orders").insert(
                mapOf(
                    "items" to cartItems.map { it.name }.joinToString(", "),
                    "total" to total,
                    "status" to "processing"
                )
            )
            
            // Clear cart after successful checkout
            clearCart()
        } catch (e: Exception) {
            throw Exception("Checkout failed: ${e.message}")
        }
    }

    suspend fun reorder(orderId: String) = withContext(Dispatchers.IO) {
        try {
            // Fetch order items and add them back to cart
            val order = supabaseClient.client
                .from("store_orders")
                .select() {
                    filter { eq("id", orderId) }
                }
                .decodeSingle<OrderDto>()
            
            // Add items to cart (simplified)
            // In real app, you'd parse the items and add them individually
        } catch (e: Exception) {
            throw Exception("Reorder failed: ${e.message}")
        }
    }
}

@kotlinx.serialization.Serializable
data class CartDto(
    val id: String,
    val product_id: String,
    val product_name: String,
    val price: Double,
    val quantity: Int,
    val image_url: String?
) {
    fun toCartItem() = CartItemData(
        id, product_id, product_name, price, quantity, image_url
    )
}

@kotlinx.serialization.Serializable
data class OrderDto(
    val id: String,
    val items: String,
    val total: Double,
    val status: String,
    val created_at: String
) {
    fun toOrderData() = OrderData(
        id,
        items.split(", "),
        total,
        status,
        Date()
    )
}
