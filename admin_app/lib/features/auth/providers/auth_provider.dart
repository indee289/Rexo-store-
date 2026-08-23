import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? userProfile;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.userProfile,
  });

  bool get isAdmin => userProfile?['role'] == 'admin';

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    Map<String, dynamic>? userProfile,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      final profile = await SupabaseService.getUserProfile(user.id);
      if (profile != null && profile['role'] == 'admin') {
        state = AuthState(
          status: AuthStatus.authenticated,
          userProfile: profile,
        );
      } else {
        await SupabaseService.signOut();
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user == null) {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Sign in failed. Please try again.',
        );
        return;
      }

      // Fetch user profile to check role
      final profile =
          await SupabaseService.getUserProfile(response.user!.id);

      if (profile == null || profile['role'] != 'admin') {
        // Not an admin - sign out and reject
        await SupabaseService.signOut();
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Access denied. Admin privileges required.',
        );
        return;
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        userProfile: profile,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
