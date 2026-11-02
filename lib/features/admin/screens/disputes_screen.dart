import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/admin_provider.dart';

/// Admin disputes — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over admin-local `PremiumCard`s with a
/// hand-built tinted icon square, the status folded into a grey text line, the
/// metadata as a newline-joined string, and an `AlertDialog` + raw `TextField`
/// for the resolution.
///
/// New layout: a collapsing large title, cards on the shared surface with the
/// status as a colour-coded chip, the metadata as discrete labelled rows
/// instead of a run-on block, a resolution callout when one exists, and the
/// resolve flow as a glass sheet.
///
/// `adminDisputesProvider`, `resolveDispute`, the `subject`-with-`title`-
/// fallback reading, the date formatting and the rule that resolved disputes
/// show no action are unchanged.
class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputes = ref.watch(adminDisputesProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminDisputesProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GlassLargeTitleHeader(
              title: 'Disputes',
              subtitle: 'Resolve open cases',
              showBack: true,
            ),
            disputes.when(
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.tick_circle,
                      title: 'No disputes yet',
                      message: 'Nothing needs attention.',
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
                    itemCount: list.length,
                    separatorBuilder: (_, __) => AppSpacing.gapMd,
                    itemBuilder: (context, index) {
                      final dispute = list[index];
                      return RepaintBoundary(
                        child: _DisputeCard(
                          dispute: dispute,
                          onResolve: () => _showResolveSheet(
                            context,
                            ref,
                            dispute['id'].toString(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: GlassListSkeleton(itemCount: 5),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: GlassErrorState(
                  message: ErrorUtils.sanitize(error),
                  onRetry: () => ref.invalidate(adminDisputesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The table column is `subject` (the old code read a non-existent `title`).
  static String _titleOf(Map<String, dynamic> d) {
    final subject = (d['subject'] ?? d['title'] ?? '').toString().trim();
    if (subject.isNotEmpty) return subject;
    final id = (d['id'] ?? '').toString();
    return 'Dispute #${id.length > 8 ? id.substring(0, 8) : id}';
  }

  static String _dateOf(Map<String, dynamic> d) {
    final raw = (d['created_at'] ?? d['createdAt'] ?? '').toString();
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  /// Metadata as discrete pairs. The old version joined these with newlines
  /// into one grey block; they are now separate rows.
  static List<(String, String)> _metaOf(Map<String, dynamic> d) {
    final parts = <(String, String)>[];
    final user = (d['user_id'] ?? '').toString();
    if (user.isNotEmpty) parts.add(('User', user));
    final order = (d['order_id'] ?? '').toString();
    if (order.isNotEmpty) parts.add(('Order', order));
    final campaign = (d['campaign_id'] ?? '').toString();
    if (campaign.isNotEmpty) parts.add(('Campaign', campaign));
    return parts;
  }

  /// Resolve flow. The non-empty guard is unchanged, and the controller is now
  /// disposed — the old dialog leaked it.
  Future<void> _showResolveSheet(
    BuildContext context,
    WidgetRef ref,
    String disputeId,
  ) async {
    final controller = TextEditingController();
    try {
      final text = await showGlassSheet<String>(
        context: context,
        title: 'Resolve dispute',
        subtitle: 'The user is notified once you resolve',
        child: Builder(
          builder: (sheetContext) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassTextField.multiline(
                controller: controller,
                label: 'Resolution',
                hint: 'Describe the resolution…',
                minLines: 3,
                maxLines: 6,
              ),
              AppSpacing.gapLg,
              GlassButton(
                label: 'Resolve',
                icon: AppIcons.tick_circle,
                size: GlassButtonSize.medium,
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    showGlassSnackBar(
                      sheetContext,
                      message: 'Describe the resolution first.',
                      tone: GlassToastTone.warning,
                    );
                    return;
                  }
                  Navigator.pop(sheetContext, value);
                },
              ),
            ],
          ),
        ),
      );

      if (text == null) return;

      final ok = await ref
          .read(adminActionsProvider.notifier)
          .resolveDispute(disputeId, text);

      if (!context.mounted) return;
      showGlassSnackBar(
        context,
        message: ok
            ? 'Dispute resolved. The user has been notified.'
            : 'Could not resolve the dispute. Please try again.',
        tone: ok ? GlassToastTone.success : GlassToastTone.error,
      );
    } finally {
      controller.dispose();
    }
  }
}

class _DisputeCard extends StatelessWidget {
  final Map<String, dynamic> dispute;
  final VoidCallback onResolve;

  const _DisputeCard({required this.dispute, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    final status = (dispute['status'] ?? 'open').toString();
    final isResolved = status.toLowerCase() == 'resolved';
    final date = DisputesScreen._dateOf(dispute);
    final meta = DisputesScreen._metaOf(dispute);
    final description = dispute['description'];
    final resolution = (dispute['resolution'] ?? '').toString();

    return GlassCard(
      rim: isResolved ? AppColors.success.withOpacity(0.28) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassIconBubble(
                icon: AppIcons.message_question,
                color: isResolved ? AppColors.success : AppColors.error,
                size: 36,
                iconSize: 18,
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DisputesScreen._titleOf(dispute),
                      style: AppTextStyles.callout.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: AppTextStyles.caption1
                            .copyWith(color: AppColors.textHint),
                      ),
                  ],
                ),
              ),
              AppSpacing.gapSm,
              GlassChip.status(
                label: status,
                color: isResolved ? AppColors.success : AppColors.warning,
              ),
            ],
          ),

          if (description != null) ...[
            AppSpacing.gapSm,
            Text(
              description.toString(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],

          if (meta.isNotEmpty) ...[
            AppSpacing.gapSm,
            for (final (label, value) in meta)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Text(
                      '$label: ',
                      style: AppTextStyles.caption1
                          .copyWith(color: AppColors.textHint),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption1
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          if (resolution.isNotEmpty) ...[
            AppSpacing.gapMd,
            GlassCard(
              level: GlassLevel.subtle,
              rim: AppColors.success.withOpacity(0.25),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    AppIcons.tick_circle,
                    size: 15,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      resolution,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!isResolved) ...[
            AppSpacing.gapMd,
            GlassButton(
              label: 'Resolve',
              icon: AppIcons.tick_circle,
              size: GlassButtonSize.small,
              onPressed: onResolve,
            ),
          ],
        ],
      ),
    );
  }
}
