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

  /// Terminate a specific session by ID
  Future<void> terminateSession(String sessionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await SupabaseService.client
          .from('user_sessions')
          .update({'is_active': false})
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

  /// Terminate all sessions except the current one
  Future<void> terminateAllOtherSessions() async {
    state = state.copyWith(isLoading: true, error: null);

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(isLoading: false, error: 'Not authenticated');
      return;
    }

    try {
      // Get current session ID from Supabase auth
      final currentSessionToken = SupabaseService.client.auth.currentSession?.accessToken;

      await SupabaseService.client
          .from('user_sessions')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('is_active', true)
          .neq('id', currentSessionToken ?? '');

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
