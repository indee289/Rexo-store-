import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../providers/report_provider.dart';

/// Full-screen, routed Report flow (NOT a dialog).
///
/// Reached via `/report` with a `Map` extra:
///   { 'targetType': ReportTargetType, 'targetId': String, 'targetLabel': String }
///
/// Shows the reason list + optional description, submits into moderation_queue,
/// then shows a confirmation screen with the generated report id.
class ReportScreen extends ConsumerStatefulWidget {
  final ReportTargetType targetType;
  final String targetId;
  final String targetLabel;

  const ReportScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
  });

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String? _reason;
  final _detailsCtrl = TextEditingController();
  String? _reportId; // set once submitted → confirmation view

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final id = await ref.read(reportProvider.notifier).submitReport(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: reason,
            details: _detailsCtrl.text,
          );
      if (!mounted) return;
      setState(() => _reportId = id);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not submit report. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(reportProvider).isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: _reportId == null ? 'Report' : 'Report submitted',
        showBack: true,
      ),
      body: SafeArea(
        child: _reportId == null
            ? _buildForm(isLoading)
            : _buildConfirmation(_reportId!),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(
          'Report this ${widget.targetType.label}',
          style: AppTextStyles.h6,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.targetLabel,
          style: AppTextStyles.bodySmall
              .copyWith(color: theme_onSurfaceMuted(context)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Why are you reporting this?', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        ...kReportReasons.map(
          (r) => RadioListTile<String>(
            value: r,
            groupValue: _reason,
            onChanged:
                isLoading ? null : (v) => setState(() => _reason = v),
            title: Text(r),
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Additional details (optional)',
            style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _detailsCtrl,
          enabled: !isLoading,
          maxLines: 4,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: 'Add anything that helps us review this report',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: (_reason == null || isLoading) ? null : _submit,
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit report'),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation(String reportId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.tick_circle,
                size: 64, color: AppColors.success),
            const SizedBox(height: AppSpacing.lg),
            Text('Thanks for letting us know',
                style: AppTextStyles.h5, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Our moderation team will review this report. We take all '
              'reports seriously and act on those that violate our '
              'Community Guidelines.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: theme_onSurfaceMuted(context)),
              textAlign: TextAlign.center,
            ),
            if (reportId.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Report ID',
                style: AppTextStyles.caption
                    .copyWith(color: theme_onSurfaceMuted(context)),
              ),
              const SizedBox(height: 2),
              SelectableText(
                reportId,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color theme_onSurfaceMuted(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
