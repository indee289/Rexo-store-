import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/disputes_provider.dart';

/// My disputes — rebuilt layout.
///
/// Old layout: `PremiumAppBar` with a `TextButton.icon` action over a
/// `ListView` of `PremiumCard`s, each a subject line with a hand-built status
/// `Container` badge and a date underneath.
///
/// New layout: collapsing large title with the open count, the raise action as
/// a glass icon button in the bar, and each dispute as a row carrying its
/// status chip and a chevron — a dispute list is a list, not a stack of cards.
///
/// `userDisputesProvider` and the `/disputes/raise` route are unchanged.
class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputesAsync = ref.watch(userDisputesProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
        onRefresh: () async => ref.invalidate(userDisputesProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            GlassLargeTitleHeader(
              title: 'Disputes',
              showBack: true,
              subtitle: disputesAsync.maybeWhen(
                data: (d) => d.isEmpty ? null : '${d.length} total',
                orElse: () => null,
              ),
              actions: [
                GlassIconButton.filled(
                  icon: AppIcons.add,
                  tooltip: 'Raise a dispute',
                  size: 36,
                  iconSize: 18,
                  onTap: () => context.push('/disputes/raise'),
                ),
              ],
            ),
            disputesAsync.when(
              data: (disputes) {
                if (disputes.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.message_question,
                      title: 'No disputes',
                      message: 'You have no active disputes at the moment.',
                      actionLabel: 'Raise a dispute',
                      onAction: () => context.push('/disputes/raise'),
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: GlassSection(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      for (final d in disputes) _DisputeRow(dispute: d),
                    ],
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: GlassLoader(),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: GlassErrorState(
                  title: 'Failed to load disputes',
                  message: ErrorUtils.sanitize(error),
                  onRetry: () => ref.invalidate(userDisputesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisputeRow extends StatelessWidget {
  const _DisputeRow({required this.dispute});

  final Map<String, dynamic> dispute;

  /// Status drives both the chip colour and the row's icon tint, so state is
  /// readable without reading the label.
  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.info;
      case 'investigating':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textHint;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = dispute['status'] as String? ?? 'open';
    final subject = dispute['subject'] as String? ?? 'No Subject';
    final createdAt = dispute['created_at'] as String?;
    final color = _statusColor(status);

    String formattedDate = '';
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        formattedDate = DateFormat('dd MMM yyyy').format(date);
      }
    }

    return GlassRow(
      icon: AppIcons.message_question,
      iconColor: color,
      title: subject,
      subtitle: formattedDate.isEmpty ? null : formattedDate,
      showChevron: false,
      trailing: GlassChip.status(
        label: status[0].toUpperCase() + status.substring(1),
        color: color,
      ),
    );
  }
}
