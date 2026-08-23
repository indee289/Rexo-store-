import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Provider for the current user's orders list
final userOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final response = await SupabaseService.client
      .from('orders')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Provider for a single order detail with items
final orderDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, orderId) async {
  final order = await SupabaseService.client
      .from('orders')
      .select()
      .eq('id', orderId)
      .maybeSingle();

  if (order == null) return null;

  final items = await SupabaseService.client
      .from('order_items')
      .select()
      .eq('order_id', orderId);

  return {
    ...order,
    'items': List<Map<String, dynamic>>.from(items),
  };
});

/// Order status progression
class OrderStatus {
  static const List<String> progression = [
    'pending',
    'confirmed',
    'shipped',
    'out_for_delivery',
    'delivered',
  ];

  static const Map<String, String> labels = {
    'pending': 'Placed',
    'confirmed': 'Confirmed',
    'shipped': 'Shipped',
    'out_for_delivery': 'Out for Delivery',
    'delivered': 'Delivered',
  };

  static int getIndex(String status) {
    return progression.indexOf(status.toLowerCase());
  }

  static String getLabel(String status) {
    return labels[status.toLowerCase()] ?? status;
  }
}
