import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/is_admin_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import 'actions_screen.dart';
import 'admin_profile_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';

/// The single entry point for the Admin Center inside the user app.
///
/// It hosts the five admin sections (Dashboard, Users, Actions, Settings,
/// Profile) in an [IndexedStack] driven by a bottom navigation bar — replacing
/// the standalone admin app's go_router `StatefulShellRoute`. All deeper admin
/// screens are reached from these sections via `Navigator.push`.
///
/// ADMIN GUARD: this screen is only reachable from the gated "Admin Center"
/// entry in the Profile screen, but it also guards itself. If the resolved
/// user is NOT an admin, it redirects to `/home`. A user whose email matches
/// [kAdminEmail] is allowed immediately; everyone else must have `role == 'admin'`.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  static const _screens = <Widget>[
    DashboardScreen(),
    UsersScreen(),
    ActionsScreen(),
    SettingsScreen(),
    AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserProvider)?.email?.toLowerCase().trim();
    final emailIsAdmin = email == kAdminEmail;

    // If not the hardcoded admin email, decide based on the profile role.
    if (!emailIsAdmin) {
      final profileAsync = ref.watch(currentUserProfileProvider);

      // Wait for the profile before making a decision so a real admin is not
      // bounced out while their role is still loading.
      if (profileAsync.isLoading) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final isAdmin = profileAsync.valueOrNull?.isAdmin ?? false;
      if (!isAdmin) {
        // Not an admin — bounce to home after this frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/home');
        });
        return const Scaffold(
          body: Center(child: Text('Access denied')),
        );
      }
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
