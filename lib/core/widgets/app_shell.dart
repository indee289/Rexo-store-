import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/subscriptions/providers/subscriptions_provider.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_bottom_nav.dart';

/// App shell with bottom nav + subscription paywall gate.
///
/// Before showing the main app, checks if the user has an approved
/// subscription payment. If not, redirects to the subscriptions screen.
/// Admin users bypass the paywall (they need full access for management).
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(hasApprovedSubscriptionProvider);

    return subscriptionAsync.when(
      // While checking subscription status, show loading
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      // If check fails, let user through (don't lock out on error)
      error: (_, __) => _buildMainApp(context),
      data: (hasSubscription) {
        if (!hasSubscription) {
          // No subscription — show paywall
          return _PaywallGate(
            onSubscribe: () => context.push(AppRoutes.subscriptions),
          );
        }
        return _buildMainApp(context);
      },
    );
  }

  Widget _buildMainApp(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

/// Paywall screen shown when user has no approved subscription.
class _PaywallGate extends StatelessWidget {
  final VoidCallback onSubscribe;

  const _PaywallGate({required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Subscription Required',
                style: AppTextStyles.title1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'To access the Rexo marketplace, you need an active subscription. Choose a plan to get started.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Plans',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
