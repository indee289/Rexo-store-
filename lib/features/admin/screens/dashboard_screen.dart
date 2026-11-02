import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/admin_provider.dart';
import 'admin_shell.dart';

/// Admin dashboard — rebuilt layout.
///
/// Old layout: a hand-assembled fake app bar (a `Container` holding a centred
/// `Text` and a `GestureDetector` refresh square), stat cells built as bespoke
/// `Container`s, a row of three hand-drawn `_QuickAction` tiles, and an error
/// state assembled from a circle-bordered icon plus a tappable `Text` acting
/// as a button.
///
/// New layout: the standard collapsing large title with refresh as a proper
/// icon button; the stats as cards on the shared surface; the quick actions as
/// a [GlassTileGrid], which gives real tap targets and readable labels; and
/// the error state from the shared set. The content-driven `Wrap` is kept
/// deliberately — a fixed-aspect grid clips the stat cells at large display
/// scales.
///
/// `adminStatsProvider`, `adminTabIndexProvider` and the three stat keys are
/// unchanged.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            GlassLargeTitleHeader(
              title: 'Admin centre',
              subtitle: 'Platform overview',
              actions: [
                GlassIconButton(
                  icon: AppIcons.refresh,
                  tooltip: 'Refresh',
                  size: 36,
                  iconSize: 19,
                  onTap: () => ref.invalidate(adminStatsProvider),
                ),
              ],
            ),

            stats.when(
              data: (data) => SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionLabel('Overview'),
                          // Content-driven Wrap so large font/display scale
                          // never clips a stat cell (a fixed-aspect grid does).
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = AppSpacing.md;
                              final columns =
                                  constraints.maxWidth >= 560 ? 3 : 2;
                              final itemWidth = (constraints.maxWidth -
                                      spacing * (columns - 1)) /
                                  columns;
                              final cards = <Widget>[
                                _StatCard(
                                  label: 'Total users',
                                  value: '${data['total_users'] ?? 0}',
                                  icon: AppIcons.people,
                                  color: AppColors.primary,
                                ),
                                _StatCard(
                                  label: 'Active campaigns',
                                  value: '${data['active_campaigns'] ?? 0}',
                                  icon: AppIcons.briefcase,
                                  color: AppColors.success,
                                ),
                                _StatCard(
                                  label: 'Pending withdrawals',
                                  value:
                                      '${data['pending_withdrawals'] ?? 0}',
                                  icon: AppIcons.money_send,
                                  color: AppColors.accentPurple,
                                ),
                              ];
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  for (final card in cards)
                                    SizedBox(width: itemWidth, child: card),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionLabel('Quick actions'),
                          GlassTileGrid(
                            columns: 3,
                            tiles: [
                              GlassTile(
                                icon: AppIcons.people,
                                label: 'Users',
                                onTap: () => ref
                                    .read(adminTabIndexProvider.notifier)
                                    .state = 1,
                              ),
                              GlassTile(
                                icon: AppIcons.task_square,
                                label: 'Actions',
                                onTap: () => ref
                                    .read(adminTabIndexProvider.notifier)
                                    .state = 2,
                              ),
                              GlassTile(
                                icon: AppIcons.setting_2,
                                label: 'Settings',
                                onTap: () => ref
                                    .read(adminTabIndexProvider.notifier)
                                    .state = 3,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SliverToBoxAdapter(child: _StatsSkeleton()),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: GlassErrorState(
                  title: 'Could not load stats',
                  message: 'Check your connection and try again.',
                  onRetry: () => ref.invalidate(adminStatsProvider),
                ),
              ),
            ),

            // Clearance for the floating admin dock.
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

/// Group heading matching the tracked-caps header used by `GlassSection`.
Widget _sectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.xs,
      AppSpacing.md,
    ),
    child: Text(
      text.toUpperCase(),
      style: AppTextStyles.caption1.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
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
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassIconBubble(icon: icon, color: color, size: 40, iconSize: 20),
          AppSpacing.gapSm,
          Text(
            value,
            style: AppTextStyles.title2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption1
                .copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (int i = 0; i < 2; i++) ...[
                if (i > 0) AppSpacing.gapMd,
                const Expanded(
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassSkeleton(width: 40, height: 40),
                        SizedBox(height: 10),
                        GlassSkeleton(width: 60, height: 22),
                        SizedBox(height: 6),
                        GlassSkeleton(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          AppSpacing.gapMd,
          const GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassSkeleton(width: 40, height: 40),
                SizedBox(height: 10),
                GlassSkeleton(width: 60, height: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
