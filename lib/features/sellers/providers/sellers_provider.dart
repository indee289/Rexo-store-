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
