import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/utils/error_utils.dart';
import '../../../services/supabase_service.dart';
import '../../device_fingerprint/providers/device_fingerprint_provider.dart';

/// Auth state enum
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Auth state model
class AuthState {
  final AuthStatus status;
  final supabase.User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    supabase.User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _initialize();
  }

  void _initialize() {
    // Check current auth state
    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: currentUser,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }

    // Listen to auth state changes
    _authSubscription = SupabaseService.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      switch (event) {
        case supabase.AuthChangeEvent.signedIn:
          state = AuthState(
            status: AuthStatus.authenticated,
            user: session?.user,
          );
          break;
        case supabase.AuthChangeEvent.signedOut:
          state = const AuthState(status: AuthStatus.unauthenticated);
          break;
        case supabase.AuthChangeEvent.tokenRefreshed:
          state = AuthState(
            status: AuthStatus.authenticated,
            user: session?.user,
          );
          break;
        default:
          break;
      }
    });
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
        // Record device fingerprint after successful login
        _recordDeviceFingerprint();
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Sign in failed. Please try again.',
        );
      }
    } on supabase.AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Record device fingerprint after login
  void _recordDeviceFingerprint() {
    try {
      _ref.read(deviceFingerprintProvider.notifier).recordDeviceFingerprint();
    } catch (_) {
      // Non-critical - don't block auth flow
    }
  }

  /// Sign up with email, password, name, role, and username handle
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String handle,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final normalizedHandle = handle.trim().toLowerCase();

    try {
      // Check username availability up-front so we can surface a clear
      // error before creating the auth user.
      final available =
          await SupabaseService.isHandleAvailable(normalizedHandle);
      if (!available) {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'This username is already taken.',
        );
        return;
      }

      final response = await SupabaseService.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create user profile in 'users' table
        await SupabaseService.createUserProfile(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
          role: role,
          handle: normalizedHandle,
        );

        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
      } else {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Sign up failed. Please try again.',
        );
      }
    } on supabase.AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      // Gracefully handle the DB unique-constraint violation on handle
      // (in case of a race between the availability check and insert).
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: ErrorUtils.sanitize(e),
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Sign out failed. Please try again.',
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Main auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

/// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<supabase.User?>((ref) {
  return ref.watch(authProvider).user;
});
