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

  /// Get user profile from 'users' table.
  /// Live identity column is `uid` (text) — matches auth.uid()::text.
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await client
        .from('users')
        .select()
        .eq('uid', userId)
        .maybeSingle();
    return response;
  }

  /// Check whether a given username is already taken.
  ///
  /// Queries the live `users.username` column (UNIQUE constraint
  /// users_username_key confirmed on production DB).
  /// Returns true when the username is available, false when taken.
  /// Callers must pass an already-normalized (lowercased) value.
  static Future<bool> isHandleAvailable(String handle) async {
    final existing = await client
        .from('users')
        .select('id')
        .eq('username', handle)        // live column: username (not handle)
        .maybeSingle();
    return existing == null;
  }

  /// Create or complete the user profile row in 'users' after signup.
  ///
  /// ARCHITECTURE NOTE — dual-path reconciliation:
  /// When Flutter calls auth.signUp(), Supabase may fire the
  /// `handle_new_auth_user` DB trigger (defined in 04_AUTH_USER_SETUP.sql)
  /// which inserts: (id, uid, email, name, role). The trigger does NOT insert
  /// `username` because the auth metadata does not carry it.
  ///
  /// Flutter therefore also writes to public.users immediately after signUp.
  /// Uses upsert (INSERT … ON CONFLICT (id) DO UPDATE) so both paths work:
  ///   - Row already exists (trigger ran first): updates username/name/role.
  ///   - Row does not exist (confirmation-flow): inserts the full row.
  ///
  /// CONFIRMED LIVE SCHEMA columns written here:
  ///   id         uuid    ← primary key
  ///   uid        text    ← RLS identity column (NOT NULL)
  ///   email      text
  ///   name       text
  ///   username   text    ← user-chosen handle; UNIQUE constraint in live DB
  ///   role       text    ← DEFAULT 'CREATOR'
  ///   createdAt  timestamptz
  static Future<void> createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    required String role,
    required String handle,
  }) async {
    await client.from('users').upsert(
      {
        'id': userId,
        'uid': userId,              // NOT NULL identity column
        'email': email,
        'name': fullName,
        'username': handle,         // live column name; trigger never sets this
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
      },
      onConflict: 'id',             // if trigger already created the row, update it
    );
  }

  /// Update user profile.
  /// Live identity column is `uid` (text) — matches auth.uid()::text.
  static Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await client.from('users').update(data).eq('uid', userId);
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Listen to auth state changes
  static Stream<AuthState> get onAuthStateChange =>
      client.auth.onAuthStateChange;
}
