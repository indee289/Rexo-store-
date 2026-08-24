import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../providers/campaigns_provider.dart';

class ApplyScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const ApplyScreen({
    super.key,
    required this.campaignId,
  });

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _contactController = TextEditingController();
  final _instagramController = TextEditingController();
  final _followersController = TextEditingController();
  final _pitchController = TextEditingController();
  final _portfolioUrlController = TextEditingController();

  bool _isSubmitting = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _contactController.dispose();
    _instagramController.dispose();
    _followersController.dispose();
    _pitchController.dispose();
    _portfolioUrlController.dispose();
    super.dispose();
  }

  /// Prefill Name / Instagram from the signed-in user's profile the first time
  /// the profile becomes available.
  void _maybePrefill(Map<String, dynamic>? profile) {
    if (_prefilled || profile == null) return;
    _prefilled = true;
    final name = (profile['name'] ?? '').toString();
    if (name.isNotEmpty && _nameController.text.isEmpty) {
      _nameController.text = name;
    }
    final handle = (profile['handle'] ?? '').toString();
    if (handle.isNotEmpty && _instagramController.text.isEmpty) {
      _instagramController.text = handle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final campaignAsync = ref.watch(campaignDetailProvider(widget.campaignId));

    // Prefill from the current user's profile when it loads.
    ref.listen(applyPrefillProfileProvider, (_, next) {
      next.whenData(_maybePrefill);
    });
    _maybePrefill(ref.watch(applyPrefillProfileProvider).valueOrNull);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Apply to Campaign', style: AppTextStyles.h5),
        centerTitle: false,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: PremiumIconButton(
          icon: Iconsax.arrow_left,
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign title display
              campaignAsync.when(
                data: (campaign) {
                  if (campaign == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: AppRadius.allMd,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.briefcase,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            (campaign['title'] ?? 'Campaign').toString(),
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Name
              _buildField(
                label: 'Name',
                controller: _nameController,
                hint: 'Your full name',
                icon: Iconsax.user,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your name'
                    : null,
              ),

              // Location
              _buildField(
                label: 'Location',
                controller: _locationController,
                hint: 'Country / region',
                icon: Iconsax.location,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your location'
                    : null,
              ),

              // Category
              _buildField(
                label: 'Category / Niche',
                controller: _categoryController,
                hint: 'e.g. Fashion, Tech, Fitness',
                icon: Iconsax.category,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your category'
                    : null,
              ),

              // City + State (side by side)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'City',
                      controller: _cityController,
                      hint: 'City',
                      icon: Iconsax.building,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter city' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildField(
                      label: 'State',
                      controller: _stateController,
                      hint: 'State',
                      icon: Iconsax.map,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter state'
                          : null,
                    ),
                  ),
                ],
              ),

              // Contact number
              _buildField(
                label: 'Contact Number',
                controller: _contactController,
                hint: '10-digit mobile number',
                icon: Iconsax.call,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                ],
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Please enter your contact number';
                  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length < 7 || digits.length > 15) {
                    return 'Enter a valid contact number';
                  }
                  return null;
                },
              ),

              // Instagram profile link
              _buildField(
                label: 'Instagram Profile',
                controller: _instagramController,
                hint: '@handle or https://instagram.com/handle',
                icon: Iconsax.instagram,
                keyboardType: TextInputType.url,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) {
                    return 'Please enter your Instagram profile';
                  }
                  // Accept either a bare handle or a full/instagram URL.
                  final handleOk =
                      RegExp(r'^@?[A-Za-z0-9._]{1,30}$').hasMatch(value);
                  final uri = Uri.tryParse(value);
                  final urlOk = uri != null && uri.hasScheme && uri.hasAuthority;
                  if (!handleOk && !urlOk) {
                    return 'Enter a valid handle or profile link';
                  }
                  return null;
                },
              ),

              // Followers
              _buildField(
                label: 'Followers',
                controller: _followersController,
                hint: 'Total followers (number)',
                icon: Iconsax.people,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Please enter your followers count';
                  final n = int.tryParse(value);
                  if (n == null || n < 0) return 'Enter a valid number';
                  return null;
                },
              ),

              // Pitch field (multiline)
              Text('Your Pitch', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField.multiline(
                controller: _pitchController,
                hint:
                    'Tell the brand why you are the right fit for this campaign...',
                minLines: 5,
                maxLines: 6,
                maxLength: 500,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your pitch';
                  }
                  if (value.trim().length < 20) {
                    return 'Pitch should be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Portfolio URL field (optional)
              Text('Portfolio URL (optional)', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _portfolioUrlController,
                hint: 'https://your-portfolio.com',
                prefixIcon: Iconsax.link,
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final uri = Uri.tryParse(value);
                    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Submit button
              PremiumButton(
                label: 'Submit Application',
                icon: Iconsax.send_2,
                gradient: true,
                loading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submitApplication,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          PremiumTextField(
            controller: controller,
            hint: hint,
            prefixIcon: icon,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            validator: validator,
          ),
        ],
      ),
    );
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success =
        await ref.read(campaignActionsProvider.notifier).applyToCampaign(
              campaignId: widget.campaignId,
              pitch: _pitchController.text.trim(),
              portfolioUrl: _portfolioUrlController.text.trim(),
              applicantName: _nameController.text.trim(),
              location: _locationController.text.trim(),
              category: _categoryController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              contactNumber: _contactController.text.trim(),
              instagramUrl: _instagramController.text.trim(),
              followersCount: int.tryParse(_followersController.text.trim()),
            );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      // Invalidate the hasApplied provider
      ref.invalidate(hasAppliedProvider(widget.campaignId));

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.allLg,
          ),
          title: Row(
            children: [
              const Icon(Iconsax.tick_circle, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Text('Application Sent!', style: AppTextStyles.h6),
            ],
          ),
          content: Text(
            'Your application has been submitted successfully. The brand will review it and get back to you.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop();
              },
              child: Text(
                'OK',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final actionState = ref.read(campaignActionsProvider);
      final errorMsg = actionState.hasError
          ? ErrorUtils.sanitize(actionState.error)
          : 'Failed to submit application. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.allSm,
          ),
        ),
      );
    }
  }
}
