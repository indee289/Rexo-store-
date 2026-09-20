import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/error_utils.dart';
import '../../../services/supabase_service.dart';

/// Provider for user's service listings
final userServicesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final response = await SupabaseService.client
      .from('services')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Provider for all active services (UGC marketplace)
final activeServicesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('services')
      .select()
      .eq('is_active', true)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// State for service creation
class ServiceFormState {
  final bool isSubmitting;
  final String? error;
  final bool success;

  const ServiceFormState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
  });

  ServiceFormState copyWith({
    bool? isSubmitting,
    String? error,
    bool? success,
  }) {
    return ServiceFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// StateNotifier for creating/updating services
class ServiceNotifier extends StateNotifier<ServiceFormState> {
  ServiceNotifier() : super(const ServiceFormState());

  Future<bool> createService({
    required String serviceType,
    required String title,
    required String description,
    required double price,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null, success: false);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'User not authenticated',
        );
        return false;
      }

      const uuid = Uuid();
      await SupabaseService.client.from('services').insert({
        'id': uuid.v4(),
        'user_id': user.id,
        'service_type': serviceType,
        'title': title,
        'description': description,
        'price': price,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      state = state.copyWith(isSubmitting: false, success: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: ErrorUtils.sanitize(e),
      );
      return false;
    }
  }

  Future<bool> updateService({
    required String serviceId,
    required Map<String, dynamic> data,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null, success: false);

    try {
      await SupabaseService.client
          .from('services')
          .update(data)
          .eq('id', serviceId);

      state = state.copyWith(isSubmitting: false, success: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: ErrorUtils.sanitize(e),
      );
      return false;
    }
  }

  void reset() {
    state = const ServiceFormState();
  }
}

/// Provider for the service notifier
final serviceNotifierProvider =
    StateNotifierProvider<ServiceNotifier, ServiceFormState>((ref) {
  return ServiceNotifier();
});
