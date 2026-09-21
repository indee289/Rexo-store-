import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkBackground : AppColors.background;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ────────────────────────────────────────────────────
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: pageBg,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Admin Centre',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.invalidate(adminStatsProvider),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: surfaceAlt,
                        borderRadius: AppRadius.allSm,
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(Iconsax.refresh,
                          size: 18, color: cs.onSurfaceVariant),
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
                            Text(
                              'Overview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Content-driven Wrap so large font/display scale
                            // never clips a stat cell (a fixed-aspect grid does).
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const spacing = 12.0;
                                final columns =
                                    constraints.maxWidth >= 560 ? 3 : 2;
                                final itemWidth = (constraints.maxWidth -
                                        spacing * (columns - 1)) /
                                    columns;
                                final cards = <Widget>[
                                  _StatCard(
                                    label: 'Total users',
                                    value: '${data['total_users'] ?? 0}',
                                    icon: Iconsax.people,
                                    color: AppColors.primary,
                                  ),
                                  _StatCard(
                                    label: 'Active campaigns',
                                    value:
                                        '${data['active_campaigns'] ?? 0}',
                                    icon: Iconsax.briefcase,
                                    color: AppColors.success,
                                  ),
                                  _StatCard(
                                    label: 'Pending deposits',
                                    value:
                                        '${data['pending_deposits'] ?? 0}',
                                    icon: Iconsax.money_recive,
                                    color: AppColors.warning,
                                  ),
                                  _StatCard(
                                    label: 'Pending withdrawals',
                                    value:
                                        '${data['pending_withdrawals'] ?? 0}',
                                    icon: Iconsax.money_send,
                                    color: AppColors.accentPurple,
                                  ),
                                  _StatCard(
                                    label: 'Pending KYC',
                                    value: '${data['pending_kyc'] ?? 0}',
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
                                ];
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    for (final card in cards)
                                      SizedBox(
                                          width: itemWidth, child: card),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            // Quick actions row
                            Text(
                              'Quick actions',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
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
                        error: (error, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.textPrimary, width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Iconsax.chart_2, size: 28, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Could not load stats',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Check your connection and try again.',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: () => ref.invalidate(adminStatsProvider),
                                child: const Text(
                                  'Try again',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: AppRadius.allLg,
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.14 : 0.08),
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
