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
import '../../../core/widgets/glass/glass.dart';
import '../../../services/r2_storage_service.dart';
import '../../../services/supabase_service.dart';
import '../providers/jobs_provider.dart';

/// The four submission types supported.
enum _SubmissionType { link, photo, pdf, video }

/// Submit task — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over a single scroll column in which each
/// section was preceded by a bare bold `Text`, the type picker was a
/// hand-built four-segment control with its own gradient and shadow logic,
/// the drop zone was a `Container` with hand-managed border colours, and the
/// submit button sat at the bottom of the scroll. Every one of those carried
/// its own `isDark` branch.
///
/// New layout: a collapsing large title; the job being submitted against
/// shown as a brand card so the context survives; the type picker replaced by
/// the shared segmented control; the drop zone rebuilt as a card whose rim
/// carries the upload state; the review notice demoted to a quiet subtle
/// card; and submit pinned so it is reachable while the notes field is open.
/// The `isDark` branches are gone — the app is light mode only.
///
/// `jobsActionsProvider.submitTask`, `R2StorageService.uploadFile`, the
/// content-type table, the image-picker options, the PDF fallback behaviour
/// and the `_canSubmit` rule are all unchanged.
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
        showGlassSnackBar(
          context,
          message:
              'Upload your PDF to a cloud service and paste the link instead.',
          tone: GlassToastTone.warning,
          duration: const Duration(seconds: 4),
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
      final folder = 'job-submissions/${user.id}';
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
        showGlassSnackBar(
          context,
          message: ErrorUtils.sanitize(e),
          tone: GlassToastTone.error,
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
      showGlassSnackBar(
        context,
        message: "Task submitted! It's now under review.",
        tone: GlassToastTone.success,
      );
      Navigator.of(context).pop();
    } else {
      final errState = ref.read(jobsActionsProvider);
      showGlassSnackBar(
        context,
        message: errState.hasError
            ? ErrorUtils.sanitize(errState.error)
            : 'Submission failed. Please try again.',
        tone: GlassToastTone.error,
      );
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const GlassLargeTitleHeader(
                title: 'Submit task',
                subtitle: 'Share your proof of work for review',
                showBack: true,
              ),

              // What this submission is against.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: GlassCard.brand(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const GlassIconBubble(
                          icon: AppIcons.briefcase,
                          size: 36,
                          iconSize: 18,
                        ),
                        AppSpacing.gapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Submitting for',
                                style: AppTextStyles.caption1.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.jobTitle,
                                style: AppTextStyles.headline.copyWith(
                                  color: AppColors.primary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Type picker — the shared segmented control.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionLabel('Submission type'),
                      GlassTabBar(
                        labels: const ['Link', 'Photo', 'PDF', 'Video'],
                        selectedIndex: _type.index,
                        onSelected: (i) => setState(() {
                          _type = _SubmissionType.values[i];
                          _uploadedUrl = null;
                          _pickedFile = null;
                          _linkController.clear();
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // The input itself, which depends on the type.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: _type == _SubmissionType.link
                      ? GlassTextField(
                          controller: _linkController,
                          label: 'Paste your link',
                          hint: 'https://…',
                          prefixIcon: AppIcons.link,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                        )
                      : _FileUploadArea(
                          pickedFile: _pickedFile,
                          uploadedUrl: _uploadedUrl,
                          isUploading: _isUploading,
                          type: _type,
                          onTap: _pickFile,
                        ),
                ),
              ),

              // Optional notes for the reviewer.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: GlassTextField.multiline(
                    controller: _notesController,
                    label: 'Notes (optional)',
                    hint: 'Add any context or notes for the reviewer…',
                    minLines: 3,
                    maxLines: 6,
                  ),
                ),
              ),

              // What happens next — quiet, because it is reference material.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: GlassCard(
                    level: GlassLevel.subtle,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          AppIcons.info_circle,
                          size: 17,
                          color: AppColors.textSecondary,
                        ),
                        AppSpacing.gapSm,
                        Expanded(
                          child: Text(
                            'After submitting, your task will be marked '
                            '"Pending review". You\'ll get a notification once '
                            'an admin approves or rejects it.',
                            style: AppTextStyles.footnote.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Clearance for the pinned action.
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: GlassButton(
              label: 'Submit task',
              icon: AppIcons.send_1,
              size: GlassButtonSize.large,
              loading: _isSubmitting,
              onPressed: _canSubmit ? _submit : null,
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
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xs,
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

// ─── File Upload Area ─────────────────────────────────────────────────────────

/// Drop zone for the photo / video submission types.
///
/// The card's rim carries the state: neutral when empty, brand while
/// uploading, green once the file is up.
class _FileUploadArea extends StatelessWidget {
  final File? pickedFile;
  final String? uploadedUrl;
  final bool isUploading;
  final _SubmissionType type;
  final VoidCallback onTap;

  const _FileUploadArea({
    required this.pickedFile,
    required this.uploadedUrl,
    required this.isUploading,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color? rim = uploadedUrl != null
        ? AppColors.success.withOpacity(0.45)
        : (isUploading ? AppColors.primaryRim : null);

    return GlassCard(
      onTap: isUploading ? null : onTap,
      rim: rim,
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 150),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isUploading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapMd,
            Text(
              'Uploading…',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (uploadedUrl != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GlassIconBubble(
              icon: AppIcons.tick_circle,
              color: AppColors.success,
              size: 48,
              iconSize: 24,
            ),
            AppSpacing.gapMd,
            Text(
              'File uploaded',
              style: AppTextStyles.subheadline.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap to replace',
              style: AppTextStyles.caption1
                  .copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    if (pickedFile != null && type == _SubmissionType.photo) {
      return ClipRRect(
        borderRadius: AppRadius.allLg,
        child: Image.file(pickedFile!, fit: BoxFit.cover),
      );
    }

    final (icon, label) = _iconAndLabel();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassIconBubble(icon: icon, size: 48, iconSize: 24),
          AppSpacing.gapMd,
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.subheadline.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tap to select from gallery',
            style: AppTextStyles.caption1
                .copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  (IconData, String) _iconAndLabel() {
    switch (type) {
      case _SubmissionType.photo:
        return (AppIcons.gallery, 'Select a photo');
      case _SubmissionType.pdf:
        return (AppIcons.document, 'Select a PDF');
      case _SubmissionType.video:
        return (AppIcons.video, 'Select a video');
      default:
        return (AppIcons.document_upload, 'Select a file');
    }
  }
}
