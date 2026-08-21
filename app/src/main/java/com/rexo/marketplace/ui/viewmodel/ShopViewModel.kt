package com.rexo.marketplace.ui.viewmodel

import androidx.compose.runtime.mutableStateListOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.repository.ShopRepository
import com.rexo.marketplace.utils.ErrorUtils
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

/**
 * Shop ViewModel
 * Manages products, cart (local), and orders.
 * Default constructor with repository defaulting to ShopRepository().
 */
class ShopViewModel(
    private val repository: ShopRepository = ShopRepository()
) : ViewModel() {

    // UI State
    private val _uiState = MutableStateFlow(ShopUiState())
    val uiState: StateFlow<ShopUiState> = _uiState.asStateFlow()

    // Products
    private val _products = MutableStateFlow<List<ProductData>>(emptyList())
    val products: StateFlow<List<ProductData>> = _products.asStateFlow()

    // Selected product for detail screen
    private val _selectedProduct = MutableStateFlow<ProductData?>(null)
    val selectedProduct: StateFlow<ProductData?> = _selectedProduct.asStateFlow()

    // Categories
    private val _categories = MutableStateFlow<List<String>>(listOf("All"))
    val categories: StateFlow<List<String>> = _categories.asStateFlow()

    // Search query
    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    // Selected category
    private val _selectedCategory = MutableStateFlow("All")
    val selectedCategory: StateFlow<String> = _selectedCategory.asStateFlow()

    // Cart - managed locally
    private val _cartItems = MutableStateFlow<List<CartItemData>>(emptyList())
    val cartItems: StateFlow<List<CartItemData>> = _cartItems.asStateFlow()

    // Orders
    private val _orders = MutableStateFlow<List<OrderData>>(emptyList())
    val orders: StateFlow<List<OrderData>> = _orders.asStateFlow()

    // Cart count for badge
    val cartCount: StateFlow<Int> = _cartItems.map { items ->
        items.sumOf { it.quantity }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    // Cart Total
    val cartTotal: StateFlow<Double> = _cartItems.map { items ->
        items.sumOf { it.price * it.quantity }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0.0)

    init {
        loadProducts()
        loadCategories()
    }

    fun loadProducts() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val category = _selectedCategory.value
                val search = _searchQuery.value
                val result = repository.getProducts(category, search)
                _products.value = result
                _uiState.update { it.copy(isLoading = false) }
            } catch (e: Exception) {
                _products.value = emptyList()
                _uiState.update {
                    it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message))
                }
            }
        }
    }

    private fun loadCategories() {
        viewModelScope.launch {
            try {
                val cats = repository.getCategories()
                _categories.value = cats
            } catch (_: Exception) {
                _categories.value = listOf("All")
            }
        }
    }

    fun updateSearchQuery(query: String) {
        _searchQuery.value = query
        loadProducts()
    }

    fun selectCategory(category: String) {
        _selectedCategory.value = category
        loadProducts()
    }

    fun loadProductById(productId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val product = repository.getProductById(productId)
                _selectedProduct.value = product
                _uiState.update { it.copy(isLoading = false) }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message))
                }
            }
        }
    }

    fun addToCart(product: ProductData, quantity: Int = 1) {
        val currentCart = _cartItems.value.toMutableList()
        val existingIndex = currentCart.indexOfFirst { it.productId == product.id }

        if (existingIndex >= 0) {
            val existing = currentCart[existingIndex]
            currentCart[existingIndex] = existing.copy(quantity = existing.quantity + quantity)
        } else {
            currentCart.add(
                CartItemData(
                    id = "cart_${product.id}",
                    productId = product.id,
                    name = product.title,
                    price = product.discountPrice ?: product.price,
                    quantity = quantity,
                    imageUrl = product.coverImage
                )
            )
        }
        _cartItems.value = currentCart
        _uiState.update {
            it.copy(showSuccess = true, successMessage = "Added to cart!")
        }
    }

    fun updateCartItemQuantity(itemId: String, quantity: Int) {
        if (quantity <= 0) {
            removeFromCart(itemId)
            return
        }
        val currentCart = _cartItems.value.toMutableList()
        val index = currentCart.indexOfFirst { it.id == itemId }
        if (index >= 0) {
            currentCart[index] = currentCart[index].copy(quantity = quantity)
            _cartItems.value = currentCart
        }
    }

    fun removeFromCart(itemId: String) {
        _cartItems.value = _cartItems.value.filter { it.id != itemId }
    }

    fun clearCart() {
        _cartItems.value = emptyList()
    }

    fun placeOrder(shippingAddress: ShippingAddress, paymentMethod: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true, error = null) }
            try {
                val items = _cartItems.value
                val total = items.sumOf { it.price * it.quantity }
                repository.placeOrder(items, total, shippingAddress, paymentMethod)
                _cartItems.value = emptyList()
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        showSuccess = true,
                        successMessage = "Order placed successfully!"
                    )
                }
                loadOrders()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isProcessing = false, error = ErrorUtils.sanitizeErrorMessage(e.message))
                }
            }
        }
    }

    fun loadOrders() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                _orders.value = repository.getOrders()
                _uiState.update { it.copy(isLoading = false) }
            } catch (e: Exception) {
                _orders.value = emptyList()
                _uiState.update {
                    it.copy(isLoading = false, error = ErrorUtils.sanitizeErrorMessage(e.message))
                }
            }
        }
    }

    fun clearSuccess() {
        _uiState.update { it.copy(showSuccess = false, successMessage = null) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class ShopUiState(
    val isLoading: Boolean = false,
    val isProcessing: Boolean = false,
    val error: String? = null,
    val showSuccess: Boolean = false,
    val successMessage: String? = null
)

data class ProductData(
    val id: String,
    val title: String,
    val price: Double,
    val stock: Int,
    val category: String,
    val description: String,
    val coverImage: String?,
    val discountPrice: Double?,
    val status: String
)

data class CartItemData(
    val id: String,
    val productId: String,
    val name: String,
    val price: Double,
    val quantity: Int,
    val imageUrl: String?
)

data class OrderData(
    val id: String,
    val items: List<String>,
    val total: Double,
    val status: String,
    val createdAt: String,
    val shippingAddress: String = "",
    val paymentMethod: String = ""
)

data class ShippingAddress(
    val name: String,
    val phone: String,
    val address: String,
    val city: String,
    val state: String,
    val pincode: String
)
