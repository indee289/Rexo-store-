import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/demo_asset_field.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/image_upload_field.dart';
import '../../jobs/providers/jobs_provider.dart';

/// Admin screen for creating a new job, or editing an existing one.
/// Pass [existingJob] to pre-populate for editing.
///
/// Rebuilt layout. Old layout: a `PremiumAppBar` over one undifferentiated run
/// of nine field blocks, each preceded by a local `_SectionLabel` printing a
/// bold `Text` (with asterisks for required fields), the platform picker built
/// from Material `ChoiceChip`s, the deadline a hand-decorated `Container` with
/// its own clear affordance, and the save button at the very bottom of a very
/// long scroll.
///
/// New layout: a collapsing large title; the form split into five named groups
/// (basics, classification, payment, timing, extras) so it reads as five short
/// steps; required/optional conveyed by the shared field's helper text instead
/// of asterisks; the platform picker on `GlassChip`; the deadline as a grouped
/// row that shows its value as detail text; and save pinned so it is reachable
/// at any scroll offset. The `isDark` colour variables are gone — the app is
/// light mode only.
///
/// The insert/update payload, every validation rule, the comma-joined
/// `platform` convention, the demo-asset key mapping and the `pop(true)`
/// result are unchanged.
class PostJobScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingJob;

  const PostJobScreen({super.key, this.existingJob});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();
  final _maxSlotsCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();

  DateTime? _deadline;
  String? _coverImageUrl;
  List<String> _selectedPlatforms = ['Instagram'];
  DemoAssetType _demoAssetType = DemoAssetType.none;
  String? _demoAssetValue;
  bool _saving = false;

  bool get _isEdit => widget.existingJob != null;

  // Match the platform list values used on the campaign create form.
  static const List<String> _platforms = [
    'Instagram',
    'Facebook',
    'YouTube',
  ];

  @override
  void initState() {
    super.initState();
    final j = widget.existingJob;
    if (j != null) {
      // The job map is a SELECT * campaigns row passed through
      // _mapCampaignToJob, so raw columns (rules/platform/demo_asset_*) are
      // present on the map by key.
      _titleCtrl.text = j['title'] as String? ?? '';
      _descCtrl.text = j['description'] as String? ?? '';
      _categoryCtrl.text = j['category'] as String? ?? '';
      _paymentCtrl.text = (j['payment_amount'] as num?)?.toString() ?? '';
      _maxSlotsCtrl.text = (j['max_slots'] as int?)?.toString() ?? '';
      _coverImageUrl = j['cover_image_url'] as String?;
      _rulesCtrl.text = j['rules'] as String? ?? '';
      final dl = j['deadline'] as String?;
      if (dl != null) _deadline = DateTime.tryParse(dl);

      // Split the stored comma-separated platform string back into chips,
      // keeping only values we know about.
      final platformRaw = j['platform'] as String?;
      if (platformRaw != null && platformRaw.trim().isNotEmpty) {
        final parsed = platformRaw
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

      _demoAssetType = demoAssetTypeFromKey(j['demo_asset_type'] as String?);
      _demoAssetValue = j['demo_asset_url'] as String?;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _paymentCtrl.dispose();
    _maxSlotsCtrl.dispose();
    _rulesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final paymentRaw = double.tryParse(_paymentCtrl.text.trim());
    if (paymentRaw == null || paymentRaw <= 0) {
      _showError('Enter a valid payment amount greater than 0.');
      return;
    }

    final maxSlotsRaw = _maxSlotsCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(_maxSlotsCtrl.text.trim());
    if (_maxSlotsCtrl.text.trim().isNotEmpty &&
        (maxSlotsRaw == null || maxSlotsRaw <= 0)) {
      _showError(
          'Max slots must be a positive whole number, or leave blank for unlimited.');
      return;
    }

    setState(() => _saving = true);

    final rules = _rulesCtrl.text.trim();
    final demoValue = _demoAssetValue?.trim();
    final hasDemoAsset = _demoAssetType != DemoAssetType.none &&
        demoValue != null &&
        demoValue.isNotEmpty;

    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': _categoryCtrl.text.trim().isEmpty
          ? null
          : _categoryCtrl.text.trim(),
      'payment_amount': paymentRaw,
      'max_slots': maxSlotsRaw,
      'deadline': _deadline?.toUtc().toIso8601String(),
      'cover_image_url':
          (_coverImageUrl?.isNotEmpty ?? false) ? _coverImageUrl : null,
      // Multi-select platforms persisted as a comma-joined string (matches the
      // campaign create form convention). Always at least one platform.
      'platform': _selectedPlatforms.join(','),
      // Optional rules (null when empty so the column stays clear).
      'rules': rules.isEmpty ? null : rules,
      // Optional demo asset (null when nothing was attached).
      'demo_asset_type':
          hasDemoAsset ? demoAssetTypeToKey(_demoAssetType) : null,
      'demo_asset_url': hasDemoAsset ? demoValue : null,
    };

    bool ok;
    if (_isEdit) {
      ok = await ref
          .read(jobsActionsProvider.notifier)
          .updateJob(widget.existingJob!['id'] as String, data);
    } else {
      ok = await ref.read(jobsActionsProvider.notifier).createJob(data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      showGlassSnackBar(
        context,
        message: _isEdit ? 'Job updated.' : 'Job posted successfully!',
        tone: GlassToastTone.success,
      );
      Navigator.of(context).pop(true);
    } else {
      final err = ref.read(jobsActionsProvider);
      final sanitized = err.hasError
          ? ErrorUtils.sanitize(err.error)
          : 'Could not save the job. Please try again.';
      _showError(sanitized);
    }
  }

  void _showError(String msg) {
    showGlassSnackBar(context, message: msg, tone: GlassToastTone.error);
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
                  title: _isEdit ? 'Edit job' : 'Post a job',
                  subtitle: _isEdit
                      ? 'Update this listing'
                      : 'Describe the task and the payout',
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
                        _sectionLabel('Basics'),
                        ImageUploadField(
                          currentImageUrl: _coverImageUrl,
                          storageFolder: 'job-covers',
                          label: 'Cover image (optional)',
                          onImageUploaded: (url) =>
                              setState(() => _coverImageUrl = url),
                        ),
                        AppSpacing.gapLg,
                        GlassTextField(
                          controller: _titleCtrl,
                          label: 'Job title',
                          hint: 'e.g. Write a product review on Instagram',
                          prefixIcon: AppIcons.briefcase,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Title is required'
                              : null,
                        ),
                        AppSpacing.gapLg,
                        GlassTextField.multiline(
                          controller: _descCtrl,
                          label: 'Description & instructions',
                          hint:
                              'Describe the task, what to do, and what proof to submit…',
                          minLines: 4,
                          maxLines: 10,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Description is required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),

                // 2 — Classification
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
                        _sectionLabel('Classification'),
                        GlassTextField(
                          controller: _categoryCtrl,
                          label: 'Category (optional)',
                          hint: 'e.g. Social Media, Content, Photography',
                          helperText:
                              'Used to generate filter chips on the Jobs page',
                          prefixIcon: AppIcons.category,
                          textCapitalization: TextCapitalization.words,
                        ),
                        AppSpacing.gapLg,
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            bottom: AppSpacing.sm,
                          ),
                          child: Text(
                            'Platforms',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final platform in _platforms)
                              GlassChip(
                                label: platform,
                                selected: _selectedPlatforms.contains(platform),
                                onTap: () => _togglePlatform(platform),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3 — Payment & slots
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
                        _sectionLabel('Payment & slots'),
                        GlassTextField(
                          controller: _paymentCtrl,
                          label: 'Payment amount (\u20B9)',
                          hint: '0.00',
                          prefixIcon: AppIcons.money,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Payment amount is required'
                              : null,
                        ),
                        AppSpacing.gapLg,
                        GlassTextField(
                          controller: _maxSlotsCtrl,
                          label: 'Max slots (optional)',
                          hint: 'e.g. 10',
                          helperText: 'Leave blank for unlimited applications',
                          prefixIcon: AppIcons.people,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
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
                        icon: AppIcons.calendar,
                        title: 'Deadline',
                        subtitle: 'Optional',
                        trailingText: _deadline == null
                            ? 'Not set'
                            : '${_deadline!.day} '
                                '${_monthName(_deadline!.month)} '
                                '${_deadline!.year}',
                        trailing: _deadline == null
                            ? null
                            : GlassIconButton.bare(
                                icon: AppIcons.close_circle,
                                tooltip: 'Clear deadline',
                                size: 30,
                                iconSize: 18,
                                onTap: () => setState(() => _deadline = null),
                              ),
                        onTap: _pickDeadline,
                      ),
                    ],
                  ),
                ),

                // 5 — Extras
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
                          controller: _rulesCtrl,
                          label: 'Rules (optional)',
                          hint:
                              'Add any rules or guidelines creators must follow…',
                          minLines: 3,
                          maxLines: 8,
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
                          storageFolder: 'job-demo-assets',
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
              label: _isEdit ? 'Save changes' : 'Post job',
              icon: _isEdit ? AppIcons.save_2 : AppIcons.send_1,
              size: GlassButtonSize.large,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }

  /// Toggles a platform, keeping at least one selected — unchanged rule.
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

  String _monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month];
  }
}
