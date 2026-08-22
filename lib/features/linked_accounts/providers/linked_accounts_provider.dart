import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Provider to fetch linked accounts for the current user
final linkedAccountsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final response = await SupabaseService.client
      .from('linked_accounts')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Linked accounts actions notifier
class LinkedAccountsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  LinkedAccountsNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Save or update a linked account
  Future<bool> saveAccount({
    required String platform,
    required String handle,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    state = const AsyncValue.loading();

    try {
      // Check if account already exists for this platform
      final existing = await SupabaseService.client
          .from('linked_accounts')
          .select()
          .eq('user_id', user.id)
          .eq('platform', platform)
          .maybeSingle();

      if (existing != null) {
        // Update existing
        await SupabaseService.client
            .from('linked_accounts')
            .update({'handle': handle})
            .eq('id', existing['id']);
      } else {
        // Insert new
        await SupabaseService.client.from('linked_accounts').insert({
          'user_id': user.id,
          'platform': platform,
          'handle': handle,
        });
      }

      state = const AsyncValue.data(null);
      ref.invalidate(linkedAccountsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete a linked account
  Future<bool> deleteAccount(String accountId) async {
    state = const AsyncValue.loading();

    try {
      await SupabaseService.client
          .from('linked_accounts')
          .delete()
          .eq('id', accountId);

      state = const AsyncValue.data(null);
      ref.invalidate(linkedAccountsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Linked accounts actions provider
final linkedAccountsActionsProvider =
    StateNotifierProvider<LinkedAccountsNotifier, AsyncValue<void>>((ref) {
  return LinkedAccountsNotifier(ref);
});
