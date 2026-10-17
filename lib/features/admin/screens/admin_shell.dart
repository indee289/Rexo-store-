import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/is_admin_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import 'actions_screen.dart';
import 'admin_profile_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';

/// Riverpod provider that holds the current admin tab index.
/// DashboardScreen (and other children) can write to this to switch tabs.
final adminTabIndexProvider = StateProvider<int>((ref) => 0);

/// The single entry point for the Admin Center inside the user app.
///
/// It hosts the five admin sections (Dashboard, Users, Actions, Settings,
/// Profile) in an [IndexedStack] driven by a bottom navigation bar.
///
/// Tab indexes: 0=Dashboard, 1=Users, 2=Actions, 3=Settings, 4=Profile
///
/// ADMIN GUARD: this screen is only reachable from the gated "Admin Center"
/// entry in the Profile screen, but it also guards itself.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  static const _screens = <Widget>[
    DashboardScreen(),
    UsersScreen(),
    ActionsScreen(),
    SettingsScreen(),
    AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Admin access is determined purely from the database role via
    // isAdminProvider (no hardcoded emails). While the profile is loading,
    // show a spinner; once loaded, redirect non-admins to /home.
    final isAdmin = ref.watch(isAdminProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    if (profileAsync.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const Scaffold(
        body: Center(child: Text('Access denied')),
      );
    }

    // Watch the shared tab index provider
    final currentIndex = ref.watch(adminTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => ref.read(adminTabIndexProvider.notifier).state = i,
      ),
    );
  }
}
