import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom dark header ──────────────────────────────────────────
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(
                  bottom: BorderSide(color: AppColors.darkBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Admin Centre',
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.darkTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ref.invalidate(adminStatsProvider),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: AppRadius.allSm,
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(Iconsax.refresh,
                          size: 18, color: AppColors.darkTextSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(adminStatsProvider),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview heading
                      Text(
                        'Overview',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.darkTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats grid
                      stats.when(
                        data: (data) => GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            _DarkStatCard(
                              label: 'Total Users',
                              value: '${data['total_users'] ?? 0}',
                              icon: Iconsax.people,
                              color: AppColors.primary,
                            ),
                            _DarkStatCard(
                              label: 'Active Campaigns',
                              value: '${data['active_campaigns'] ?? 0}',
                              icon: Iconsax.briefcase,
                              color: AppColors.success,
                            ),
                            _DarkStatCard(
                              label: 'Pending Deposits',
                              value: '${data['pending_deposits'] ?? 0}',
                              icon: Iconsax.money_recive,
                              color: AppColors.warning,
                            ),
                            _DarkStatCard(
                              label: 'Pending Withdrawals',
                              value: '${data['pending_withdrawals'] ?? 0}',
                              icon: Iconsax.money_send,
                              color: AppColors.accentPurple,
                            ),
                            _DarkStatCard(
                              label: 'Pending KYC',
                              value: '${data['pending_kyc'] ?? 0}',
                              icon: Iconsax.document,
                              color: AppColors.accentTeal,
                            ),
                            _DarkStatCard(
                              label: 'Revenue',
                              value:
                                  '\u20B9${data['total_earnings'] ?? 0}',
                              icon: Iconsax.chart_square,
                              color: AppColors.accentAmber,
                            ),
                          ],
                        ),
                        loading: () => const ShimmerLoading(height: 320),
                        error: (error, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(Iconsax.warning_2,
                                    size: 48, color: AppColors.error),
                                const SizedBox(height: 12),
                                Text(
                                  'Failed to load stats',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.darkTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () =>
                                      ref.invalidate(adminStatsProvider),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

class _DarkStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DarkStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
