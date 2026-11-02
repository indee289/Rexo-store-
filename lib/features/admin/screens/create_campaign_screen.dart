import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/demo_asset_field.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/image_upload_field.dart';
import '../../../services/supabase_service.dart';
import '../providers/admin_provider.dart';

/// Admin create/edit campaign — rebuilt layout.
///
/// Old layout: a raw Material `AppBar` over one undifferentiated run of
/// thirteen field blocks, each preceded by a local `_buildLabel` printing a
/// bold `Text`, every input built on `TextFormField` + a local
/// `_inputDecoration` helper, three Material `DropdownButtonFormField`s, a
/// hand-decorated deadline `Container`, and an `ElevatedButton` with its own
/// hand-rolled spinner at the very bottom of a long scroll.
///
/// New layout: a collapsing large title; the form split into six named groups
/// (basics, classification, slots & budget, timing, brand, extras); the three
/// dropdowns replaced by grouped picker rows that show the current value as
/// detail text and open an option sheet; platforms on `GlassChip`; the two
/// money fields paired side by side; and submit pinned so it is reachable at
/// any scroll offset. This now matches the storefront create-campaign screen.
///
/// The payload is unchanged, including the edit-only clearing of `rules`,
/// `demo_asset_type` and `demo_asset_url`, the dual `brandId`/`brand_id` write
/// on insert, the `status: 'active'` default, every validator and the
/// `pop(context, true)` result.
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
      _slotsController.text = (e['slots'] ?? '').toString();
      _budgetController.text = (e['budget'] ?? '').toString();
      _perCreatorController.text = (e['payout_per_creator'] ?? '').toString();
      _companyNameController.text = e['company_name'] as String? ?? '';
      _descriptionController.text = e['description'] as String? ?? '';
      _rulesController.text = e['rules'] as String? ?? '';
      _coverImageUrl = e['cover_image'] as String?;
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
      showGlassSnackBar(
        context,
        message: 'Please select a campaign deadline',
        tone: GlassToastTone.error,
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
        'slots': int.parse(_slotsController.text.trim()),
        'budget': double.parse(_budgetController.text.trim()),
        'payout_per_creator':
            double.tryParse(_perCreatorController.text.trim()) ?? 0,
        'deadline': _deadline?.toIso8601String(),
        'company_name': _companyNameController.text.trim(),
        'gender': _selectedGender,
        'page_profile_category': _selectedPageProfileCategory,
      };

      if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) {
        data['cover_image'] = _coverImageUrl;
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
        // Write BOTH owner columns so every reader matches regardless of
        // casing: `brandId` (camelCase — used by campaign detail + profile
        // count + jobs flow) and `brand_id` (snake_case legacy).
        final uid = SupabaseService.currentUser?.id;
        data['brandId'] = uid;
        data['brand_id'] = uid;
        data['status'] = 'active';
        await SupabaseService.client.from('campaigns').insert(data);
      }

      ref.invalidate(adminCampaignsProvider);

      if (mounted) {
        showGlassSnackBar(
          context,
          message: _isEdit
              ? 'Campaign updated!'
              : 'Campaign created successfully!',
          tone: GlassToastTone.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: ErrorUtils.sanitize(e),
          tone: GlassToastTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  /// Opens a sheet of [options] and reports the chosen one. Replaces the three
  /// Material `DropdownButtonFormField`s; the stored values are untouched.
  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final picked = await showGlassSheet<String>(
      context: context,
      title: title,
      child: Builder(
        builder: (sheetContext) => SingleChildScrollView(
          child: GlassGroup(
            children: [
              for (final option in options)
                GlassRow(
                  title: _optionLabel(option),
                  showChevron: false,
                  trailing: option == current
                      ? const Icon(
                          AppIcons.tick_circle,
                          size: 20,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onSelected(picked);
  }

  /// Display form of an option value. Only the label is prettied — the value
  /// written to the database is untouched.
  String _optionLabel(String raw) {
    if (raw.isEmpty) return raw;
    if (raw == 'all') return 'All';
    if (raw == raw.toLowerCase()) {
      return raw[0].toUpperCase() + raw.substring(1);
    }
    return raw;
  }

  void _togglePlatform(String platform) {
    setState(() {
      if (_selectedPlatforms.contains(platform)) {
        if (_selectedPlatforms.length > 1) {
          _selectedPlatforms.remove(platform);
        }
      } else {
        _selectedPlatforms.add(platform);
      }
    });
  }

  String get _deadlineLabel {
    final d = _deadline;
    if (d == null) return 'Not set';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                GlassLargeTitleHeader(
                  title: _isEdit ? 'Edit campaign' : 'Create campaign',
                  subtitle: _isEdit
                      ? 'Update this campaign'
                      : 'Brief creators and open your slots',
                  showBack: true,
                ),

                // 1 — Basics
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('Campaign basics'),
                        GlassTextField(
                          controller: _campaignNameController,
                          label: 'Campaign name',
                          hint: 'Enter campaign name',
                          prefixIcon: AppIcons.edit,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campaign name is required';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapLg,
                        GlassTextField.multiline(
                          controller: _descriptionController,
                          label: 'Campaign description',
                          hint:
                              'Describe the campaign, what creators should do…',
                          minLines: 3,
                          maxLines: 6,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campaign description is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 2 — Classification: the three former dropdowns as rows.
                SliverToBoxAdapter(
                  child: GlassSection(
                    title: 'Classification',
                    children: [
                      GlassRow(
                        title: 'Category',
                        icon: AppIcons.category,
                        trailingText: _optionLabel(_selectedCategory),
                        onTap: () => _pickOption(
                          title: 'Category',
                          options: _categories,
                          current: _selectedCategory,
                          onSelected: (value) =>
                              setState(() => _selectedCategory = value),
                        ),
                      ),
                      GlassRow(
                        title: 'Audience gender',
                        icon: AppIcons.user,
                        trailingText: _optionLabel(_selectedGender),
                        onTap: () => _pickOption(
                          title: 'Audience gender',
                          options: _genders,
                          current: _selectedGender,
                          onSelected: (value) =>
                              setState(() => _selectedGender = value),
                        ),
                      ),
                      GlassRow(
                        title: 'Page profile category',
                        icon: AppIcons.tag,
                        trailingText:
                            _optionLabel(_selectedPageProfileCategory),
                        onTap: () => _pickOption(
                          title: 'Page profile category',
                          options: _pageProfileCategories,
                          current: _selectedPageProfileCategory,
                          onSelected: (value) => setState(
                            () => _selectedPageProfileCategory = value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Platforms
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('Platforms'),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final platform in _platforms)
                              GlassChip(
                                label: platform,
                                selected:
                                    _selectedPlatforms.contains(platform),
                                onTap: () => _togglePlatform(platform),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3 — Slots & budget
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('Slots & budget'),
                        GlassTextField(
                          controller: _slotsController,
                          label: 'Slots',
                          hint: 'Number of slots',
                          prefixIcon: AppIcons.people,
                          keyboardType: TextInputType.number,
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
                        AppSpacing.gapLg,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GlassTextField(
                                controller: _budgetController,
                                label: 'Budget',
                                hint: 'Total',
                                prefixText: '\u20B9 ',
                                keyboardType: TextInputType.number,
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
                            ),
                            AppSpacing.gapMd,
                            Expanded(
                              child: GlassTextField(
                                controller: _perCreatorController,
                                label: 'Per creator',
                                hint: 'Payout',
                                prefixText: '\u20B9 ',
                                keyboardType: TextInputType.number,
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 4 — Timing
                SliverToBoxAdapter(
                  child: GlassSection(
                    title: 'Timing',
                    children: [
                      GlassRow(
                        title: 'Deadline',
                        subtitle: _deadline == null
                            ? 'Required before you can publish'
                            : null,
                        icon: AppIcons.calendar_1,
                        iconColor:
                            _deadline == null ? AppColors.warning : null,
                        trailingText: _deadlineLabel,
                        onTap: _pickDeadline,
                      ),
                    ],
                  ),
                ),

                // 5 — Brand
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('Brand'),
                        GlassTextField(
                          controller: _companyNameController,
                          label: 'Company name',
                          hint: 'Enter company name',
                          prefixIcon: AppIcons.building,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Company name is required';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapLg,
                        ImageUploadField(
                          label: 'Campaign cover image',
                          storageFolder: 'campaign-images',
                          currentImageUrl: _coverImageUrl,
                          onImageUploaded: (url) {
                            setState(() => _coverImageUrl = url);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 6 — Extras
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('Extras'),
                        GlassTextField.multiline(
                          controller: _rulesController,
                          label: 'Campaign rules (optional)',
                          hint: 'Add any rules or guidelines for creators…',
                          minLines: 3,
                          maxLines: 6,
                        ),
                        AppSpacing.gapLg,
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            bottom: AppSpacing.sm,
                          ),
                          child: Text(
                            'Demo asset (optional)',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
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
                      ],
                    ),
                  ),
                ),

                // Clearance for the pinned action.
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: GlassButton(
              label: _isEdit ? 'Save changes' : 'Create campaign',
              icon: _isEdit ? AppIcons.save_2 : AppIcons.add_circle,
              size: GlassButtonSize.large,
              loading: _isSubmitting,
              onPressed: _isSubmitting ? null : _handleSubmit,
            ),
          ),
        ],
      ),
    );
  }

  /// Group heading matching the tracked-caps header used by `GlassSection`.
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.caption1.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
