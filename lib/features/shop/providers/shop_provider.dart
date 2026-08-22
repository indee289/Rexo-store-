import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/supabase_service.dart';

/// Category filter provider for shop
final shopCategoryFilter = StateProvider<String>((ref) => 'All');

/// Provider for all active products
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final category = ref.watch(shopCategoryFilter);

  var query = SupabaseService.client
      .from('products')
      .select()
      .eq('is_active', true);

  if (category != 'All') {
    query = query.eq('category', category);
  }

  final response = await query.order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Provider for single product detail
final productDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final response = await SupabaseService.client
      .from('products')
      .select()
      .eq('id', id)
      .maybeSingle();

  return response;
});

/// Cart item model
class CartItem {
  final Map<String, dynamic> product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get subtotal {
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    return price * quantity;
  }
}

/// Cart state notifier
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Add a product to cart
  void addToCart(Map<String, dynamic> product, {int quantity = 1}) {
    final existingIndex = state.indexWhere(
      (item) => item.product['id'] == product['id'],
    );

    if (existingIndex >= 0) {
      final updatedItems = [...state];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + quantity,
      );
      state = updatedItems;
    } else {
      state = [...state, CartItem(product: product, quantity: quantity)];
    }
  }

  /// Remove a product from cart
  void removeFromCart(String productId) {
    state = state.where((item) => item.product['id'] != productId).toList();
  }

  /// Update quantity of a product
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final updatedItems = state.map((item) {
      if (item.product['id'] == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = updatedItems;
  }

  /// Clear entire cart
  void clearCart() {
    state = [];
  }

  /// Get total amount
  double get totalAmount {
    return state.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Get total item count
  int get totalItems {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

/// Total amount provider
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.subtotal);
});

/// Total items count provider
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

/// Place order function
Future<bool> placeOrder({
  required List<CartItem> items,
  required double totalAmount,
  required Map<String, dynamic>? shippingAddress,
  required String paymentMethod,
}) async {
  try {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    const uuid = Uuid();
    final orderId = uuid.v4();

    // Create order
    await SupabaseService.client.from('orders').insert({
      'id': orderId,
      'user_id': user.id,
      'total_amount': totalAmount,
      'status': 'pending',
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Create order items
    final orderItems = items.map((item) {
      return {
        'id': uuid.v4(),
        'order_id': orderId,
        'product_id': item.product['id'],
        'quantity': item.quantity,
        'price': item.product['price'],
      };
    }).toList();

    await SupabaseService.client.from('order_items').insert(orderItems);

    return true;
  } catch (e) {
    return false;
  }
}
