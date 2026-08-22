import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Provider for a seller profile by user_id
final sellerProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, userId) async {
  final response = await SupabaseService.client
      .from('seller_profiles')
      .select()
      .eq('user_id', userId)
      .maybeSingle();

  return response;
});

/// Provider for a seller's products
final sellerProductsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, sellerId) async {
  final response = await SupabaseService.client
      .from('products')
      .select()
      .eq('is_active', true)
      .order('created_at', ascending: false);

  // Filter client-side since products table may not have seller_id
  // If products had seller_id, we would filter by it directly
  return List<Map<String, dynamic>>.from(response);
});
