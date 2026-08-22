import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Provider to check if current user has an approved Rexo Program application
final isRexoProgramApprovedProvider = FutureProvider<bool>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return false;

  final response = await SupabaseService.client
      .from('rexo_program_applications')
      .select('id')
      .eq('creator_id', user.id)
      .eq('status', 'approved')
      .maybeSingle();

  return response != null;
});

/// Provider to get current user's rexo program application status
final rexoProgramStatusProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  final response = await SupabaseService.client
      .from('rexo_program_applications')
      .select()
      .eq('creator_id', user.id)
      .order('applied_at', ascending: false)
      .limit(1)
      .maybeSingle();

  return response;
});

/// Provider to check if a user can add products
/// (admin, brand, or approved rexo program creator)
final canAddProductsProvider = FutureProvider<bool>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return false;

  final profile = await SupabaseService.getUserProfile(user.id);
  if (profile == null) return false;

  final role = profile['role'] ?? 'creator';

  // Admin can always add products
  if (role == 'admin') return true;

  // Brands can add products
  if (role == 'brand') return true;

  // Creators with approved Rexo Program can add products
  if (role == 'creator') {
    final rexoApp = await SupabaseService.client
        .from('rexo_program_applications')
        .select('id')
        .eq('creator_id', user.id)
        .eq('status', 'approved')
        .maybeSingle();
    return rexoApp != null;
  }

  return false;
});

/// All Rexo Program applications (admin view)
final adminRexoProgramProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('rexo_program_applications')
      .select('*, users:creator_id(name, email, handle)')
      .order('applied_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Rexo Program actions notifier
class RexoProgramNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  RexoProgramNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Apply for Rexo Program
  Future<bool> applyForProgram() async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    state = const AsyncValue.loading();

    try {
      await SupabaseService.client.from('rexo_program_applications').insert({
        'creator_id': user.id,
        'status': 'pending',
        'applied_at': DateTime.now().toIso8601String(),
      });

      state = const AsyncValue.data(null);
      ref.invalidate(rexoProgramStatusProvider);
      ref.invalidate(canAddProductsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Approve application (admin)
  Future<bool> approveApplication(String applicationId) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    state = const AsyncValue.loading();

    try {
      await SupabaseService.client
          .from('rexo_program_applications')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': user.id,
          })
          .eq('id', applicationId);

      state = const AsyncValue.data(null);
      ref.invalidate(adminRexoProgramProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Reject application (admin)
  Future<bool> rejectApplication(String applicationId) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    state = const AsyncValue.loading();

    try {
      await SupabaseService.client
          .from('rexo_program_applications')
          .update({
            'status': 'rejected',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': user.id,
          })
          .eq('id', applicationId);

      state = const AsyncValue.data(null);
      ref.invalidate(adminRexoProgramProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Rexo Program actions provider
final rexoProgramActionsProvider =
    StateNotifierProvider<RexoProgramNotifier, AsyncValue<void>>((ref) {
  return RexoProgramNotifier(ref);
});
