import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Live banners for the home carousel — only visible ones, sorted by sort_order.
final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await SupabaseService.client
        .from('banners')
        .select()
        .eq('is_visible', true)
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  } catch (_) {
    return [];
  }
});

/// All banners for admin (including hidden).
final adminBannersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('banners')
      .select()
      .order('sort_order', ascending: true);
  return List<Map<String, dynamic>>.from(response);
});

/// Banner actions notifier.
class BannersActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  BannersActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> createBanner(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseService.currentUser;
      await SupabaseService.client.from('banners').insert({
        ...data,
        'created_by': user?.id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
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
      await SupabaseService.client.from('banners').update({
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
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
      await SupabaseService.client.from('banners').delete().eq('id', id);
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
