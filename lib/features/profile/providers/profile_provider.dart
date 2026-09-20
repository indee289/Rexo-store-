import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/r2_storage_service.dart';
import '../../../services/supabase_service.dart';

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

  String get role => profile?['role'] ?? 'creator';
  bool get isCreator => role == 'creator';
  bool get isBrand => role == 'brand';
  bool get isAdmin => role == 'admin';
}

/// Provider for the full user profile with role-specific data
final currentUserProfileProvider = FutureProvider<ProfileState>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) {
    return const ProfileState(error: 'Not authenticated');
  }

  // Fetch base user profile
  Map<String, dynamic>? profile;
  try {
    profile = await SupabaseService.getUserProfile(user.id);
  } catch (e) {
    return ProfileState(error: 'Profile not found. Please try again.');
  }
  if (profile == null) {
    return const ProfileState(error: 'Profile not found');
  }

  final role = (profile['role'] ?? 'creator').toString().toLowerCase();

  // Fetch role-specific profile — gracefully skip if table missing or RLS blocks
  Map<String, dynamic>? roleProfile;
  try {
    if (role == 'creator') {
      final response = await SupabaseService.client
          .from('creator_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      roleProfile = response;
    } else if (role == 'brand') {
      final response = await SupabaseService.client
          .from('brand_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      roleProfile = response;
    }
  } catch (_) {
    // Role-specific profile is optional — don't fail the whole profile load
    roleProfile = null;
  }

  // Fetch wallet data — gracefully skip if table/RLS issue
  Map<String, dynamic>? wallet;
  try {
    wallet = await SupabaseService.client
        .from('wallets')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
  } catch (_) {
    wallet = null;
  }

  return ProfileState(
    profile: profile,
    roleProfile: roleProfile,
    wallet: wallet,
  );
});

/// Number of campaigns the current user has applied to (approved or otherwise).
final currentUserCampaignsCountProvider = FutureProvider<int>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return 0;
  final response = await SupabaseService.client
      .from('applications')
      .select('id')
      .eq('creatorId', user.id);    // live: camelCase
  return (response as List).length;
});

/// Number of users following the current user (their followers).
final currentUserFollowersCountProvider = FutureProvider<int>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return 0;
  final response = await SupabaseService.client
      .from('follows')
      .select('id')
      .eq('following_id', user.id);
  return (response as List).length;
});

/// Number of users the current user is following.
final currentUserFollowingCountProvider = FutureProvider<int>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return 0;
  final response = await SupabaseService.client
      .from('follows')
      .select('id')
      .eq('follower_id', user.id);
  return (response as List).length;
});

/// Profile notifier for updating profile data
class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileNotifier() : super(const AsyncValue.data(null));

  /// Stores the last error encountered during an update operation.
  /// The UI can read this to display a specific error message.
  Object? _lastError;
  Object? get lastError => _lastError;

  /// Update user profile fields.
  ///
  /// Only valid users table columns are sent to Supabase to prevent
  /// "column not found" errors.
  ///
  /// Returns true on success, false on failure. On failure, [lastError]
  /// contains the original error object for use with ErrorUtils.sanitize.
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    state = const AsyncValue.loading();
    _lastError = null;

    try {
      // CONFIRMED LIVE users columns (from Stage F3 verification):
      // id, uid, email, name, username, role, profileImage
      // bio, phone, isVerified, isBanned, createdAt — NOT confirmed in live DB.
      // Only send columns that definitely exist to prevent 400 errors.
      const validColumns = {
        'name',
        'username',     // live column (was handle)
        'profileImage', // live column (was avatar_url)
      };

      final filteredFields = <String, dynamic>{};
      for (final entry in fields.entries) {
        if (validColumns.contains(entry.key)) {
          filteredFields[entry.key] = entry.value;
        }
      }

      // updated_at does not exist in the live users schema — not added.

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

  /// Upload avatar to Cloudflare R2 and update profile
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

      final publicUrl = await R2StorageService.uploadFile(
        filePath,
        fileBytes,
        contentType,
      );

      // Update user profile with new avatar URL.
      // Live column is profileImage (not avatar_url).
      await SupabaseService.updateUserProfile(
        userId: user.id,
        data: {
          'profileImage': publicUrl,  // live column name
        },
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
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Provider for profile updates
final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  return ProfileNotifier();
});
