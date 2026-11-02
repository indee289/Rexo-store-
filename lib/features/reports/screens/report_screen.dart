import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/report_provider.dart';

/// Full-screen, routed Report flow (NOT a dialog) — rebuilt layout.
///
/// Reached via `/report` with a `Map` extra:
///   { 'targetType': ReportTargetType, 'targetId': String, 'targetLabel': String }
///
/// Shows the reason list + optional description, submits into moderation_queue,
/// then shows a confirmation screen with the generated report id.
///
/// Old layout: `PremiumAppBar` over a `ListView` of bare `Text` headings, a
/// stack of Material `RadioListTile`s, a raw `TextField`, and a `FilledButton`.
/// The confirmation was a centred column with a 64px bare icon.
///
/// New layout: collapsing large title; the target shown as a card so it is
/// clear *what* is being reported; reasons as a grouped section of selectable
/// rows (a radio dot inside a glass row reads better and gives a full-width
/// target); details as a labelled multiline field; and the confirmation as a
/// proper success card with the report id in a copyable recessed well.
///
/// `reportProvider.submitReport`, `kReportReasons` and the target payload are
/// unchanged.
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
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: 'Could not submit report. Please try again.',
        tone: GlassToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(reportProvider).isLoading;
    final submitted = _reportId != null;

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(
            title: submitted ? 'Report submitted' : 'Report',
            showBack: true,
          ),
          if (submitted)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _Confirmation(reportId: _reportId!),
            )
          else
            ..._formSlivers(isLoading),
        ],
      ),
    );
  }

  List<Widget> _formSlivers(bool isLoading) {
    return [
      // What is being reported.
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: GlassCard(
            borderRadius: AppRadius.allLg,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const GlassIconBubble(
                  icon: AppIcons.flag,
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
                        'Reporting this ${widget.targetType.label}',
                        style: AppTextStyles.footnote
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.targetLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headline.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Reasons as selectable rows.
      SliverToBoxAdapter(
        child: GlassSection(
          title: 'Why are you reporting this?',
          children: [
            for (final r in kReportReasons)
              GlassRow(
                title: r,
                showChevron: false,
                onTap: isLoading ? null : () => setState(() => _reason = r),
                leading: _RadioDot(selected: _reason == r),
              ),
          ],
        ),
      ),

      // Optional details.
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: GlassTextField.multiline(
            controller: _detailsCtrl,
            label: 'Additional details (optional)',
            hint: 'Add anything that helps us review this report',
            enabled: !isLoading,
            maxLength: 1000,
            minLines: 4,
            maxLines: 6,
          ),
        ),
      ),

      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
          ),
          child: GlassButton(
            label: 'Submit report',
            loading: isLoading,
            size: GlassButtonSize.large,
            onPressed: (_reason == null || isLoading) ? null : _submit,
          ),
        ),
      ),
    ];
  }
}

/// Radio indicator used as a row's leading slot.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.systemGray3,
          width: selected ? 6.5 : 1.6,
        ),
      ),
    );
  }
}

/// Post-submit confirmation.
class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassCard(
            borderRadius: AppRadius.allXl,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const GlassIconBubble(
                  icon: AppIcons.tick_circle,
                  color: AppColors.success,
                  size: 60,
                  iconSize: 30,
                ),
                AppSpacing.gapLg,
                Text(
                  'Thanks for letting us know',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title2
                      .copyWith(color: AppColors.textPrimary),
                ),
                AppSpacing.gapSm,
                Text(
                  'Our moderation team will review this report. We take all '
                  'reports seriously and act on those that violate our '
                  'Community Guidelines.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subheadline.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (reportId.isNotEmpty) ...[
                  AppSpacing.gapLg,
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: AppRadius.allMd,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'REPORT ID',
                          style: AppTextStyles.caption1.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          reportId,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subheadline.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.gapXl,
          GlassButton(
            label: 'Done',
            size: GlassButtonSize.large,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
