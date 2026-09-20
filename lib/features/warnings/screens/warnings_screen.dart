import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_sheet.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/warnings_provider.dart';

class WarningsScreen extends ConsumerWidget {
  const WarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warningsAsync = ref.watch(userWarningsProvider);
    final suspensionsAsync = ref.watch(userSuspensionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Warnings & Suspensions', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Suspensions Section
            suspensionsAsync.when(
              data: (suspensions) {
                if (suspensions.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Suspensions',
                      style: AppTextStyles.h6.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...suspensions.map(
                      (s) => _buildSuspensionCard(context, ref, s),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );
              },
              loading: () => const ShimmerLoading(height: 100),
              error: (_, __) => _buildErrorText('Failed to load suspensions'),
            ),
            // Warnings Section
            Text('Warnings', style: AppTextStyles.h6),
            const SizedBox(height: AppSpacing.md),
            warningsAsync.when(
              data: (warnings) {
                if (warnings.isEmpty) {
                  return _buildEmptyState(context);
                }
                return Column(
                  children: warnings
                      .map((w) => _buildWarningCard(context, w))
                      .toList(),
                );
              },
              loading: () => const ShimmerLoading(height: 216),
              error: (_, __) => _buildErrorText('Failed to load warnings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuspensionCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> suspension,
  ) {
    final reason = suspension['reason'] ?? 'No reason provided';
    final startsAt = suspension['starts_at'] != null
        ? DateFormat('MMM dd, yyyy')
            .format(DateTime.parse(suspension['starts_at']))
        : 'Unknown';
    final endsAt = suspension['ends_at'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(suspension['ends_at']))
        : 'Indefinite';
    final appealStatus = suspension['appeal_status'] ?? 'none';
    final suspensionId = suspension['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.warning_2, color: AppColors.error, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Account Suspended',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reason,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Duration: $startsAt - $endsAt',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (appealStatus == 'none')
            PremiumButton(
              label: 'Submit Appeal',
              variant: PremiumButtonVariant.outline,
              icon: Iconsax.message_text,
              onPressed: () =>
                  _showAppealBottomSheet(context, ref, suspensionId),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: _getAppealStatusColor(appealStatus).withOpacity(0.1),
                borderRadius: AppRadius.allSm,
              ),
              child: Text(
                'Appeal: ${appealStatus[0].toUpperCase()}${appealStatus.substring(1).toLowerCase()}',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getAppealStatusColor(appealStatus),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context, Map<String, dynamic> warning) {
    final reason = warning['reason'] ?? 'No reason provided';
    final severity = warning['severity'] ?? 'low';
    final createdAt = warning['created_at'] != null
        ? DateFormat('MMM dd, yyyy')
            .format(DateTime.parse(warning['created_at']))
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSeverityBadge(severity),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  createdAt,
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    switch (severity) {
      case 'high':
        color = AppColors.error;
        break;
      case 'medium':
        color = AppColors.primary;
        break;
      default:
        color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.allSm,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        severity[0].toUpperCase() + severity.substring(1).toLowerCase(),
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _getAppealStatusColor(String status) {
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

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const Icon(
            Iconsax.shield_tick,
            size: 48,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No warnings',
            style: AppTextStyles.labelLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your account is in good standing',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorText(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),
    );
  }

  void _showAppealBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String suspensionId,
  ) {
    final controller = TextEditingController();

    showPremiumSheet<void>(
      context: context,
      title: 'Submit Appeal',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explain why you believe this suspension should be lifted.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumTextField.multiline(
            controller: controller,
            hint: 'Write your appeal...',
            minLines: 4,
            maxLines: 6,
          ),
          const SizedBox(height: AppSpacing.lg),
          Consumer(
            builder: (context, ref, _) {
              final appealState = ref.watch(appealNotifierProvider);
              return PremiumButton(
                label: appealState.isLoading ? 'Submitting...' : 'Submit Appeal',
                gradient: true,
                loading: appealState.isLoading,
                onPressed: appealState.isLoading
                    ? null
                    : () {
                        if (controller.text.trim().isNotEmpty) {
                          ref
                              .read(appealNotifierProvider.notifier)
                              .submitAppeal(
                                suspensionId: suspensionId,
                                appealText: controller.text.trim(),
                              );
                          Navigator.pop(context);
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
