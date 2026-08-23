import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Provider to fetch addresses for the current user
final addressesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final response = await SupabaseService.client
      .from('addresses')
      .select()
      .eq('user_id', user.id)
      .order('is_default', ascending: false)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Addresses actions notifier for CRUD
class AddressesNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  AddressesNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Add a new address
  Future<bool> addAddress({
    required String name,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String pincode,
    bool isDefault = false,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    this.state = const AsyncValue.loading();

    try {
      // If marking as default, unset other defaults first
      if (isDefault) {
        await SupabaseService.client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', user.id);
      }

      await SupabaseService.client.from('addresses').insert({
        'user_id': user.id,
        'name': name,
        'phone': phone,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'pincode': pincode,
        'is_default': isDefault,
      });

      this.state = const AsyncValue.data(null);
      ref.invalidate(addressesProvider);
      return true;
    } catch (e, st) {
      this.state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Update an existing address
  Future<bool> updateAddress({
    required String addressId,
    required String name,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String pincode,
    bool isDefault = false,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    this.state = const AsyncValue.loading();

    try {
      if (isDefault) {
        await SupabaseService.client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', user.id);
      }

      await SupabaseService.client.from('addresses').update({
        'name': name,
        'phone': phone,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'pincode': pincode,
        'is_default': isDefault,
      }).eq('id', addressId);

      this.state = const AsyncValue.data(null);
      ref.invalidate(addressesProvider);
      return true;
    } catch (e, st) {
      this.state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String addressId) async {
    this.state = const AsyncValue.loading();

    try {
      await SupabaseService.client
          .from('addresses')
          .delete()
          .eq('id', addressId);

      this.state = const AsyncValue.data(null);
      ref.invalidate(addressesProvider);
      return true;
    } catch (e, st) {
      this.state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Addresses actions provider
final addressesActionsProvider =
    StateNotifierProvider<AddressesNotifier, AsyncValue<void>>((ref) {
  return AddressesNotifier(ref);
});
