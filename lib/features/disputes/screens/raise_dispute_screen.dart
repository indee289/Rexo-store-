import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../providers/disputes_provider.dart';

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
  String _relatedType = 'Order';

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Raise Dispute', style: AppTextStyles.h5),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: PremiumIconButton(
            icon: Iconsax.arrow_left,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Related type dropdown
              Text('Related To', style: AppTextStyles.h6),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.allSm,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _relatedType,
                    isExpanded: true,
                    style: AppTextStyles.bodyMedium,
                    items: const [
                      DropdownMenuItem(
                        value: 'Order',
                        child: Text('Order'),
                      ),
                      DropdownMenuItem(
                        value: 'Campaign',
                        child: Text('Campaign'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _relatedType = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Related ID
              Text('$_relatedType ID', style: AppTextStyles.h6),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _relatedIdController,
                hint: 'Enter the ${_relatedType.toLowerCase()} ID',
                prefixIcon: Iconsax.hashtag,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Subject
              Text('Subject', style: AppTextStyles.h6),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _subjectController,
                hint: 'Brief subject of your dispute',
                prefixIcon: Iconsax.document_text,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Subject is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Description
              Text('Description', style: AppTextStyles.h6),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField.multiline(
                controller: _descriptionController,
                hint: 'Describe the issue in detail...',
                minLines: 5,
                maxLines: 8,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Error message
              if (formState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    formState.error!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),

              // Submit button
              PremiumButton(
                label: 'Submit Dispute',
                gradient: true,
                loading: formState.isSubmitting,
                onPressed: formState.isSubmitting ? null : _handleSubmit,
              ),
            ],
          ),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dispute submitted successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.allSm,
          ),
        ),
      );
      context.pop();
    }
  }
}
