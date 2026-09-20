import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/demo_asset_field.dart';
import '../../../core/widgets/image_upload_field.dart';
import '../../../services/supabase_service.dart';
import '../providers/admin_provider.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingCampaign;
  const CreateCampaignScreen({super.key, this.existingCampaign});

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
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  DateTime? _deadline;

  String _selectedCategory = 'Logo';
  List<String> _selectedPlatforms = ['Instagram'];
  DemoAssetType _demoAssetType = DemoAssetType.none;
  String? _demoAssetValue;
  String _selectedGender = 'all';
  String _selectedPageProfileCategory = 'Comedy';
  String? _coverImageUrl;
  bool _isSubmitting = false;

  bool get _isEdit => widget.existingCampaign != null;

  static const List<String> _categories = [
    'Logo',
    'UGC',
    'Barter',
    'Clipping',
    'Paid',
    'Repost',
  ];

  static const List<String> _platforms = [
    'Instagram',
    'Facebook',
    'YouTube',
  ];

  static const List<String> _genders = [
    'all',
    'male',
    'female',
  ];

  static const List<String> _pageProfileCategories = [
    'Comedy',
    'Vlog',
    'Meme',
    'Funny',
    'Tech',
    'Travel',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existingCampaign;
    if (e != null) {
      _campaignNameController.text = e['title'] as String? ?? '';
      _slotsController.text = (e['total_slots'] ?? '').toString();
      _budgetController.text = (e['budget'] ?? '').toString();
      _perCreatorController.text = (e['per_creator_payout'] ?? '').toString();
      _companyNameController.text = e['company_name'] as String? ?? '';
      _descriptionController.text = e['description'] as String? ?? '';
      _rulesController.text = e['rules'] as String? ?? '';
      _coverImageUrl = e['cover_image_url'] as String?;
      if (e['category'] != null && _categories.contains(e['category'])) {
        _selectedCategory = e['category'] as String;
      }
      if (e['platform'] != null &&
          (e['platform'] as String).trim().isNotEmpty) {
        final parsed = (e['platform'] as String)
            .split(',')
            .map((x) => x.trim())
            .where((x) => x.isNotEmpty)
            .map((x) => _platforms.firstWhere(
                  (p) => p.toLowerCase() == x.toLowerCase(),
                  orElse: () => '',
                ))
            .where((x) => x.isNotEmpty)
            .toSet()
            .toList();
        if (parsed.isNotEmpty) {
          _selectedPlatforms = parsed;
        }
      }
      _demoAssetType = demoAssetTypeFromKey(e['demo_asset_type'] as String?);
      _demoAssetValue = e['demo_asset_url'] as String?;
      if (e['gender'] != null && _genders.contains(e['gender'])) {
        _selectedGender = e['gender'] as String;
      }
      if (e['page_profile_category'] != null &&
          _pageProfileCategories.contains(e['page_profile_category'])) {
        _selectedPageProfileCategory = e['page_profile_category'] as String;
      }
      if (e['deadline'] != null) {
        _deadline = DateTime.tryParse(e['deadline'].toString());
      }
    }
  }

  @override
  void dispose() {
    _campaignNameController.dispose();
    _slotsController.dispose();
    _budgetController.dispose();
    _perCreatorController.dispose();
    _companyNameController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a campaign deadline'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'title': _campaignNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'platform': _selectedPlatforms.join(','),
        'total_slots': int.parse(_slotsController.text.trim()),
        'budget': double.parse(_budgetController.text.trim()),
        'per_creator_payout':
            double.tryParse(_perCreatorController.text.trim()) ?? 0,
        'deadline': _deadline?.toIso8601String(),
        'company_name': _companyNameController.text.trim(),
        'gender': _selectedGender,
        'page_profile_category': _selectedPageProfileCategory,
      };

      if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) {
        data['cover_image_url'] = _coverImageUrl;
      }

      // Optional campaign rules (plain value; safe to write).
      final rules = _rulesController.text.trim();
      if (rules.isNotEmpty) {
        data['rules'] = rules;
      } else if (_isEdit) {
        // On edit, clear rules if the admin emptied the field.
        data['rules'] = null;
      }

      // Optional demo asset (plain values; safe to write).
      final demoValue = _demoAssetValue?.trim();
      if (_demoAssetType != DemoAssetType.none &&
          demoValue != null &&
          demoValue.isNotEmpty) {
        data['demo_asset_type'] = demoAssetTypeToKey(_demoAssetType);
        data['demo_asset_url'] = demoValue;
      } else if (_isEdit) {
        // On edit, clear the demo asset if it was removed.
        data['demo_asset_type'] = null;
        data['demo_asset_url'] = null;
      }

      if (_isEdit) {
        await SupabaseService.client
            .from('campaigns')
            .update(data)
            .eq('id', widget.existingCampaign!['id'] as String);
      } else {
        data['brand_id'] = SupabaseService.currentUser?.id;
        data['status'] = 'active';
        await SupabaseService.client.from('campaigns').insert(data);
      }

      ref.invalidate(adminCampaignsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Campaign updated!' : 'Campaign created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.sanitize(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Campaign' : 'Create Campaign',
            style: AppTextStyles.h5),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.arrow_left),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign Name
              _buildLabel('Campaign Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _campaignNameController,
                decoration: _inputDecoration(
                  hint: 'Enter campaign name',
                  icon: Iconsax.edit,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campaign name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Campaign Description
              _buildLabel('Campaign Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 6,
                decoration: _inputDecoration(
                  hint: 'Describe the campaign, what creators should do…',
                  icon: Iconsax.document_text,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campaign description is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Category Dropdown
              _buildLabel('Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration(
                  hint: 'Select category',
                  icon: Iconsax.category,
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Platforms (multi-select)
              _buildLabel('Platforms'),
              const SizedBox(height: 8),
              _buildPlatformChips(),

              const SizedBox(height: 20),

              // Slots
              _buildLabel('Slots'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _slotsController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  hint: 'Number of slots',
                  icon: Iconsax.people,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Slots is required';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Budget
              _buildLabel('Budget'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  hint: 'Campaign budget',
                  icon: Iconsax.wallet_3,
                  prefix: '\u20B9 ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Budget is required';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Per Creator Budget
              _buildLabel('Per Creator Budget'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _perCreatorController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  hint: 'Payout per creator',
                  icon: Iconsax.money_recive,
                  prefix: '\u20B9 ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Per-creator budget is required';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Deadline
              _buildLabel('Deadline'),
              const SizedBox(height: 8),
              _buildDeadlineField(),

              const SizedBox(height: 20),

              // Company Name
              _buildLabel('Company Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _companyNameController,
                decoration: _inputDecoration(
                  hint: 'Enter company name',
                  icon: Iconsax.building,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Company name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Campaign Cover Image
              ImageUploadField(
                label: 'Campaign Cover Image',
                storageFolder: 'campaign-images',
                currentImageUrl: _coverImageUrl,
                onImageUploaded: (url) {
                  setState(() => _coverImageUrl = url);
                },
              ),

              const SizedBox(height: 20),

              // Campaign Rules (Optional)
              _buildLabel('Campaign Rules (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rulesController,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 6,
                decoration: _inputDecoration(
                  hint: 'Add any rules or guidelines for creators…',
                  icon: Iconsax.task_square,
                ),
              ),

              const SizedBox(height: 20),

              // Demo Asset (Optional)
              _buildLabel('Demo Asset (Optional)'),
              const SizedBox(height: 8),
              DemoAssetField(
                storageFolder: 'campaign-demo-assets',
                initialType: _demoAssetType,
                initialValue: _demoAssetValue,
                onChanged: (type, value) {
                  setState(() {
                    _demoAssetType = type;
                    _demoAssetValue = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Gender Dropdown
              _buildLabel('Gender'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: _inputDecoration(
                  hint: 'Select gender',
                  icon: Iconsax.user,
                ),
                items: _genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Page Profile Category Dropdown
              _buildLabel('Page Profile Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPageProfileCategory,
                decoration: _inputDecoration(
                  hint: 'Select page profile category',
                  icon: Iconsax.tag,
                ),
                items: _pageProfileCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPageProfileCategory = value);
                  }
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEdit ? 'Save Changes' : 'Submit Campaign',
                          style: AppTextStyles.button),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPlatformChips() {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _platforms.map((platform) {
        final isSelected = _selectedPlatforms.contains(platform);
        return ChoiceChip(
          label: Text(platform),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) {
            setState(() {
              if (isSelected) {
                // Keep at least one platform selected.
                if (_selectedPlatforms.length > 1) {
                  _selectedPlatforms.remove(platform);
                }
              } else {
                _selectedPlatforms.add(platform);
              }
            });
          },
          selectedColor: AppColors.primary,
          backgroundColor: theme.colorScheme.surface,
          side: BorderSide(
            color: isSelected ? AppColors.primary : theme.dividerColor,
          ),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }).toList(),
    );
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
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
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
              ),
            ),
            Icon(Iconsax.arrow_down_1,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      prefixText: prefix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
