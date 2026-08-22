import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/addresses/screens/add_address_screen.dart';
import '../../features/addresses/screens/addresses_screen.dart';
import '../../features/admin/screens/admin_audit_logs_screen.dart';
import '../../features/admin/screens/admin_broadcast_screen.dart';
import '../../features/admin/screens/admin_campaigns_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_deposits_screen.dart';
import '../../features/admin/screens/admin_disputes_screen.dart';
import '../../features/admin/screens/admin_kyc_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/admin/screens/admin_shop_screen.dart';
import '../../features/admin/screens/admin_submissions_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_wallets_screen.dart';
import '../../features/admin/screens/admin_withdrawals_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/campaigns/screens/apply_screen.dart';
import '../../features/campaigns/screens/campaign_detail_screen.dart';
import '../../features/campaigns/screens/campaigns_screen.dart';
import '../../features/campaigns/screens/my_campaigns_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/kyc/screens/kyc_upload_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/terms_of_service_screen.dart';
import '../../features/linked_accounts/screens/linked_accounts_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shop/screens/cart_screen.dart';
import '../../features/shop/screens/checkout_screen.dart';
import '../../features/shop/screens/product_detail_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../features/wallet/screens/deposit_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/wallet/screens/withdraw_screen.dart';
import '../widgets/app_shell.dart';

/// Route paths
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
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
  static const String settings = '/settings';
  static const String linkedAccounts = '/linked-accounts';
  static const String kyc = '/kyc';
  static const String addresses = '/addresses';
  static const String addAddress = '/add-address';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminCampaigns = '/admin/campaigns';
  static const String adminSubmissions = '/admin/submissions';
  static const String adminDeposits = '/admin/deposits';
  static const String adminWithdrawals = '/admin/withdrawals';
  static const String adminShop = '/admin/shop';
  static const String adminDisputes = '/admin/disputes';
  static const String adminKyc = '/admin/kyc';
  static const String adminWallets = '/admin/wallets';
  static const String adminSettings = '/admin/settings';
  static const String adminAuditLogs = '/admin/audit-logs';
  static const String adminBroadcast = '/admin/broadcast';
}

/// GoRouter provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isOnAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      // Allow splash screen to handle its own navigation
      if (isOnSplash) return null;

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

      /// Messages screen
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

      /// Admin Dashboard screen
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      /// Admin Users screen
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
      ),

      /// Admin Campaigns screen
      GoRoute(
        path: AppRoutes.adminCampaigns,
        builder: (context, state) => const AdminCampaignsScreen(),
      ),

      /// Admin Submissions screen
      GoRoute(
        path: AppRoutes.adminSubmissions,
        builder: (context, state) => const AdminSubmissionsScreen(),
      ),

      /// Admin Deposits screen
      GoRoute(
        path: AppRoutes.adminDeposits,
        builder: (context, state) => const AdminDepositsScreen(),
      ),

      /// Admin Withdrawals screen
      GoRoute(
        path: AppRoutes.adminWithdrawals,
        builder: (context, state) => const AdminWithdrawalsScreen(),
      ),

      /// Admin Shop screen
      GoRoute(
        path: AppRoutes.adminShop,
        builder: (context, state) => const AdminShopScreen(),
      ),

      /// Admin Disputes screen
      GoRoute(
        path: AppRoutes.adminDisputes,
        builder: (context, state) => const AdminDisputesScreen(),
      ),

      /// Admin KYC screen
      GoRoute(
        path: AppRoutes.adminKyc,
        builder: (context, state) => const AdminKycScreen(),
      ),

      /// Admin Wallets screen
      GoRoute(
        path: AppRoutes.adminWallets,
        builder: (context, state) => const AdminWalletsScreen(),
      ),

      /// Admin Settings screen
      GoRoute(
        path: AppRoutes.adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),

      /// Admin Audit Logs screen
      GoRoute(
        path: AppRoutes.adminAuditLogs,
        builder: (context, state) => const AdminAuditLogsScreen(),
      ),

      /// Admin Broadcast screen
      GoRoute(
        path: AppRoutes.adminBroadcast,
        builder: (context, state) => const AdminBroadcastScreen(),
      ),
    ],
  );
});
