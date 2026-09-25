import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/providers/profile_provider.dart';

/// Single source of truth for "is the current user an admin?".
///
/// Determined **exclusively** from the database — checks `users.role == 'admin'`
/// via [ProfileState.isAdmin]. No hardcoded emails.
///
/// Returns `false` while the profile is still loading, so non-admin users are
/// never temporarily shown admin UI, and admin users gain access once their
/// profile resolves.
final isAdminProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.maybeWhen(
    data: (state) => state.isAdmin,
    orElse: () => false,
  );
});
