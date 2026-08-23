import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

/// The hardcoded platform admin email. A user signing in with this email is
/// always treated as an admin, in addition to anyone whose `users.role` is
/// `'admin'`. Kept in sync with [AppConstants.adminEmail].
const String kAdminEmail = 'rexoagency.in@gmail.com';

/// Single source of truth for "is the current user an admin?".
///
/// True when EITHER:
///   * the authenticated user's email matches [kAdminEmail], OR
///   * the loaded profile role is `'admin'` (ProfileState.isAdmin).
///
/// While the profile is still loading, this returns the email-based decision
/// only (so the hardcoded admin is recognised immediately, and everyone else
/// is treated as non-admin until their role resolves).
final isAdminProvider = Provider<bool>((ref) {
  final email = ref.watch(currentUserProvider)?.email?.toLowerCase().trim();
  if (email != null && email == kAdminEmail) {
    return true;
  }

  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.maybeWhen(
    data: (state) => state.isAdmin,
    orElse: () => false,
  );
});
