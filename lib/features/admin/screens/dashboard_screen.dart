import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ────────────────────────────────────────────────────
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Admin Centre',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.invalidate(adminStatsProvider),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: AppRadius.allSm,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Iconsax.refresh,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async =>
                    ref.invalidate(adminStatsProvider),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats grid
                      stats.when(
                        data: (data) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.4,
                              children: [
                                _StatCard(
                                  label: 'Total Users',
                                  value:
                                      '${data['total_users'] ?? 0}',
                                  icon: Iconsax.people,
                                  color: AppColors.primary,
                                ),
                                _StatCard(
                                  label: 'Active Campaigns',
                                  value:
                                      '${data['active_campaigns'] ?? 0}',
                                  icon: Iconsax.briefcase,
                                  color: AppColors.success,
                                ),
                                _StatCard(
                                  label: 'Pending Deposits',
                                  value:
                                      '${data['pending_deposits'] ?? 0}',
                                  icon: Iconsax.money_recive,
                                  color: AppColors.warning,
                                ),
                                _StatCard(
                                  label: 'Pending Withdrawals',
                                  value:
                                      '${data['pending_withdrawals'] ?? 0}',
                                  icon: Iconsax.money_send,
                                  color: AppColors.accentPurple,
                                ),
                                _StatCard(
                                  label: 'Pending KYC',
                                  value:
                                      '${data['pending_kyc'] ?? 0}',
                                  icon: Iconsax.document,
                                  color: AppColors.accentTeal,
                                ),
                                _StatCard(
                                  label: 'Revenue',
                                  value:
                                      '₹${data['total_earnings'] ?? 0}',
                                  icon: Iconsax.chart_square,
                                  color: AppColors.accentAmber,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            // Quick actions row
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                _QuickAction(
                                  label: 'Users',
                                  icon: Iconsax.people,
                                  onTap: () =>
                                      context.push('/admin/users'),
                                ),
                                const SizedBox(width: 8),
                                _QuickAction(
                                  label: 'KYC',
                                  icon: Iconsax.verify,
                                  onTap: () =>
                                      context.push('/kyc'),
                                ),
                                const SizedBox(width: 8),
                                _QuickAction(
                                  label: 'Wallets',
                                  icon: Iconsax.wallet_1,
                                  onTap: () =>
                                      context.push('/wallet'),
                                ),
                                const SizedBox(width: 8),
                                _QuickAction(
                                  label: 'Campaigns',
                                  icon: Iconsax.briefcase,
                                  onTap: () =>
                                      context.push('/campaigns'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        loading: () =>
                            const ShimmerLoading(height: 320),
                        error: (error, _) => Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              const Icon(Iconsax.warning_2,
                                  size: 48, color: AppColors.error),
                              const SizedBox(height: 12),
                              const Text(
                                'Failed to load stats',
                                style: TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => ref.invalidate(
                                    adminStatsProvider),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
