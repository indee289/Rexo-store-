import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/image_upload_field.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../services/supabase_service.dart';
import '../providers/campaigns_provider.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _campaignNameController = TextEditingController();
  final _slotsController = TextEditingController();
  final _budgetController = TextEditingController();
  final _perCreatorController = TextEditingController();
  final _companyNameController = TextEditingController();
  DateTime? _deadline;

  String _selectedCategory = 'Logo';
  String _selectedPlatform = 'Instagram';
  String _selectedGender = 'all';
  String _selectedPageProfileCategory = 'Comedy';
  bool _isSubmitting = false;
  String? _coverImageUrl;

  final List<String> _categories = [
    'Logo',
    'UGC',
    'Barter',
    'Clipping',
    'Paid',
    'Repost',
  ];

  final List<String> _platforms = [
    'Instagram',
    'Facebook',
    'YouTube',
  ];

  final List<String> _genders = [
    'all',
    'male',
    'female',
  ];

  final List<String> _pageProfileCategories = [
    'Comedy',
    'Vlog',
    'Meme',
    'Funny',
    'Tech',
    'Travel',
    'Other',
  ];

  @override
  void dispose() {
    _campaignNameController.dispose();
    _slotsController.dispose();
    _budgetController.dispose();
    _perCreatorController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a campaign deadline'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Store platform lowercase for DB CHECK constraint compatibility
      final platformForDb = _selectedPlatform.toLowerCase();

      await SupabaseService.client.from('campaigns').insert({
        'brandId': user.id,           // live: brandId (camelCase)
        'title': _campaignNameController.text.trim(),
        'category': _selectedCategory,
        'platform': platformForDb,
        'slots': int.tryParse(_slotsController.text.trim()) ?? 1,        'filled_slots': 0,
        'budget': double.tryParse(_budgetController.text.trim()) ?? 0,
        'payout_per_creator':
            double.tryParse(_perCreatorController.text.trim()) ?? 0,
        'deadline': _deadline?.toIso8601String(),
        'company_name': _companyNameController.text.trim(),
        'cover_image': _coverImageUrl,
        'gender': _selectedGender,
        'page_profile_category': _selectedPageProfileCategory,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      // Invalidate campaigns list to refresh
      ref.invalidate(campaignsListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Campaign created successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.allMd,
          ),
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to create campaign. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.allMd,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Create campaign',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Campaign Name
              _buildLabel('Campaign Name'),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _campaignNameController,
                hint: 'Enter campaign name',
                prefixIcon: Iconsax.document_text,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a campaign name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 2. Category dropdown
              _buildLabel('Category'),
              const SizedBox(height: AppSpacing.sm),
              _buildDropdown(
                value: _selectedCategory,
                items: _categories,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 3. Platform dropdown
              _buildLabel('Platform'),
              const SizedBox(height: AppSpacing.sm),
              _buildDropdown(
                value: _selectedPlatform,
                items: _platforms,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPlatform = value);
                  }
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 4. Slots (number)
              _buildLabel('Slots'),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _slotsController,
                hint: 'Number of slots (e.g. 10)',
                prefixIcon: Iconsax.people,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter number of slots';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 5. Budget (number)
              _buildLabel('Budget (\u20B9)'),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _budgetController,
                hint: 'Total budget',
                prefixIcon: Iconsax.money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the budget';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 6. Per Creator Budget
              _buildLabel('Per Creator Budget (\u20B9)'),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _perCreatorController,
                hint: 'Payout per creator',
                prefixIcon: Iconsax.money_recive,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter per-creator budget';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 7. Deadline
              _buildLabel('Deadline'),
              const SizedBox(height: AppSpacing.sm),
              _buildDeadlineField(),

              const SizedBox(height: AppSpacing.lg),

              // 8. Company Name
              _buildLabel('Company Name'),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _companyNameController,
                hint: 'Enter company name',
                prefixIcon: Iconsax.building,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter company name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 7. Campaign Cover Image
              ImageUploadField(
                label: 'Campaign Cover Image',
                storageFolder: 'campaign-assets',
                onImageUploaded: (url) {
                  _coverImageUrl = url;
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 8. Gender dropdown
              _buildLabel('Gender'),
              const SizedBox(height: AppSpacing.sm),
              _buildDropdown(
                value: _selectedGender,
                items: _genders,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 9. Page Profile Category dropdown
              _buildLabel('Page Profile Category'),
              const SizedBox(height: AppSpacing.sm),
              _buildDropdown(
                value: _selectedPageProfileCategory,
                items: _pageProfileCategories,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPageProfileCategory = value);
                  }
                },
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Submit button
              PremiumButton(
                label: 'Create campaign',
                icon: Iconsax.add_circle,
                gradient: true,
                loading: _isSubmitting,
                onPressed: _isSubmitting ? null : _handleSubmit,
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppTextStyles.labelLarge);
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Widget _buildDeadlineField() {
    final theme = Theme.of(context);
    final selected = _deadline != null;
    final label = selected
        ? '${_deadline!.day.toString().padLeft(2, '0')}/'
            '${_deadline!.month.toString().padLeft(2, '0')}/${_deadline!.year}'
        : 'Select deadline date';
    return GestureDetector(
      onTap: _pickDeadline,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(Iconsax.calendar_1,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: selected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Iconsax.arrow_down_1,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: theme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Iconsax.arrow_down_1, size: 20),
          style: AppTextStyles.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          dropdownColor: theme.colorScheme.surface,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
