import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/actions/screens/actions_screen.dart';
import '../../features/actions/screens/campaign_control_screen.dart';
import '../../features/actions/screens/submission_review_screen.dart';
import '../../features/actions/screens/deposit_queue_screen.dart';
import '../../features/actions/screens/withdrawal_queue_screen.dart';
import '../../features/actions/screens/shop_admin_screen.dart';
import '../../features/actions/screens/disputes_screen.dart';
import '../../features/actions/screens/kyc_verification_screen.dart';
import '../../features/actions/screens/wallets_escrow_screen.dart';
import '../../features/actions/screens/push_broadcast_screen.dart';
import '../../features/actions/screens/rexo_program_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/audit_logs_screen.dart';
import '../../features/settings/screens/admin_profile_screen.dart';
import '../widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/';

      if (isSplash) return null;

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      if (isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/users',
                builder: (context, state) => const UsersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/actions',
                builder: (context, state) => const ActionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const AdminProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Pushed screens from Actions hub
      GoRoute(
        path: '/actions/campaigns',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CampaignControlScreen(),
      ),
      GoRoute(
        path: '/actions/submissions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubmissionReviewScreen(),
      ),
      GoRoute(
        path: '/actions/deposits',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DepositQueueScreen(),
      ),
      GoRoute(
        path: '/actions/withdrawals',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WithdrawalQueueScreen(),
      ),
      GoRoute(
        path: '/actions/shop',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShopAdminScreen(),
      ),
      GoRoute(
        path: '/actions/disputes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DisputesScreen(),
      ),
      GoRoute(
        path: '/actions/kyc',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const KycVerificationScreen(),
      ),
      GoRoute(
        path: '/actions/wallets',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WalletsEscrowScreen(),
      ),
      GoRoute(
        path: '/actions/broadcast',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PushBroadcastScreen(),
      ),
      GoRoute(
        path: '/actions/rexo-program',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RexoProgramScreen(),
      ),
      GoRoute(
        path: '/settings/audit-logs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AuditLogsScreen(),
      ),
    ],
  );
});
