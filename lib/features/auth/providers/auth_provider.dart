import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/utils/error_utils.dart';
import '../../../services/onesignal_service.dart';
import '../../../services/push_notification_service.dart';
import '../../../services/supabase_service.dart';
import '../../device_fingerprint/providers/device_fingerprint_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../home/providers/banners_provider.dart';

/// Auth state enum
///
/// [mfaRequired] means the password step succeeded but the session is still at
/// AAL1 while a verified second factor (TOTP) exists — the user must complete
/// an MFA challenge before they are considered [authenticated].
enum AuthStatus {
  initial,
  loading,
  authenticated,
  mfaRequired,
  unauthenticated,
  error,
}

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
      // Session restored on startup: register this device's FCM token so the
      // user_devices row exists even without a fresh sign-in this launch.
      _registerDeviceForPush();
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }

    // Listen to auth state changes
    _authSubscription = SupabaseService.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      switch (event) {
        case supabase.AuthChangeEvent.signedIn:
          // If the sign-in flow flagged that a second factor is still
          // required, don't override it here. The MFA challenge flow
          // (completeMfa) owns the transition to authenticated once the TOTP
          // code is verified — otherwise this event would clobber
          // mfaRequired and silently bypass 2FA.
          if (state.status == AuthStatus.mfaRequired) break;
          state = AuthState(
            status: AuthStatus.authenticated,
            user: session?.user,
          );
          // A session is now active (login, signup, or restore) — make sure
          // this device's FCM token is saved to user_devices.
          _registerDeviceForPush();
          break;
        case supabase.AuthChangeEvent.signedOut:
          state = const AuthState(status: AuthStatus.unauthenticated);
          break;
        case supabase.AuthChangeEvent.tokenRefreshed:
          // Preserve a pending MFA challenge across background token refreshes
          // (a refresh keeps the same assurance level, so it must not elevate
          // the user to authenticated before the factor is verified).
          if (state.status == AuthStatus.mfaRequired) break;
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
        // Password step succeeded (AAL1). Supabase does NOT block the login
        // when a verified TOTP factor exists — it just stays at AAL1. Detect
        // that here and require the second factor before treating the user as
        // fully authenticated.
        if (await _mfaChallengeRequired()) {
          state = AuthState(
            status: AuthStatus.mfaRequired,
            user: response.user,
          );
          return;
        }

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

  /// Whether the current session needs to step up to AAL2 (i.e. a verified
  /// TOTP factor exists but hasn't been satisfied this session).
  ///
  /// Fails OPEN: if the assurance-level lookup throws for any reason we return
  /// false so a transient error can never lock a legitimate user out.
  Future<bool> _mfaChallengeRequired() async {
    try {
      final aal = await SupabaseService.client.auth.mfa
          .getAuthenticatorAssuranceLevel();
      return aal.currentLevel == supabase.AuthenticatorAssuranceLevels.aal1 &&
          aal.nextLevel == supabase.AuthenticatorAssuranceLevels.aal2;
    } catch (_) {
      // Never lock the user out on an AAL lookup failure.
      return false;
    }
  }

  /// Called by the MFA challenge screen after a TOTP code has been verified
  /// (the session is now elevated to AAL2). Re-reads the current user and
  /// marks the account as fully authenticated.
  void completeMfa() {
    final user = SupabaseService.currentUser;
    if (user != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
      // Now that the login is fully complete, run the post-login side effects
      // that were deferred while the second factor was pending.
      _recordDeviceFingerprint();
      _registerDeviceForPush();
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
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

  /// Register this device's FCM token in `user_devices` for the now-active
  /// user. Fire-and-forget: push registration must never block or break auth.
  /// [PushNotificationService.onUserLogin] fetches the real FCM token and
  /// upserts it against the authenticated user id (RLS restricts to own rows).
  void _registerDeviceForPush() {
    try {
      PushNotificationService.onUserLogin();
    } catch (_) {
      // Non-critical - push notifications are optional.
    }

    // Associate this device's OneSignal subscription with the app user so
    // pushes can be targeted by external id. Fire-and-forget + guarded.
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId != null) {
        OneSignalService.onUserLogin(userId);
      }
    } catch (_) {
      // Non-critical - OneSignal targeting is optional.
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
      // Remove this device's FCM token BEFORE clearing the session — the
      // delete is RLS-guarded by auth.uid(), so it must run while still
      // authenticated. Best-effort; never blocks sign-out.
      await PushNotificationService.onUserLogout();

      // Disassociate the user from this device's OneSignal subscription so the
      // next user isn't targeted with the previous external id. Best-effort.
      await OneSignalService.onUserLogout();

      await SupabaseService.signOut();

      // ── Invalidate ALL cached user data so the next login starts fresh ──
      // Without this, Riverpod's FutureProvider cache survives across logins
      // and the new user sees the old user's stale profile/stats.
      _ref.invalidate(currentUserProfileProvider);
      _ref.invalidate(currentUserCampaignsCountProvider);
      _ref.invalidate(currentUserFollowersCountProvider);
      _ref.invalidate(currentUserFollowingCountProvider);
      _ref.invalidate(featuredCampaignsProvider);
      _ref.invalidate(bannersProvider);

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
