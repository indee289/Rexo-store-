import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/admin_provider.dart';

/// Admin submission review — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over admin-local `PremiumCard`s whose action
/// row mixed an `ElevatedButton.icon`, an `OutlinedButton.icon` and a bare
/// `IconButton` for disburse; the empty and error states were stacked `Text`s;
/// and the disburse flow was an `AlertDialog` wrapping a raw `TextField`.
///
/// New layout: a collapsing large title, cards on the shared surface, the
/// approve/reject pair as a `GlassButton` pair with disburse as a labelled
/// third action rather than an unlabelled icon, and the shared glass states
/// with pull-to-refresh and a retry. Disburse now opens a glass sheet.
///
/// `adminSubmissionsProvider`, `approveSubmission`, `rejectSubmission` and
/// `disburseSubmissionPayout` are unchanged, as is the rule that a non-positive
/// amount does not dismiss the input or disburse anything.
class SubmissionReviewScreen extends ConsumerWidget {
  const SubmissionReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissions = ref.watch(adminSubmissionsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminSubmissionsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GlassLargeTitleHeader(
              title: 'Submission review',
              subtitle: 'Approve, reject or disburse',
              showBack: true,
            ),
            submissions.when(
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.tick_circle,
                      title: 'All caught up',
                      message: 'No pending submissions.',
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
                      final submission = list[index];
                      final id = submission['id'];
                      return RepaintBoundary(
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const GlassIconBubble(
                                    icon: AppIcons.document_upload,
                                    size: 36,
                                    iconSize: 18,
                                  ),
                                  AppSpacing.gapSm,
                                  Expanded(
                                    child: Text(
                                      'Submission #${_shortId(id)}',
                                      style: AppTextStyles.callout.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.gapSm,
                              Text(
                                submission['content'] ??
                                    'No content provided',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.footnote.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              AppSpacing.gapMd,
                              Row(
                                children: [
                                  Expanded(
                                    child: GlassButton(
                                      label: 'Approve',
                                      icon: AppIcons.tick_circle,
                                      size: GlassButtonSize.small,
                                      onPressed: () => ref
                                          .read(adminActionsProvider.notifier)
                                          .approveSubmission(id),
                                    ),
                                  ),
                                  AppSpacing.gapSm,
                                  Expanded(
                                    child: GlassButton.outline(
                                      label: 'Reject',
                                      icon: AppIcons.close_circle,
                                      size: GlassButtonSize.small,
                                      onPressed: () => ref
                                          .read(adminActionsProvider.notifier)
                                          .rejectSubmission(id),
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.gapSm,
                              // Was an unlabelled IconButton wedged into the
                              // action row; now a labelled action.
                              GlassButton.glass(
                                label: 'Disburse payout',
                                icon: AppIcons.money_send,
                                size: GlassButtonSize.small,
                                onPressed: () => _showDisburseSheet(
                                  context,
                                  ref,
                                  id.toString(),
                                ),
                              ),
                            ],
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
                  onRetry: () => ref.invalidate(adminSubmissionsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Disburse flow.
  ///
  /// A sheet rather than a dialog so the amount field clears the keyboard. The
  /// gate is the same as before: a null or non-positive amount neither
  /// disburses nor dismisses. The controller is now disposed — the old
  /// `AlertDialog` version leaked it.
  Future<void> _showDisburseSheet(
    BuildContext context,
    WidgetRef ref,
    String submissionId,
  ) async {
    final controller = TextEditingController();
    try {
      await showGlassSheet<void>(
        context: context,
        title: 'Disburse payout',
        subtitle: 'Submission #${_shortId(submissionId)}',
        child: Builder(
          builder: (sheetContext) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassTextField(
                controller: controller,
                label: 'Amount',
                hint: '0.00',
                prefixText: '\u20B9 ',
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              AppSpacing.gapLg,
              GlassButton(
                label: 'Disburse',
                icon: AppIcons.money_send,
                size: GlassButtonSize.medium,
                onPressed: () {
                  final amount = double.tryParse(controller.text);
                  if (amount != null && amount > 0) {
                    ref
                        .read(adminActionsProvider.notifier)
                        .disburseSubmissionPayout(submissionId, amount);
                    Navigator.pop(sheetContext);
                  } else {
                    showGlassSnackBar(
                      sheetContext,
                      message: 'Enter an amount greater than zero.',
                      tone: GlassToastTone.error,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

/// First 8 characters of an id, or the whole thing when it is shorter.
///
/// The old code called `.substring(0, 8)` directly, which throws on any id
/// shorter than 8 characters; this keeps the same display and cannot throw.
String _shortId(Object? id, {String fallback = ''}) {
  final s = id?.toString() ?? '';
  if (s.isEmpty) return fallback;
  return s.length >= 8 ? s.substring(0, 8) : s;
}
