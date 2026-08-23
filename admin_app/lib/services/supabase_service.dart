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

  /// Listen to auth state changes
  static Stream<AuthState> get onAuthStateChange =>
      client.auth.onAuthStateChange;
}
