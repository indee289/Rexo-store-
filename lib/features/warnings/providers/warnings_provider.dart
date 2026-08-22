import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Fetch user warnings for the current user
final userWarningsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return [];

  final response = await SupabaseService.client
      .from('user_warnings')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Fetch active suspensions for the current user
final userSuspensionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return [];

  final response = await SupabaseService.client
      .from('user_suspensions')
      .select()
      .eq('user_id', userId)
      .eq('is_active', true)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Appeal state
class AppealState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const AppealState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  AppealState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return AppealState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Appeal notifier for submitting suspension appeals
class AppealNotifier extends StateNotifier<AppealState> {
  final Ref _ref;

  AppealNotifier(this._ref) : super(const AppealState());

  /// Submit an appeal for a suspension
  Future<void> submitAppeal({
    required String suspensionId,
    required String appealText,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await SupabaseService.client
          .from('user_suspensions')
          .update({
            'appeal_text': appealText,
            'appeal_status': 'pending',
          })
          .eq('id', suspensionId);

      _ref.invalidate(userSuspensionsProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit appeal',
      );
    }
  }

  /// Reset state
  void reset() {
    state = const AppealState();
  }
}

/// Provider for appeal notifier
final appealNotifierProvider =
    StateNotifierProvider<AppealNotifier, AppealState>((ref) {
  return AppealNotifier(ref);
});
