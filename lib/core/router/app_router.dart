import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/screens/delete_account_screen.dart';
import '../../features/addresses/screens/add_address_screen.dart';
import '../../features/blocks/screens/blocked_accounts_screen.dart';
import '../../features/addresses/screens/addresses_screen.dart';
import '../../features/admin/screens/admin_shell.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/mfa_challenge_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/campaigns/screens/apply_screen.dart';
import '../../features/campaigns/screens/campaign_detail_screen.dart';
import '../../features/campaigns/screens/campaigns_screen.dart';
import '../../features/campaigns/screens/create_campaign_screen.dart';
import '../../features/campaigns/screens/my_campaigns_screen.dart';
import '../../features/coupons/screens/coupons_screen.dart';
import '../../features/disputes/screens/disputes_screen.dart';
import '../../features/disputes/screens/raise_dispute_screen.dart';
import '../../features/home/screens/creator_profile_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/terms_of_service_screen.dart';
import '../../features/linked_accounts/screens/linked_accounts_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/moderation/screens/moderation_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/public_profile_screen.dart';
import '../../features/reports/providers/report_provider.dart';
import '../../features/reports/screens/report_screen.dart';
import '../../features/referrals/screens/referrals_screen.dart';
import '../../features/reviews/screens/reviews_screen.dart';
import '../../features/security/screens/security_logs_screen.dart';
import '../../features/sellers/screens/seller_profile_screen.dart';
import '../../features/services/screens/media_kit_screen.dart';
import '../../features/services/screens/rate_calculator_screen.dart';
import '../../features/services/screens/services_screen.dart';
import '../../features/sessions/screens/sessions_screen.dart';
import '../../features/settings/screens/help_support_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/jobs/screens/job_detail_screen.dart';
import '../../features/jobs/screens/jobs_screen.dart';
import '../../features/subscriptions/screens/subscriptions_screen.dart';
import '../../features/subscriptions/screens/subscription_payment_screen.dart';
import '../../features/wallet/screens/deposit_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/wallet/screens/withdraw_screen.dart';
import '../../features/warnings/screens/warnings_screen.dart';
import '../../features/settings/screens/two_factor_auth_screen.dart';
import '../widgets/app_shell.dart';

/// Global navigator key for the root [GoRouter]. Lets non-widget code (e.g. the
/// OneSignal push-subscription observer) present dialogs over the current route.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

/// Route paths
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String mfaChallenge = '/mfa-challenge';
  static const String register = '/register';
  static const String home = '/home';
  static const String campaigns = '/campaigns';
  static const String campaignDetail = '/campaigns/:id';
  static const String campaignApply = '/campaigns/:id/apply';
  static const String jobs = '/jobs';
  static const String jobDetail = '/jobs/:id';
  static const String profile = '/profile';
  static const String wallet = '/wallet';
  static const String walletDeposit = '/wallet/deposit';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String notifications = '/notifications';
  static const String messages = '/messages';
  static const String chat = '/messages/:userId';
  static const String myCampaigns = '/my-campaigns';
  static const String createCampaign = '/create-campaign';
  static const String settings = '/settings';
  static const String deleteAccount = '/settings/delete-account';
  static const String blockedAccounts = '/settings/blocked-accounts';
  static const String linkedAccounts = '/linked-accounts';
  static const String addresses = '/addresses';
  static const String addAddress = '/add-address';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String helpSupport = '/help-support';

  static const String disputes = '/disputes';
  static const String disputesRaise = '/disputes/raise';
  static const String reviews = '/reviews/:targetId';
  static const String coupons = '/coupons';
  static const String referrals = '/referrals';
  static const String sellerProfile = '/seller/:id';
  static const String services = '/services';
  static const String servicesRateCalculator = '/services/rate-calculator';
  static const String servicesMediaKit = '/services/media-kit';
  static const String subscriptions = '/subscriptions';
  static const String subscriptionPayment = '/subscriptions/payment';
  static const String sessions = '/sessions';
  static const String securityLogs = '/security-logs';
  static const String warnings = '/warnings';
  static const String moderation = '/moderation';
  static const String report = '/report';
  static const String publicProfile = '/profile/:handle';

  static const String creatorProfile = '/creators/:id';

  static const String twoFactorAuth = '/two-factor-auth';

  /// Admin Center (merged admin app). Only reachable by admins — gated at the
  /// entry point (Profile menu) and guarded again inside [AdminShell].
  static const String adminDashboard = '/admin';
}

