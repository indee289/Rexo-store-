import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/image_upload_field.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../jobs/providers/jobs_provider.dart';

/// Admin screen for creating a new job, or editing an existing one.
/// Pass [existingJob] to pre-populate for editing.
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

  DateTime? _deadline;
  String? _coverImageUrl;
  bool _saving = false;

  bool get _isEdit => widget.existingJob != null;

  @override
  void initState() {
    super.initState();
    final j = widget.existingJob;
    if (j != null) {
      _titleCtrl.text = j['title'] as String? ?? '';
      _descCtrl.text = j['description'] as String? ?? '';
      _categoryCtrl.text = j['category'] as String? ?? '';
      _paymentCtrl.text =
          (j['payment_amount'] as num?)?.toString() ?? '';
      _maxSlotsCtrl.text =
          (j['max_slots'] as int?)?.toString() ?? '';
      _coverImageUrl = j['cover_image_url'] as String?;
      final dl = j['deadline'] as String?;
      if (dl != null) _deadline = DateTime.tryParse(dl);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _paymentCtrl.dispose();
    _maxSlotsCtrl.dispose();
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
      _showError('Max slots must be a positive whole number, or leave blank for unlimited.');
      return;
    }

    setState(() => _saving = true);

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
    };

    bool ok;
    if (_isEdit) {
      ok = await ref
          .read(jobsActionsProvider.notifier)
          .updateJob(widget.existingJob!['id'] as String, data);
    } else {
      ok = await ref
          .read(jobsActionsProvider.notifier)
          .createJob(data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Job updated.' : 'Job posted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      final err = ref.read(jobsActionsProvider);
      _showError(err.hasError
          ? ErrorUtils.sanitize(err.error)
          : 'Could not save the job. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: _isEdit ? 'Edit Job' : 'Post a Job'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover Image ──────────────────────────────────────────────
              _SectionLabel(label: 'Cover Image (Optional)', isDark: isDark),
              const SizedBox(height: AppSpacing.sm),
              ImageUploadField(
                currentImageUrl: _coverImageUrl,
                storageFolder: 'job-covers',
                label: 'Upload Cover Image',
                onImageUploaded: (url) => setState(() => _coverImageUrl = url),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Title ────────────────────────────────────────────────────
              _SectionLabel(label: 'Job Title *', isDark: isDark),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _titleCtrl,
                hint: 'e.g. Write a product review on Instagram',
                prefixIcon: Iconsax.briefcase,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Description / Instructions ───────────────────────────────
              _SectionLabel(label: 'Description & Instructions *', isDark: isDark),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField.multiline(
                controller: _descCtrl,
                hint: 'Describe the task, what to do, and what proof to submit…',
                minLines: 4,
                maxLines: 10,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Category ─────────────────────────────────────────────────
              _SectionLabel(label: 'Category (Optional)', isDark: isDark),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Used to generate filter chips on the Jobs page.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _categoryCtrl,
                hint: 'e.g. Social Media, Content, Photography',
                prefixIcon: Iconsax.category,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Payment Amount ────────────────────────────────────────────
              _SectionLabel(label: 'Payment Amount (₹) *', isDark: isDark),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _paymentCtrl,
                hint: '0.00',
                prefixIcon: Iconsax.money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Payment amount is required'
                    : null,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Max Slots ─────────────────────────────────────────────────
              _SectionLabel(label: 'Max Slots (Optional)', isDark: isDark),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Leave blank for unlimited applications.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _maxSlotsCtrl,
                hint: 'e.g. 10',
                prefixIcon: Iconsax.people,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Deadline ──────────────────────────────────────────────────
              _SectionLabel(label: 'Deadline (Optional)', isDark: isDark),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceAlt
                        : AppColors.surfaceAlt,
                    borderRadius: AppRadius.allMd,
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.calendar,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.textHint),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _deadline == null
                            ? 'Select a deadline date'
                            : '${_deadline!.day} ${_monthName(_deadline!.month)} ${_deadline!.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _deadline == null
                              ? (isDark
                                  ? AppColors.darkTextHint
                                  : AppColors.textHint)
                              : textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_deadline != null)
                        GestureDetector(
                          onTap: () => setState(() => _deadline = null),
                          child: Icon(Iconsax.close_circle,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextHint
                                  : AppColors.textHint),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Save Button ───────────────────────────────────────────────
              PremiumButton(
                label: _isEdit ? 'Save Changes' : 'Post Job',
                icon: _isEdit ? Iconsax.save_2 : Iconsax.send_1,
                loading: _saving,
                onPressed: _save,
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
    );
  }
}
