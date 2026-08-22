import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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

  /// Update user profile fields
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    state = const AsyncValue.loading();

    try {
      fields['updated_at'] = DateTime.now().toIso8601String();
      await SupabaseService.updateUserProfile(
        userId: user.id,
        data: fields,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Upload avatar to Supabase storage and update profile
  Future<String?> uploadAvatar(File file) async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    state = const AsyncValue.loading();

    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';
      final filePath = '${user.id}/$fileName';

      await SupabaseService.client.storage
          .from('avatars')
          .upload(filePath, file);

      final publicUrl = SupabaseService.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

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
}

/// Provider for profile updates
final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  return ProfileNotifier();
});
