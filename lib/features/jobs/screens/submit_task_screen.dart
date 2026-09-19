import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../services/r2_storage_service.dart';
import '../../../services/supabase_service.dart';
import '../providers/jobs_provider.dart';

/// The four submission types supported.
enum _SubmissionType { link, photo, pdf, video }

class SubmitTaskScreen extends ConsumerStatefulWidget {
  final String applicationId;
  final String jobTitle;

  const SubmitTaskScreen({
    super.key,
    required this.applicationId,
    required this.jobTitle,
  });

  @override
  ConsumerState<SubmitTaskScreen> createState() => _SubmitTaskScreenState();
}

class _SubmitTaskScreenState extends ConsumerState<SubmitTaskScreen> {
  _SubmissionType _type = _SubmissionType.link;
  final _linkController = TextEditingController();
  final _notesController = TextEditingController();

  File? _pickedFile;
  String? _uploadedUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _linkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String get _typeKey {
    switch (_type) {
      case _SubmissionType.link:
        return 'link';
      case _SubmissionType.photo:
        return 'photo';
      case _SubmissionType.pdf:
        return 'pdf';
      case _SubmissionType.video:
        return 'video';
    }
  }

  String get _submissionUrl {
    if (_type == _SubmissionType.link) return _linkController.text.trim();
    return _uploadedUrl ?? '';
  }

  bool get _canSubmit {
    if (_isUploading || _isSubmitting) return false;
    if (_type == _SubmissionType.link) {
      return _linkController.text.trim().isNotEmpty;
    }
    return _uploadedUrl != null && _uploadedUrl!.isNotEmpty;
  }

  // ─── File picking ───────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    XFile? picked;

    if (_type == _SubmissionType.photo) {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } else if (_type == _SubmissionType.video) {
      picked = await picker.pickVideo(source: ImageSource.gallery);
    } else if (_type == _SubmissionType.pdf) {
      // image_picker doesn't support PDF — show instructions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Upload your PDF to a cloud service and paste the link instead.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      setState(() => _type = _SubmissionType.link);
      return;
    }

    if (picked == null) return;

    setState(() {
      _pickedFile = File(picked!.path);
      _uploadedUrl = null;
    });

    await _uploadFile();
  }

  Future<void> _uploadFile() async {
    if (_pickedFile == null) return;

    final user = SupabaseService.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final ext = _pickedFile!.path.split('.').last.toLowerCase();
      final fileName = '${const Uuid().v4()}.$ext';
      final folder =
          'job-submissions/${user.id}';
      final bytes = await _pickedFile!.readAsBytes();
      final contentType = _getContentType(ext);

      final url = await R2StorageService.uploadFile(
        '$folder/$fileName',
        bytes,
        contentType,
      );

      setState(() {
        _uploadedUrl = url;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  // ─── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    final ok = await ref.read(jobsActionsProvider.notifier).submitTask(
          applicationId: widget.applicationId,
          submissionType: _typeKey,
          submissionUrl: _submissionUrl,
          submissionNote: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task submitted! It\'s now under review.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final errState = ref.read(jobsActionsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errState.hasError
              ? ErrorUtils.sanitize(errState.error)
              : 'Submission failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Submit Task'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job title context
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: AppRadius.allMd,
                border: Border.all(color: AppColors.primary.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.briefcase,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.jobTitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Submission type segmented control
            Text(
              'Submission Type',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SubmissionTypeSelector(
              selected: _type,
              isDark: isDark,
              onChanged: (t) => setState(() {
                _type = t;
                _uploadedUrl = null;
                _pickedFile = null;
                _linkController.clear();
              }),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Input section based on type
            Text(
              _type == _SubmissionType.link
                  ? 'Paste Your Link'
                  : 'Upload Your File',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (_type == _SubmissionType.link)
              PremiumTextField(
                controller: _linkController,
                hint: 'https://...',
                prefixIcon: Iconsax.link,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              )
            else
              _FileUploadArea(
                pickedFile: _pickedFile,
                uploadedUrl: _uploadedUrl,
                isUploading: _isUploading,
                type: _type,
                isDark: isDark,
                onTap: _pickFile,
              ),

            const SizedBox(height: AppSpacing.xl),

            // Notes (optional)
            Text(
              'Notes (Optional)',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            PremiumTextField.multiline(
              controller: _notesController,
              hint: 'Add any context or notes for the reviewer…',
              minLines: 3,
              maxLines: 6,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Pending review info box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                borderRadius: AppRadius.allMd,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.info_circle,
                      size: 16,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'After submitting, your task will be marked as '
                      '"Pending Review". You\'ll receive a notification once the admin '
                      'approves or rejects your submission.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Submit button
            PremiumButton(
              label: 'Submit Task',
              icon: Iconsax.send_1,
              loading: _isSubmitting,
              onPressed: _canSubmit ? _submit : null,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ─── Submission Type Selector ─────────────────────────────────────────────────

class _SubmissionTypeSelector extends StatelessWidget {
  final _SubmissionType selected;
  final bool isDark;
  final ValueChanged<_SubmissionType> onChanged;

  const _SubmissionTypeSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  static const _types = [
    (_SubmissionType.link, Iconsax.link, 'Link'),
    (_SubmissionType.photo, Iconsax.gallery, 'Photo'),
    (_SubmissionType.pdf, Iconsax.document, 'PDF'),
    (_SubmissionType.video, Iconsax.video, 'Video'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        borderRadius: AppRadius.allMd,
      ),
      child: Row(
        children: _types.map((t) {
          final isSelected = t.$1 == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  borderRadius: AppRadius.allSm,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.$2,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.$3,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── File Upload Area ─────────────────────────────────────────────────────────

class _FileUploadArea extends StatelessWidget {
  final File? pickedFile;
  final String? uploadedUrl;
  final bool isUploading;
  final _SubmissionType type;
  final bool isDark;
  final VoidCallback onTap;

  const _FileUploadArea({
    required this.pickedFile,
    required this.uploadedUrl,
    required this.isUploading,
    required this.type,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final hint = isDark ? AppColors.darkTextHint : AppColors.textHint;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.allMd,
          border: Border.all(
            color: uploadedUrl != null
                ? AppColors.success
                : (isUploading ? AppColors.primary : border),
            width: uploadedUrl != null ? 1.5 : 1,
          ),
        ),
        child: _buildContent(hint),
      ),
    );
  }

  Widget _buildContent(Color hint) {
    if (isUploading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.primary),
          ),
          SizedBox(height: 12),
          Text(
            'Uploading…',
            style: TextStyle(
                fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 20),
        ],
      );
    }

    if (uploadedUrl != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.tick_circle,
                size: 36, color: AppColors.success),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'File uploaded successfully',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to replace',
              style: TextStyle(fontSize: 11, color: hint),
            ),
          ],
        ),
      );
    }

    if (pickedFile != null && type == _SubmissionType.photo) {
      return ClipRRect(
        borderRadius: AppRadius.allMd,
        child: Image.file(pickedFile!, fit: BoxFit.cover),
      );
    }

    final (icon, label) = _iconAndLabel();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: hint),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: hint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to select from gallery',
            style: TextStyle(fontSize: 11, color: hint),
          ),
        ],
      ),
    );
  }

  (IconData, String) _iconAndLabel() {
    switch (type) {
      case _SubmissionType.photo:
        return (Iconsax.gallery, 'Select a photo');
      case _SubmissionType.pdf:
        return (Iconsax.document, 'Select a PDF');
      case _SubmissionType.video:
        return (Iconsax.video, 'Select a video');
      default:
        return (Iconsax.document_upload, 'Select a file');
    }
  }
}
