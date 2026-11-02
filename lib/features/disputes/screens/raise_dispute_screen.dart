import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/disputes_provider.dart';

/// Raise a dispute — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over a form of bare `Text` headings, each above
/// a field, with the Related-To selector as a Material `DropdownButton` inside
/// a hand-built `Container`, and the submit error as a loose red `Text`.
///
/// New layout: collapsing large title; the Related-To choice as a labelled
/// segmented control (two options do not need a dropdown — a dropdown hides
/// both until tapped); the fields using the shared text field with its own
/// labels; and the error as a proper inline error card.
///
/// `disputeNotifierProvider.submitDispute` and its payload keys are unchanged.
class RaiseDisputeScreen extends ConsumerStatefulWidget {
  const RaiseDisputeScreen({super.key});

  @override
  ConsumerState<RaiseDisputeScreen> createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends ConsumerState<RaiseDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _relatedIdController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// Values sent to the provider. Order matters — the segmented control's
  /// index maps into this list.
  static const _relatedTypes = ['Order', 'Campaign'];
  int _relatedIndex = 0;

  String get _relatedType => _relatedTypes[_relatedIndex];

  @override
  void dispose() {
    _relatedIdController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(disputeNotifierProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          const GlassLargeTitleHeader(title: 'Raise dispute', showBack: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        bottom: AppSpacing.sm,
                      ),
                      child: Text(
                        'Related to',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    GlassTabBar(
                      labels: _relatedTypes,
                      selectedIndex: _relatedIndex,
                      onSelected: (i) => setState(() => _relatedIndex = i),
                      margin: EdgeInsets.zero,
                    ),
                    AppSpacing.gapLg,

                    GlassTextField(
                      controller: _relatedIdController,
                      label: '$_relatedType ID',
                      hint: 'Enter the ${_relatedType.toLowerCase()} ID',
                      prefixIcon: AppIcons.hashtag,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'This field is required'
                          : null,
                    ),
                    AppSpacing.gapLg,

                    GlassTextField(
                      controller: _subjectController,
                      label: 'Subject',
                      hint: 'Brief subject of your dispute',
                      prefixIcon: AppIcons.document_text,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Subject is required'
                          : null,
                    ),
                    AppSpacing.gapLg,

                    GlassTextField.multiline(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Describe the issue in detail...',
                      minLines: 5,
                      maxLines: 8,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Description is required'
                          : null,
                    ),

                    if (formState.error != null) ...[
                      AppSpacing.gapLg,
                      _ErrorCard(message: formState.error!),
                    ],

                    AppSpacing.gapXl,
                    GlassButton(
                      label: 'Submit dispute',
                      loading: formState.isSubmitting,
                      size: GlassButtonSize.large,
                      onPressed:
                          formState.isSubmitting ? null : _handleSubmit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await ref.read(disputeNotifierProvider.notifier).submitDispute(
              relatedType: _relatedType,
              relatedId: _relatedIdController.text.trim(),
              subject: _subjectController.text.trim(),
              description: _descriptionController.text.trim(),
            );

    if (!mounted) return;

    if (success) {
      showGlassSnackBar(
        context,
        message: 'Dispute submitted successfully',
        tone: GlassToastTone.success,
      );
      context.pop();
    }
  }
}

/// Inline submit error.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: AppColors.error.withOpacity(0.28),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.warning_2, size: 18, color: AppColors.error),
          AppSpacing.gapSm,
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.footnote.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
