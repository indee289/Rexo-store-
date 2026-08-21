package com.rexo.marketplace.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rexo.marketplace.data.repository.ShopRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.Date

/**
 * Shop ViewModel
 * Manages products, cart, orders
 */
class ShopViewModel(
    private val repository: ShopRepository
) : ViewModel() {

    // UI State
    private val _uiState = MutableStateFlow(ShopUiState())
    val uiState: StateFlow<ShopUiState> = _uiState.asStateFlow()

    // Cart
    private val _cartItems = MutableStateFlow<List<CartItemData>>(emptyList())
    val cartItems: StateFlow<List<CartItemData>> = _cartItems.asStateFlow()

    // Orders
    private val _orders = MutableStateFlow<List<OrderData>>(emptyList())
    val orders: StateFlow<List<OrderData>> = _orders.asStateFlow()

    // Cart Total
    val cartTotal: StateFlow<Double> = _cartItems.map { items ->
        items.sumOf { it.price * it.quantity }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(), 0.0)

    init {
        loadCart()
        loadOrders()
    }

    fun loadCart() {
        viewModelScope.launch {
            try {
                _cartItems.value = repository.getCartItems()
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
            }
        }
    }

    fun loadOrders() {
        viewModelScope.launch {
            try {
                _orders.value = repository.getOrders()
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
            }
        }
    }

    fun addToCart(productId: String, quantity: Int = 1) {
        viewModelScope.launch {
            try {
                repository.addToCart(productId, quantity)
                loadCart()
                _uiState.update { 
                    it.copy(
                        showSuccess = true,
                        successMessage = "Added to cart!"
                    ) 
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
            }
        }
    }

    fun updateCartItemQuantity(itemId: String, quantity: Int) {
        viewModelScope.launch {
            try {
                if (quantity <= 0) {
                    removeFromCart(itemId)
                } else {
                    repository.updateCartQuantity(itemId, quantity)
                    loadCart()
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
            }
        }
    }

    fun removeFromCart(itemId: String) {
        viewModelScope.launch {
            try {
                repository.removeFromCart(itemId)
                loadCart()
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
            }
        }
    }

    fun clearCart() {
        viewModelScope.launch {
            try {
                repository.clearCart()
                loadCart()
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
            }
        }
    }

    fun checkout() {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true) }
            try {
                repository.checkout()
                loadCart()
                loadOrders()
                _uiState.update { 
                    it.copy(
                        isProcessing = false,
                        showSuccess = true,
                        successMessage = "Order placed successfully!"
                    ) 
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(isProcessing = false, error = e.message) 
                }
            }
        }
    }

    fun reorder(orderId: String) {
        viewModelScope.launch {
            try {
                repository.reorder(orderId)
                loadCart()
                _uiState.update { 
                    it.copy(
                        showSuccess = true,
                        successMessage = "Items added to cart!"
                    ) 
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
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
    val date: Date
)
