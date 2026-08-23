import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/addresses/screens/add_address_screen.dart';
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
import '../../features/kyc/screens/kyc_upload_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/terms_of_service_screen.dart';
import '../../features/linked_accounts/screens/linked_accounts_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/moderation/screens/moderation_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/public_profile_screen.dart';
import '../../features/reviews/screens/reviews_screen.dart';
import '../../features/security/screens/security_logs_screen.dart';
import '../../features/sellers/screens/seller_profile_screen.dart';
import '../../features/services/screens/media_kit_screen.dart';
import '../../features/services/screens/rate_calculator_screen.dart';
import '../../features/services/screens/services_screen.dart';
import '../../features/sessions/screens/sessions_screen.dart';
import '../../features/settings/screens/help_support_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shop/screens/cart_screen.dart';
import '../../features/shop/screens/checkout_screen.dart';
import '../../features/shop/screens/product_detail_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../features/subscriptions/screens/subscriptions_screen.dart';
import '../../features/wallet/screens/deposit_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/wallet/screens/withdraw_screen.dart';
import '../../features/warnings/screens/warnings_screen.dart';
import '../../features/settings/screens/two_factor_auth_screen.dart';
import '../widgets/app_shell.dart';

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
  static const String shop = '/shop';
  static const String productDetail = '/shop/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
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
  static const String linkedAccounts = '/linked-accounts';
  static const String kyc = '/kyc';
  static const String addresses = '/addresses';
  static const String addAddress = '/add-address';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String helpSupport = '/help-support';

  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String disputes = '/disputes';
  static const String disputesRaise = '/disputes/raise';
  static const String reviews = '/reviews/:targetId';
  static const String coupons = '/coupons';
  static const String sellerProfile = '/seller/:id';
  static const String services = '/services';
  static const String servicesRateCalculator = '/services/rate-calculator';
  static const String servicesMediaKit = '/services/media-kit';
  static const String subscriptions = '/subscriptions';
  static const String sessions = '/sessions';
  static const String securityLogs = '/security-logs';
  static const String warnings = '/warnings';
  static const String moderation = '/moderation';
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
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final isAuthenticated = status == AuthStatus.authenticated;
      final isLoading = status == AuthStatus.loading || status == AuthStatus.initial;
      final isOnAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnMfaChallenge =
          state.matchedLocation == AppRoutes.mfaChallenge;

      // Allow splash screen to handle its own navigation
      if (isOnSplash) return null;

      // Don't redirect while loading/initializing
      if (isLoading) return null;

      // Password step done but a verified second factor is still pending:
      // force the MFA challenge and never let this user reach a protected
      // route (e.g. /home) until the factor is verified.
      if (status == AuthStatus.mfaRequired) {
        return isOnMfaChallenge ? null : AppRoutes.mfaChallenge;
      }

      // Once the challenge is satisfied (authenticated) send them home; if the
      // session was dropped (unauthenticated) send them back to login. Either
      // way, don't leave anyone stranded on the challenge screen.
      if (isOnMfaChallenge) {
        if (isAuthenticated) return AppRoutes.home;
        if (!isAuthenticated) return AppRoutes.login;
      }

      // If not authenticated and not on an auth route, redirect to login
      if (!isAuthenticated && !isOnAuthRoute) {
        return AppRoutes.login;
      }

      // If authenticated and on an auth route, redirect to home
      if (isAuthenticated && isOnAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
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

          /// Shop branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.shop,
                builder: (context, state) => const ShopScreen(),
              ),
            ],
          ),

          /// Messages / Inbox branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.messages,
                builder: (context, state) => const MessagesScreen(),
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

      /// Product detail screen (pushed on top of bottom nav)
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),

      /// Cart screen
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),

      /// Checkout screen
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
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

      /// Linked Accounts screen
      GoRoute(
        path: AppRoutes.linkedAccounts,
        builder: (context, state) => const LinkedAccountsScreen(),
      ),

      /// KYC Upload screen
      GoRoute(
        path: AppRoutes.kyc,
        builder: (context, state) => const KycUploadScreen(),
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

      /// Orders screen
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const OrdersScreen(),
      ),

      /// Order Detail screen
      GoRoute(
        path: AppRoutes.orderDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: id);
        },
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
