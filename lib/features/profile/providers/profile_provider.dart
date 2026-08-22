import 'dart:io';
import 'dart:typed_data';

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
  final profile = await SupabaseService.getUserProfile(user.id);
  if (profile == null) {
    return const ProfileState(error: 'Profile not found');
  }

  final role = profile['role'] ?? 'creator';

  // Fetch role-specific profile
  Map<String, dynamic>? roleProfile;
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

  // Fetch wallet data
  final wallet = await SupabaseService.client
      .from('wallets')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();

  return ProfileState(
    profile: profile,
    roleProfile: roleProfile,
    wallet: wallet,
  );
});

/// Profile notifier for updating profile data
class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileNotifier() : super(const AsyncValue.data(null));

  /// Update user profile fields.
  ///
  /// Only valid users table columns are sent to Supabase to prevent
  /// "column not found" errors.
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    state = const AsyncValue.loading();

    try {
      // Only allow valid users table columns to be sent
      const validColumns = {
        'name',
        'handle',
        'bio',
        'phone',
        'avatar_url',
        'updated_at',
      };

      final filteredFields = <String, dynamic>{};
      for (final entry in fields.entries) {
        if (validColumns.contains(entry.key)) {
          filteredFields[entry.key] = entry.value;
        }
      }

      filteredFields['updated_at'] = DateTime.now().toIso8601String();

      await SupabaseService.updateUserProfile(
        userId: user.id,
        data: filteredFields,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
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

      // Update user profile with new avatar URL
      await SupabaseService.updateUserProfile(
        userId: user.id,
        data: {
          'avatar_url': publicUrl,
          'updated_at': DateTime.now().toIso8601String(),
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
