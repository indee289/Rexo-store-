import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Fetch active sessions for the current user
final userSessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return [];

  final response = await SupabaseService.client
      .from('user_sessions')
      .select()
      .eq('user_id', userId)
      .eq('is_active', true)
      .order('last_active_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Fetch user devices for the current user
final userDevicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return [];

  final response = await SupabaseService.client
      .from('user_devices')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Sessions state for mutations
class SessionsState {
  final bool isLoading;
  final String? error;

  const SessionsState({
    this.isLoading = false,
    this.error,
  });

  SessionsState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return SessionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Sessions notifier for terminate actions
class SessionsNotifier extends StateNotifier<SessionsState> {
  final Ref _ref;

  SessionsNotifier(this._ref) : super(const SessionsState());

  /// Terminate a specific session by ID — hard-deletes the row so it
  /// actually disappears (a soft `is_active=false` update could silently
  /// affect 0 rows and the session would reappear on refresh).
  Future<void> terminateSession(String sessionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await SupabaseService.client
          .from('user_sessions')
          .delete()
          .eq('id', sessionId);

      _ref.invalidate(userSessionsProvider);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to terminate session',
      );
    }
  }

  /// Terminate all sessions except the current (most recently active) one.
  /// The current session is identified as the most recent `last_active_at`
  /// row (the Supabase JWT access token is NOT the session row id, so it
  /// cannot be used to exclude the current row).
  Future<void> terminateAllOtherSessions() async {
    state = state.copyWith(isLoading: true, error: null);

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(isLoading: false, error: 'Not authenticated');
      return;
    }

    try {
      // Fetch this user's sessions, newest first; keep the newest (current).
      final rows = await SupabaseService.client
          .from('user_sessions')
          .select('id')
          .eq('user_id', userId)
          .order('last_active_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(rows);
      // Skip the first (current) session; delete the rest by id.
      for (var i = 1; i < list.length; i++) {
        final id = (list[i]['id'] ?? '').toString();
        if (id.isEmpty) continue;
        await SupabaseService.client
            .from('user_sessions')
            .delete()
            .eq('id', id);
      }

      _ref.invalidate(userSessionsProvider);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to terminate sessions',
      );
    }
  }
}

/// Provider for sessions notifier
final sessionsNotifierProvider =
    StateNotifierProvider<SessionsNotifier, SessionsState>((ref) {
  return SessionsNotifier(ref);
});
