import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/r2_storage_service.dart';
import '../../../services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Profile state model
class ProfileState {
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? roleProfile;
  final Map<String, dynamic>? wallet;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profile,
    this.roleProfile,
    this.wallet,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    Map<String, dynamic>? profile,
    Map<String, dynamic>? roleProfile,
    Map<String, dynamic>? wallet,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      roleProfile: roleProfile ?? this.roleProfile,
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  String get role => (profile?['role'] ?? 'creator').toString().toLowerCase();
  bool get isCreator => role == 'creator';
  bool get isBrand => role == 'brand';
  bool get isAdmin => role == 'admin';
}

/// Provider for the full user profile with role-specific data.
/// All secondary queries (roleProfile, wallet, follows) are wrapped in
/// try/catch so a single missing table never crashes the whole profile.
///
/// Watches [authProvider] so Riverpod automatically re-executes this provider
/// when the user signs in/out — preventing stale profile data after switching
/// accounts.
final currentUserProfileProvider = FutureProvider<ProfileState>((ref) async {
  // ── Reactive dependency on auth state ──
  // When auth changes (logout → login as new user), this provider is
  // automatically re-evaluated with the new user's ID.
  final authState = ref.watch(authProvider);
  final user = authState.user;
  if (user == null || !authState.isAuthenticated) {
    return const ProfileState(error: 'Not authenticated');
  }

  // Fetch base user profile — the only required call
  Map<String, dynamic>? profile;
  try {
    profile = await SupabaseService.getUserProfile(user.id);
  } catch (e) {
    return const ProfileState(error: 'Could not load profile. Please try again.');
  }
  if (profile == null) {
    return const ProfileState(error: 'Profile not found');
  }

  // Role-specific profiles — creator_profiles / brand_profiles may not exist
  // in the live DB; gracefully skip without crashing.
  Map<String, dynamic>? roleProfile;
  try {
    final role = (profile['role'] ?? 'creator').toString().toLowerCase();
    if (role == 'creator') {
      roleProfile = await SupabaseService.client
          .from('creator_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
    } else if (role == 'brand') {
      roleProfile = await SupabaseService.client
          .from('brand_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
    }
  } catch (_) {
    roleProfile = null; // Table absent — silently skip
  }

  // Wallet — the wallets table may not exist; walletBalance is also on users
  Map<String, dynamic>? wallet;
  try {
    wallet = await SupabaseService.client
        .from('wallets')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
  } catch (_) {
    wallet = null; // Table absent — silently skip
  }

  return ProfileState(profile: profile, roleProfile: roleProfile, wallet: wallet);
});

/// Number of campaigns associated with the current user.
/// For brand/admin users: counts campaigns they CREATED (in `campaigns` table).
/// For creator users: counts campaigns they APPLIED TO (in `applications` table).
/// Watches [authProvider] to auto-refresh on login/logout.
final currentUserCampaignsCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  if (user == null || !authState.isAuthenticated) return 0;

  try {
    // First, determine the user's role from their profile
    final profile = await SupabaseService.getUserProfile(user.id);
    final role = (profile?['role'] ?? 'creator').toString().toLowerCase();

    if (role == 'brand' || role == 'admin') {
      // Brand/Admin: count campaigns they CREATED
      final response = await SupabaseService.client
          .from('campaigns')
          .select('id')
          .eq('brandId', user.id); // live: camelCase
      return (response as List).length;
    } else {
      // Creator: count campaigns they APPLIED TO
      final response = await SupabaseService.client
          .from('applications')
          .select('id')
          .eq('creatorId', user.id); // live: camelCase
      return (response as List).length;
    }
  } catch (_) {
    return 0;
  }
});

/// Followers count — reads from users.followersCount (live column).
/// The `follows` table does not exist in the live DB.
/// Watches [authProvider] to auto-refresh on login/logout.
final currentUserFollowersCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  if (user == null || !authState.isAuthenticated) return 0;
  try {
    final row = await SupabaseService.getUserProfile(user.id);
    return (row?['followersCount'] as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
});

/// Following count — reads from users.followingCount (live column).
/// Watches [authProvider] to auto-refresh on login/logout.
final currentUserFollowingCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  if (user == null || !authState.isAuthenticated) return 0;
  try {
    final row = await SupabaseService.getUserProfile(user.id);
    return (row?['followingCount'] as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
});

/// Profile notifier for updating profile data
class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileNotifier() : super(const AsyncValue.data(null));

  Object? _lastError;
  Object? get lastError => _lastError;

  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    state = const AsyncValue.loading();
    _lastError = null;

    try {
      // Confirmed live users columns — only send known columns.
      const validColumns = {
        'name', 'username', 'profileImage', 'bio', 'phone', 'mobile',
        'location', 'category', 'instagramLink',
      };

      final filteredFields = <String, dynamic>{};
      for (final entry in fields.entries) {
        if (validColumns.contains(entry.key)) {
          filteredFields[entry.key] = entry.value;
        }
      }

      await SupabaseService.updateUserProfile(
        userId: user.id,
        data: filteredFields,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _lastError = e;
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<String?> uploadAvatar(File file) async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;
    state = const AsyncValue.loading();
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';
      final filePath = 'avatars/${user.id}/$fileName';
      final fileBytes = await file.readAsBytes();
      final contentType = _getAvatarContentType(fileExt);
      final publicUrl = await R2StorageService.uploadFile(filePath, fileBytes, contentType);
      await SupabaseService.updateUserProfile(
        userId: user.id,
        data: {'profileImage': publicUrl},
      );
      state = const AsyncValue.data(null);
      return publicUrl;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  String _getAvatarContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      default: return 'application/octet-stream';
    }
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  return ProfileNotifier();
});