/// Lightweight [Listenable] used as GoRouter's `refreshListenable`. It is
/// bumped whenever the auth state changes so the router re-runs `redirect`
/// WITHOUT being recreated (which would reset navigation to /splash).
class _AuthRefreshNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// Deep-link destination that a logged-out user tried to reach. It is captured
/// by [redirect] when an unauthenticated user hits a protected route (e.g. a
/// campaign/chat deep link), preserved across the login/MFA screens, and
/// consumed the moment the user becomes authenticated so they land on the
/// intended page instead of being dumped on Home.
String? _pendingDeepLink;

/// Locations that must never be treated as a "return" destination (auth
/// scaffolding and the app root/home). Prevents redirect loops and stops us
/// from "returning" a user to the login/splash screens.
bool _isTrivialLocation(String location) {
  final path = Uri.parse(location).path;
  return path.isEmpty ||
      path == '/' ||
      path == AppRoutes.splash ||
      path == AppRoutes.login ||
      path == AppRoutes.register ||
      path == AppRoutes.mfaChallenge ||
      path == AppRoutes.home;
}

/// GoRouter provider
///
/// IMPORTANT: the GoRouter instance is created ONCE. We must NOT `ref.watch`
/// authProvider here — doing so rebuilt the whole router on every auth change,
/// which reset navigation back to `initialLocation` (/splash), causing the
/// splash screen to flash and the page to "reload" on login. Instead we drive
/// redirect re-evaluation through a `refreshListenable` bumped on auth changes,
/// and read the current auth state inside `redirect` via `ref.read`.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier();
  final sub = ref.listen<AuthState>(
    authProvider,
    (_, __) => refresh.bump(),
    fireImmediately: false,
  );
  ref.onDispose(() {
    sub.close();
    refresh.dispose();
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final isAuthenticated = status == AuthStatus.authenticated;
      final isLoading = status == AuthStatus.loading || status == AuthStatus.initial;
      final matched = state.matchedLocation;
      // Full location (path + query) — this is what we preserve for deep links.
      final location = state.uri.toString();
      final isOnAuthRoute =
          matched == AppRoutes.login || matched == AppRoutes.register;
      final isOnSplash = matched == AppRoutes.splash;
      final isOnMfaChallenge = matched == AppRoutes.mfaChallenge;

      // Allow splash screen to handle its own navigation
      if (isOnSplash) return null;

      // Don't redirect while loading/initializing
      if (isLoading) return null;

      // Password step done but a verified second factor is still pending:
      // force the MFA challenge and never let this user reach a protected
      // route (e.g. /home) until the factor is verified. Any captured deep
      // link is preserved in [_pendingDeepLink] across this step.
      if (status == AuthStatus.mfaRequired) {
        return isOnMfaChallenge ? null : AppRoutes.mfaChallenge;
      }

      if (!isAuthenticated) {
        // A deep link (or any protected route) reached while logged out:
        // remember exactly where the user wanted to go so we can return them
        // there after authentication — NOT just to Home.
        if (!isOnAuthRoute && !_isTrivialLocation(location)) {
          _pendingDeepLink = location;
        }
        // Dropped session while on the MFA screen → back to login.
        if (isOnMfaChallenge) return AppRoutes.login;
        return isOnAuthRoute ? null : AppRoutes.login;
      }

      // ── Authenticated ──
      // Just landed post-auth (on login/register/MFA, or bounced to Home):
      // consume the preserved deep link and send them to their real target.
      if (_pendingDeepLink != null &&
          (isOnAuthRoute || isOnMfaChallenge || matched == AppRoutes.home)) {
        final target = _pendingDeepLink!;
        _pendingDeepLink = null;
        if (target != location && !_isTrivialLocation(target)) {
          return target;
        }
      }

      // No pending destination — keep authenticated users off the auth screens.
      if (isOnAuthRoute || isOnMfaChallenge) {
        return AppRoutes.home;
      }

      return null;
    },
    // Invalid / nonexistent ROUTES (a valid route with a bad resource id is
    // handled by the destination screen's own not-found state, which relies on
    // Supabase RLS — never on the link's parameters). This only catches URIs
    // that match no route at all, so a malformed deep link can't crash the app.
    errorBuilder: (context, state) => _DeepLinkErrorScreen(uri: state.uri),
    routes: [
      /// Splash screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      /// Login screen
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      /// MFA challenge screen (login-time TOTP second factor)
      GoRoute(
        path: AppRoutes.mfaChallenge,
        builder: (context, state) => const MfaChallengeScreen(),
      ),

      /// Register screen
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      /// Shell route for authenticated screens with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          /// Home branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          /// Campaigns branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.campaigns,
                builder: (context, state) => const CampaignsScreen(),
              ),
            ],
          ),

          /// Jobs branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.jobs,
                builder: (context, state) => const JobsScreen(),
              ),
            ],
          ),

          /// Profile branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      /// Campaign detail screen (pushed on top of bottom nav)
      GoRoute(
        path: AppRoutes.campaignDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CampaignDetailScreen(campaignId: id);
        },
      ),

      /// Campaign apply screen
      GoRoute(
        path: AppRoutes.campaignApply,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ApplyScreen(campaignId: id);
        },
      ),

      /// Job detail screen (pushed on top of bottom nav)
      GoRoute(
        path: AppRoutes.jobDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return JobDetailScreen(jobId: id);
        },
      ),

      /// Wallet screen
      GoRoute(
        path: AppRoutes.wallet,
        builder: (context, state) => const WalletScreen(),
      ),

      /// Wallet deposit screen
      GoRoute(
        path: AppRoutes.walletDeposit,
        builder: (context, state) => const DepositScreen(),
      ),

      /// Wallet withdraw screen
      GoRoute(
        path: AppRoutes.walletWithdraw,
        builder: (context, state) => const WithdrawScreen(),
      ),

      /// Notifications screen
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      /// Messages / Inbox screen (opened from the Home header inbox icon;
      /// no longer a bottom-nav tab per the Home reference).
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => const MessagesScreen(),
      ),

      /// Chat screen
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ChatScreen(otherUserId: userId);
        },
      ),

      /// My Campaigns screen
      GoRoute(
        path: AppRoutes.myCampaigns,
        builder: (context, state) => const MyCampaignsScreen(),
      ),

      /// Create Campaign screen
      GoRoute(
        path: AppRoutes.createCampaign,
        builder: (context, state) => const CreateCampaignScreen(),
      ),

      /// Settings screen
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      /// Delete Account screen (full-screen, routed — not a dialog)
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (context, state) => const DeleteAccountScreen(),
      ),

      /// Blocked Accounts management screen
      GoRoute(
        path: AppRoutes.blockedAccounts,
        builder: (context, state) => const BlockedAccountsScreen(),
      ),

      /// Linked Accounts screen
      GoRoute(
        path: AppRoutes.linkedAccounts,
        builder: (context, state) => const LinkedAccountsScreen(),
      ),

      /// Addresses screen
      GoRoute(
        path: AppRoutes.addresses,
        builder: (context, state) => const AddressesScreen(),
      ),

      /// Add Address screen
      GoRoute(
        path: AppRoutes.addAddress,
        builder: (context, state) {
          final existingAddress = state.extra as Map<String, dynamic>?;
          return AddAddressScreen(existingAddress: existingAddress);
        },
      ),

      /// Privacy Policy screen
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      /// Terms of Service screen
      GoRoute(
        path: AppRoutes.termsOfService,
        builder: (context, state) => const TermsOfServiceScreen(),
      ),

      /// Help & Support screen
      GoRoute(
        path: AppRoutes.helpSupport,
        builder: (context, state) => const HelpSupportScreen(),
      ),



      /// Two-Factor Authentication screen
      GoRoute(
        path: AppRoutes.twoFactorAuth,
        builder: (context, state) => const TwoFactorAuthScreen(),
      ),

      /// Disputes screen
      GoRoute(
        path: AppRoutes.disputes,
        builder: (context, state) => const DisputesScreen(),
      ),

      /// Raise Dispute screen
      GoRoute(
        path: AppRoutes.disputesRaise,
        builder: (context, state) => const RaiseDisputeScreen(),
      ),

      /// Reviews screen
      GoRoute(
        path: AppRoutes.reviews,
        builder: (context, state) {
          final targetId = state.pathParameters['targetId']!;
          final targetType =
              state.uri.queryParameters['targetType'] ?? 'product';
          return ReviewsScreen(
            targetId: targetId,
            targetType: targetType,
          );
        },
      ),

      /// Coupons screen
      GoRoute(
        path: AppRoutes.coupons,
        builder: (context, state) => const CouponsScreen(),
      ),

      /// Refer & Earn screen
      GoRoute(
        path: AppRoutes.referrals,
        builder: (context, state) => const ReferralsScreen(),
      ),

      /// Seller Profile screen
      GoRoute(
        path: AppRoutes.sellerProfile,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SellerProfileScreen(sellerId: id);
        },
      ),

      /// Services screen
      GoRoute(
        path: AppRoutes.services,
        builder: (context, state) => const ServicesScreen(),
      ),

      /// Rate Calculator screen
      GoRoute(
        path: AppRoutes.servicesRateCalculator,
        builder: (context, state) => const RateCalculatorScreen(),
      ),

      /// Media Kit screen
      GoRoute(
        path: AppRoutes.servicesMediaKit,
        builder: (context, state) => const MediaKitScreen(),
      ),

      /// Subscriptions screen
      GoRoute(
        path: AppRoutes.subscriptions,
        builder: (context, state) => const SubscriptionsScreen(),
      ),

      /// Subscription payment screen.
      /// Extra must be a Map<String, dynamic> with keys:
      ///   planId (String), planName (String), amount (double), durationDays (int)
      GoRoute(
        path: AppRoutes.subscriptionPayment,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return SubscriptionPaymentScreen(
            planId: extra['planId'] as String,
            planName: extra['planName'] as String,
            amount: (extra['amount'] as num).toDouble(),
            durationDays: (extra['durationDays'] as num).toInt(),
          );
        },
      ),

      /// Sessions & Devices screen
      GoRoute(
        path: AppRoutes.sessions,
        builder: (context, state) => const SessionsScreen(),
      ),

      /// Security Logs screen
      GoRoute(
        path: AppRoutes.securityLogs,
        builder: (context, state) => const SecurityLogsScreen(),
      ),

      /// Warnings & Suspensions screen
      GoRoute(
        path: AppRoutes.warnings,
        builder: (context, state) => const WarningsScreen(),
      ),

      /// Moderation screen (admin only)
      GoRoute(
        path: AppRoutes.moderation,
        builder: (context, state) => const ModerationScreen(),
      ),

      /// Report screen (full-screen, routed — not a dialog).
      /// Expects a Map extra: { 'targetType': ReportTargetType,
      /// 'targetId': String, 'targetLabel': String }.
      GoRoute(
        path: AppRoutes.report,
        builder: (context, state) {
          final extra = (state.extra as Map<String, dynamic>?) ?? const {};
          return ReportScreen(
            targetType:
                extra['targetType'] as ReportTargetType? ?? ReportTargetType.user,
            targetId: (extra['targetId'] ?? '').toString(),
            targetLabel: (extra['targetLabel'] ?? '').toString(),
          );
        },
      ),

      /// Admin Center (merged admin app) — full-screen, outside the storefront
      /// bottom-nav shell. [AdminShell] hosts Dashboard/Users/Actions/Settings/
      /// Profile and guards against non-admins (redirects to /home). The entry
      /// point in the Profile menu is only shown when isAdminProvider is true.
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminShell(),
      ),

      /// Public Profile screen (deep link)
      GoRoute(
        path: AppRoutes.publicProfile,
        builder: (context, state) {
          final handle = state.pathParameters['handle']!;
          return PublicProfileScreen(handle: handle);
        },
      ),

      /// Creator Profile screen
      GoRoute(
        path: AppRoutes.creatorProfile,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CreatorProfileScreen(creatorUserId: id);
        },
      ),
    ],
  );
});

/// Shown when an incoming deep link matches no known route (a malformed or
/// stale link). It never leaks link parameters into any privileged action and
/// simply offers a way back into the app.
class _DeepLinkErrorScreen extends StatelessWidget {
  final Uri uri;
  const _DeepLinkErrorScreen({required this.uri});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off, size: 48),
              const SizedBox(height: 12),
              const Text(
                "This link couldn't be opened.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                uri.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
