import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Fetch pending moderation queue items
final moderationQueueProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('moderation_queue')
      .select()
      .eq('status', 'pending')
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Fetch AI moderation logs
final aiModerationLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('ai_moderation_logs')
      .select()
      .order('created_at', ascending: false)
      .limit(50);

  return List<Map<String, dynamic>>.from(response);
});

/// Moderation action state
class ModerationActionState {
  final bool isLoading;
  final String? error;

  const ModerationActionState({
    this.isLoading = false,
    this.error,
  });

  ModerationActionState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ModerationActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Moderation action notifier for approve/reject
class ModerationActionNotifier extends StateNotifier<ModerationActionState> {
  final Ref _ref;

  ModerationActionNotifier(this._ref) : super(const ModerationActionState());

  /// Approve a moderation queue item
  Future<void> approveItem(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = SupabaseService.currentUser?.id;

      await SupabaseService.client
          .from('moderation_queue')
          .update({
            'status': 'approved',
            'reviewed_by': userId,
          })
          .eq('id', itemId);

      _ref.invalidate(moderationQueueProvider);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to approve item',
      );
    }
  }

  /// Reject a moderation queue item
  Future<void> rejectItem(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = SupabaseService.currentUser?.id;

      await SupabaseService.client
          .from('moderation_queue')
          .update({
            'status': 'rejected',
            'reviewed_by': userId,
          })
          .eq('id', itemId);

      _ref.invalidate(moderationQueueProvider);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reject item',
      );
    }
  }
}

/// Provider for moderation action notifier
final moderationActionProvider =
    StateNotifierProvider<ModerationActionNotifier, ModerationActionState>((ref) {
  return ModerationActionNotifier(ref);
});
