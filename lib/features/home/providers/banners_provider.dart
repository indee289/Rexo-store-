import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Live banners for the home carousel — only visible ones, sorted by sort_order.
final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await SupabaseService.client.rpc('get_banners');
    return List<Map<String, dynamic>>.from(response as List);
  } catch (_) {
    return [];
  }
});

/// All banners for admin (including hidden).
final adminBannersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client.rpc('get_all_banners');
  return List<Map<String, dynamic>>.from(response as List);
});

/// Banner actions notifier.
class BannersActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  BannersActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> createBanner(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .rpc('create_banner', params: {'p_data': data});
      state = const AsyncValue.data(null);
      ref.invalidate(adminBannersProvider);
      ref.invalidate(bannersProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateBanner(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .rpc('update_banner', params: {'p_id': id, 'p_data': data});
      state = const AsyncValue.data(null);
      ref.invalidate(adminBannersProvider);
      ref.invalidate(bannersProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleVisibility(String id, bool current) async {
    return updateBanner(id, {'is_visible': !current});
  }

  Future<bool> deleteBanner(String id) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client
          .rpc('delete_banner', params: {'p_id': id});
      state = const AsyncValue.data(null);
      ref.invalidate(adminBannersProvider);
      ref.invalidate(bannersProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final bannersActionsProvider =
    StateNotifierProvider<BannersActionsNotifier, AsyncValue<void>>(
        (ref) => BannersActionsNotifier(ref));
