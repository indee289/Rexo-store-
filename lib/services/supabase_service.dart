import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

class SupabaseService {
  SupabaseService._();

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get the currently authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Check if a user is currently authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Initialize Supabase with URL and anon key from dart-define
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Get user profile from 'users' table
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  /// Check whether a given [handle] (username) is already taken.
  ///
  /// Returns true if the handle is available (no existing row), false if a
  /// user already owns it. The comparison uses the exact stored value, so
  /// callers should pass an already-normalized (lowercased) handle.
  static Future<bool> isHandleAvailable(String handle) async {
    final existing = await client
        .from('users')
        .select('id')
        .eq('handle', handle)
        .maybeSingle();
    return existing == null;
  }

  /// Create user profile in 'users' table after signup
  static Future<void> createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    required String role,
    required String handle,
  }) async {
    await client.from('users').insert({
      'id': userId,
      'email': email,
      'name': fullName,
      'handle': handle,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await client.from('users').update(data).eq('id', userId);
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Listen to auth state changes
  static Stream<AuthState> get onAuthStateChange =>
      client.auth.onAuthStateChange;
}
