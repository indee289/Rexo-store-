package com.rexo.marketplace.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

/**
 * Shop & Product Data Models
 */

enum class StoreProductType {
    FREE_RESOURCE,
    DIGITAL_PRODUCT,
    PHYSICAL_PRODUCT,
    SERVICE_PACKAGE,
    SUBSCRIPTION_PLAN
}

@Entity(tableName = "store_products")
@Serializable
data class StoreProduct(
    @PrimaryKey
    val id: String,
    val title: String,
    val productType: String,
    val category: String,
    val shortDescription: String,
    val fullDescription: String,
    val coverImage: String,
    val galleryImagesJson: String,  // JSON array
    val price: Double,
    val discountPrice: Double? = null,
    val stock: Int,
    val tagsJson: String,  // JSON array
    val featuresIncludedJson: String,  // JSON array
    val requirementsJson: String? = null,  // JSON array
    val status: String = "active",
    val publishDate: String,
    
    // Toggles
    val isFree: Boolean = false,
    val isPaid: Boolean = true,
    val isFeatured: Boolean = false,
    val isRecommended: Boolean = false,
    val isVisible: Boolean = true,
    
    // Digital Product
    val downloadUrl: String? = null,
    val driveUrl: String? = null,
    val fileType: String? = null,
    val licenseKey: String? = null,
    
    // Physical Product
    val weight: String? = null,
    val colorsJson: String? = null,  // JSON array
    val sizesJson: String? = null,   // JSON array
    val sku: String? = null,
    val shippingFee: Double? = null,
    val estimatedDelivery: String? = null,
    
    // Stats
    val rating: Double = 5.0,
    val salesCount: Int = 0,
    val viewsCount: Int = 0
)

@Entity(tableName = "store_orders")
@Serializable
data class StoreOrder(
    @PrimaryKey
    val id: String,
    val userId: String,
    val userName: String,
    val userEmail: String,
    val itemsJson: String,  // JSON array of StoreOrderItem
    val totalAmount: Double,
    val productType: String,
    val status: String = "pending",
    val shippingAddressJson: String? = null,  // JSON object
    val paymentMethod: String,
    val transactionRef: String,
    val createdAt: String,
    val unlockedAt: String? = null
)

@Serializable
data class ShippingAddress(
    val id: String,
    val userId: String,
    val fullName: String,
    val phone: String,
    val street: String,
    val landmark: String? = null,
    val city: String,
    val state: String,
    val pincode: String,
    val isDefault: Boolean = false,
    val type: String = "home"
)
