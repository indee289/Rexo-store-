import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/image_upload_field.dart';
import '../../../services/supabase_service.dart';
import '../providers/campaigns_provider.dart';

/// Create campaign — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over one undifferentiated run of ten
/// label-plus-field pairs, where four of the ten were Material
/// `DropdownButton`s inside hand-decorated `Container`s and the submit button
/// sat at the very bottom of the scroll, past roughly two screens of form.
///
/// New layout: a collapsing large title; the form split into named groups
/// (basics, classification, slots and budget, timing, brand, rules) so the
/// page reads as six short steps instead of one long column; the four
/// dropdowns replaced by grouped picker rows that show the current value as
/// detail text and open a sheet of options; the two money fields paired
/// side by side because they are read against each other; and the submit
/// action pinned to the bottom so it is reachable at any scroll offset.
///
/// The insert payload, `campaignsListProvider` invalidation, every validator
/// and the option lists are unchanged.
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
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
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
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Store platform lowercase for DB CHECK constraint compatibility
      final platformForDb = _selectedPlatform.toLowerCase();

      await SupabaseService.client.from('campaigns').insert({
        // Write BOTH owner columns: the live table has historically used
        // `brandId` (camelCase) OR `brand_id` (snake_case). Populating both
        // satisfies whichever one exists / is NOT NULL and matches the RLS
        // INSERT policy regardless of which column it checks.
        'brandId': user.id,
        'brand_id': user.id,
        'title': _campaignNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'platform': platformForDb,
        'slots': int.tryParse(_slotsController.text.trim()) ?? 1,
        'filled_slots': 0,
        'budget': double.tryParse(_budgetController.text.trim()) ?? 0,
        'payout_per_creator':
            double.tryParse(_perCreatorController.text.trim()) ?? 0,
        'deadline': _deadline?.toIso8601String(),
        'company_name': _companyNameController.text.trim(),
        'cover_image': _coverImageUrl,
        'gender': _selectedGender,
        'page_profile_category': _selectedPageProfileCategory,
        'rules': _rulesController.text.trim().isEmpty
            ? null
            : _rulesController.text.trim(),
        'status': 'active',
        // created_at / updated_at are intentionally NOT sent: the live
        // `campaigns` table has no `updated_at` column (sending it caused a
        // PGRST204 "column not found" -> "something went wrong"). Both
        // timestamps have DEFAULT now() in the DB, so they populate themselves.
      });

      if (!mounted) return;

      // Invalidate campaigns list to refresh
      ref.invalidate(campaignsListProvider);

      showGlassSnackBar(
        context,
        message: 'Campaign created successfully!',
        tone: GlassToastTone.success,
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: ErrorUtils.sanitize(e),
        tone: GlassToastTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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

  /// Opens a sheet of [options] and reports the chosen one.
  ///
  /// Replaces the Material `DropdownButton` menus. The stored values are the
  /// raw option strings exactly as before; only the presentation differs.
  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final picked = await showGlassSheet<String>(
      context: context,
      title: title,
      // A Builder so the rows pop the *sheet* route rather than this screen.
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
                  title: 'Create campaign',
                  subtitle: 'Brief creators and open your slots',
                  showBack: true,
                  onBack: () => context.pop(),
                ),

                // 1 — Basics: what the campaign is and what it asks for.
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
                          prefixIcon: AppIcons.document_text,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a campaign name';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapLg,
                        GlassTextField.multiline(
                          controller: _descriptionController,
                          label: 'Description',
                          hint:
                              'Describe your campaign — what creators need to know',
                          minLines: 3,
                          maxLines: 6,
                        ),
                      ],
                    ),
                  ),
                ),

                // 2 — Classification: the four former dropdowns, as rows that
                // show their current value and open a picker sheet.
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
                      title: 'Platform',
                      icon: AppIcons.global,
                      trailingText: _optionLabel(_selectedPlatform),
                      onTap: () => _pickOption(
                        title: 'Platform',
                        options: _platforms,
                        current: _selectedPlatform,
                        onSelected: (value) =>
                            setState(() => _selectedPlatform = value),
                      ),
                    ),
                    GlassRow(
                      title: 'Page profile category',
                      icon: AppIcons.tag,
                      trailingText: _optionLabel(_selectedPageProfileCategory),
                      onTap: () => _pickOption(
                        title: 'Page profile category',
                        options: _pageProfileCategories,
                        current: _selectedPageProfileCategory,
                        onSelected: (value) => setState(
                          () => _selectedPageProfileCategory = value,
                        ),
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
                    ],
                  ),
                ),

                // 3 — Slots and budget. The two money fields are paired
                // because each is read against the other.
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
                          hint: 'Number of slots (e.g. 10)',
                          prefixIcon: AppIcons.people,
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
                        AppSpacing.gapLg,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GlassTextField(
                                controller: _budgetController,
                                label: 'Total budget (\u20B9)',
                                hint: 'Total',
                                prefixIcon: AppIcons.money,
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
                            ),
                            AppSpacing.gapMd,
                            Expanded(
                              child: GlassTextField(
                                controller: _perCreatorController,
                                label: 'Per creator (\u20B9)',
                                hint: 'Payout',
                                prefixIcon: AppIcons.money_recive,
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 4 — Timing. The deadline is validated in _handleSubmit, not
                // by the form, so it is surfaced as a row with its own state.
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

                // 5 — Brand presentation.
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
                              return 'Please enter company name';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapLg,
                        ImageUploadField(
                          label: 'Campaign cover image',
                          storageFolder: 'campaign-assets',
                          onImageUploaded: (url) {
                            _coverImageUrl = url;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 6 — Optional rules, last because it is optional.
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
                        _sectionLabel('Rules'),
                        GlassTextField.multiline(
                          controller: _rulesController,
                          label: 'Rules (optional)',
                          hint: 'Any specific rules or guidelines for creators',
                          minLines: 2,
                          maxLines: 4,
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
              label: 'Create campaign',
              icon: AppIcons.add_circle,
              size: GlassButtonSize.large,
              loading: _isSubmitting,
              onPressed: _isSubmitting ? null : _handleSubmit,
            ),
          ),
        ],
      ),
    );
  }

  /// Group heading for the field blocks that sit outside a glass pane, matching
  /// the tracked-caps header [GlassSection] prints for its own groups.
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
