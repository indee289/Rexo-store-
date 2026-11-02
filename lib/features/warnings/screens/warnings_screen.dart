import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/warnings_provider.dart';

/// Warnings & suspensions — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over bare `Text` headings above columns of
/// hand-built `Container` cards; the empty state was another bordered box; the
/// appeal form opened in a `showPremiumSheet`.
///
/// New layout: collapsing large title; an active suspension gets its own
/// red-edged card at the top (it is the most consequential thing on the
/// screen) with the appeal action on it; warnings become rows carrying a
/// severity chip; and a clear account shows the shared empty state instead of
/// a custom box.
///
/// `userWarningsProvider`, `userSuspensionsProvider` and
/// `appealNotifierProvider.submitAppeal` are unchanged.
class WarningsScreen extends ConsumerWidget {
  const WarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warningsAsync = ref.watch(userWarningsProvider);
    final suspensionsAsync = ref.watch(userSuspensionsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          const GlassLargeTitleHeader(
            title: 'Warnings & suspensions',
            showBack: true,
          ),

          // Active suspensions first — highest consequence.
          SliverToBoxAdapter(
            child: suspensionsAsync.when(
              data: (suspensions) {
                if (suspensions.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final s in suspensions)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _SuspensionCard(suspension: s),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: GlassLoader(size: 24),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Warnings.
          SliverToBoxAdapter(
            child: warningsAsync.when(
              data: (warnings) {
                if (warnings.isEmpty) {
                  return const GlassEmptyState(
                    icon: AppIcons.shield_tick,
                    title: 'No warnings',
                    message: 'Your account is in good standing.',
                    compact: true,
                  );
                }
                return GlassSection(
                  title: 'Warnings',
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
                  ),
                  children: [
                    for (final w in warnings) _WarningRow(warning: w),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: GlassLoader(),
              ),
              error: (_, __) => GlassErrorState(
                compact: true,
                title: 'Failed to load warnings',
                onRetry: () => ref.invalidate(userWarningsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuspensionCard extends ConsumerWidget {
  const _SuspensionCard({required this.suspension});

  final Map<String, dynamic> suspension;

  static Color _appealColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reason = (suspension['reason'] ?? 'No reason provided').toString();
    final startsAt = suspension['starts_at'] != null
        ? DateFormat('MMM dd, yyyy')
            .format(DateTime.parse(suspension['starts_at']))
        : 'Unknown';
    final endsAt = suspension['ends_at'] != null
        ? DateFormat('MMM dd, yyyy')
            .format(DateTime.parse(suspension['ends_at']))
        : 'Indefinite';
    final appealStatus = (suspension['appeal_status'] ?? 'none').toString();
    final suspensionId = suspension['id'] as String;

    return GlassCard(
      borderRadius: AppRadius.allLg,
      rim: AppColors.error.withOpacity(0.32),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const GlassIconBubble(
                icon: AppIcons.warning_2,
                color: AppColors.error,
                size: 36,
                iconSize: 18,
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Text(
                  'Account suspended',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Text(
            reason,
            style: AppTextStyles.subheadline.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          AppSpacing.gapSm,
          Text(
            'Duration: $startsAt — $endsAt',
            style: AppTextStyles.footnote
                .copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.gapLg,
          if (appealStatus == 'none')
            GlassButton.outline(
              label: 'Submit appeal',
              icon: AppIcons.message_text,
              onPressed: () =>
                  _showAppealSheet(context, ref, suspensionId),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: GlassChip.status(
                label: 'Appeal: '
                    '${appealStatus[0].toUpperCase()}'
                    '${appealStatus.substring(1).toLowerCase()}',
                color: _appealColor(appealStatus),
              ),
            ),
        ],
      ),
    );
  }

  void _showAppealSheet(
    BuildContext context,
    WidgetRef ref,
    String suspensionId,
  ) {
    final controller = TextEditingController();

    showGlassSheet<void>(
      context: context,
      title: 'Submit appeal',
      subtitle: 'Reviewed by the moderation team',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Explain why you believe this suspension should be lifted.',
            style: AppTextStyles.subheadline.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          AppSpacing.gapLg,
          GlassTextField.multiline(
            controller: controller,
            hint: 'Write your appeal...',
            minLines: 4,
            maxLines: 6,
          ),
          AppSpacing.gapLg,
          Consumer(
            builder: (sheetContext, innerRef, _) {
              final appealState = innerRef.watch(appealNotifierProvider);
              return GlassButton(
                label: 'Submit appeal',
                loading: appealState.isLoading,
                size: GlassButtonSize.large,
                onPressed: appealState.isLoading
                    ? null
                    : () {
                        if (controller.text.trim().isNotEmpty) {
                          innerRef
                              .read(appealNotifierProvider.notifier)
                              .submitAppeal(
                                suspensionId: suspensionId,
                                appealText: controller.text.trim(),
                              );
                          Navigator.pop(sheetContext);
                        }
                      },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow({required this.warning});

  final Map<String, dynamic> warning;

  static Color _severityColor(String severity) {
    switch (severity) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = (warning['reason'] ?? 'No reason provided').toString();
    final severity = (warning['severity'] ?? 'low').toString();
    final createdAt = warning['created_at'] != null
        ? DateFormat('MMM dd, yyyy')
            .format(DateTime.parse(warning['created_at']))
        : 'Unknown';
    final color = _severityColor(severity);

    return GlassRow(
      icon: AppIcons.flag,
      iconColor: color,
      title: reason,
      subtitle: createdAt,
      showChevron: false,
      trailing: GlassChip.status(
        label: severity[0].toUpperCase() + severity.substring(1).toLowerCase(),
        color: color,
      ),
    );
  }
}
