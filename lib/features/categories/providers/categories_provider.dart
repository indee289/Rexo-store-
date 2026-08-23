import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Provider for product categories from DB
final productCategoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('product_categories')
      .select()
      .order('sort_order', ascending: true);

  return List<Map<String, dynamic>>.from(response);
});

/// Provider for top-level categories (parent_id is null)
final topLevelCategoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final allCategories = await ref.watch(productCategoriesProvider.future);
  return allCategories
      .where((cat) => cat['parent_id'] == null)
      .toList();
});

/// Provider for subcategories of a given parent
final subCategoriesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, parentId) async {
  final allCategories = await ref.watch(productCategoriesProvider.future);
  return allCategories
      .where((cat) => cat['parent_id'] == parentId)
      .toList();
});
