import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/supabase_service.dart';

/// Provider for the current user's disputes list
final userDisputesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final response = await SupabaseService.client
      .from('disputes')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// State for creating a dispute
class DisputeFormState {
  final bool isSubmitting;
  final String? error;
  final bool success;

  const DisputeFormState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
  });

  DisputeFormState copyWith({
    bool? isSubmitting,
    String? error,
    bool? success,
  }) {
    return DisputeFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// StateNotifier for creating a new dispute
class DisputeNotifier extends StateNotifier<DisputeFormState> {
  DisputeNotifier() : super(const DisputeFormState());

  Future<bool> submitDispute({
    required String relatedType,
    required String relatedId,
    required String subject,
    required String description,
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
      final data = <String, dynamic>{
        'id': uuid.v4(),
        'user_id': user.id,
        'subject': subject,
        'description': description,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      };

      if (relatedType == 'Order') {
        data['order_id'] = relatedId;
      } else if (relatedType == 'Campaign') {
        data['campaign_id'] = relatedId;
      }

      await SupabaseService.client.from('disputes').insert(data);

      state = state.copyWith(isSubmitting: false, success: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const DisputeFormState();
  }
}

/// Provider for the dispute notifier
final disputeNotifierProvider =
    StateNotifierProvider<DisputeNotifier, DisputeFormState>((ref) {
  return DisputeNotifier();
});
