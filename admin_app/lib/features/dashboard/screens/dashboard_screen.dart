import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/stat_chip.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(adminStatsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () => ref.invalidate(adminStatsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              PremiumCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.user,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            authState.userProfile?['name'] ?? 'Admin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats heading
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Stats grid — content-driven height via Wrap so larger font /
              // display scaling never clips a stat cell (fixed aspect grids do).
              stats.when(
                data: (data) {
                  final chips = <Widget>[
                    StatChip(
                      label: 'Total users',
                      value: '${data['total_users'] ?? 0}',
                      icon: Iconsax.people,
                      color: AppColors.primary,
                    ),
                    StatChip(
                      label: 'Active campaigns',
                      value: '${data['active_campaigns'] ?? 0}',
                      icon: Iconsax.briefcase,
                      color: AppColors.success,
                    ),
                    StatChip(
                      label: 'Pending deposits',
                      value: '${data['pending_deposits'] ?? 0}',
                      icon: Iconsax.money_recive,
                      color: AppColors.warning,
                    ),
                    StatChip(
                      label: 'Pending withdrawals',
                      value: '${data['pending_withdrawals'] ?? 0}',
                      icon: Iconsax.money_send,
                      color: Colors.purple,
                    ),
                    StatChip(
                      label: 'Pending KYC',
                      value: '${data['pending_kyc'] ?? 0}',
                      icon: Iconsax.document,
                      color: Colors.teal,
                    ),
                    StatChip(
                      label: 'Revenue',
                      value: '\u20B9${data['total_earnings'] ?? 0}',
                      icon: Iconsax.chart_square,
                      color: AppColors.secondary,
                    ),
                  ];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 12.0;
                      // Two columns on phones, three when there is room.
                      final columns = constraints.maxWidth >= 560 ? 3 : 2;
                      final itemWidth =
                          (constraints.maxWidth - spacing * (columns - 1)) /
                              columns;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final chip in chips)
                            SizedBox(width: itemWidth, child: chip),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
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
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(adminStatsProvider),
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
    );
  }
}
