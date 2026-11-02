import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/fraud_provider.dart';

/// Admin "Risk & Fraud" review surface. Shows heuristic wallet risk flags
/// derived from deposits/withdrawals. Review-only — it never moves money.
///
/// Rebuilt: the `PremiumAppBar` becomes a collapsing large title; the empty
/// state (a bare icon and a centred `Text` pushed down by a 120px spacer in a
/// `ListView`) and the error state (a naked `Text`) become the shared glass
/// states with a retry; and each flag is now a card whose rim carries the
/// severity, with the severity and type as chips rather than two hand-built
/// tinted boxes.
///
/// `flaggedActivityProvider` and every `RiskFlag` field read — including the
/// 8-character user-id truncation and the `velocity-` prefix check that
/// suppresses the amount — are unchanged.
class FraudReviewScreen extends ConsumerWidget {
  const FraudReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(flaggedActivityProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(flaggedActivityProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GlassLargeTitleHeader(
              title: 'Risk & fraud',
              subtitle: 'Review-only — no money moves here',
              showBack: true,
            ),
            flagsAsync.when(
              data: (flags) {
                if (flags.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.shield_tick,
                      title: 'No risk flags',
                      message: 'Nothing has tripped the heuristics.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: flags.length,
                    separatorBuilder: (_, __) => AppSpacing.gapMd,
                    itemBuilder: (context, index) => RepaintBoundary(
                      child: _FlagCard(flag: flags[index]),
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: GlassListSkeleton(itemCount: 6),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: GlassErrorState(
                  message: ErrorUtils.sanitize(error),
                  onRetry: () => ref.invalidate(flaggedActivityProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  final RiskFlag flag;
  const _FlagCard({required this.flag});

  @override
  Widget build(BuildContext context) {
    final isHigh = flag.severity == 'high';
    final color = isHigh ? AppColors.error : AppColors.warning;
    final date = flag.createdAt != null
        ? DateFormat('MMM dd, HH:mm').format(flag.createdAt!)
        : '';

    final userLabel = flag.userId.isNotEmpty && flag.userId.length >= 8
        ? flag.userId.substring(0, 8)
        : flag.userId;

    return GlassCard(
      // The rim carries the severity, so a high flag reads at a glance.
      rim: color.withOpacity(isHigh ? 0.40 : 0.28),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassChip.status(
                label: flag.severity.toUpperCase(),
                color: color,
              ),
              AppSpacing.gapSm,
              GlassChip.status(
                label: flag.type[0].toUpperCase() + flag.type.substring(1),
                color: AppColors.primary,
              ),
              const Spacer(),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textHint),
                ),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            flag.reason,
            style: AppTextStyles.callout.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'User: $userLabel'
            '${flag.id.startsWith('velocity-') ? '' : '  ·  \u20B9${flag.amount}'}',
            style: AppTextStyles.footnote
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
