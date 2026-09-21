import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/error_utils.dart';
import '../../services/r2_storage_service.dart';
import '../../services/supabase_service.dart';
import 'image_upload_field.dart';
import 'premium_text_field.dart';

/// The kind of optional demo asset an admin can attach to a campaign or job.
///
/// [none] means "no demo asset". The other values map 1:1 to the string keys
/// persisted in `public.campaigns.demo_asset_type`.
enum DemoAssetType { none, image, video, pdf, link, text }

/// Maps a [DemoAssetType] to the string key stored in the database.
///
/// Returns `null` for [DemoAssetType.none] so the column is written as NULL.
String? demoAssetTypeToKey(DemoAssetType type) {
  switch (type) {
    case DemoAssetType.none:
      return null;
    case DemoAssetType.image:
      return 'image';
    case DemoAssetType.video:
      return 'video';
    case DemoAssetType.pdf:
      return 'pdf';
    case DemoAssetType.link:
      return 'link';
    case DemoAssetType.text:
      return 'text';
  }
}

/// Maps a stored string key back to a [DemoAssetType].
///
/// Any unknown / null value resolves to [DemoAssetType.none].
DemoAssetType demoAssetTypeFromKey(String? key) {
  switch (key) {
    case 'image':
      return DemoAssetType.image;
    case 'video':
      return DemoAssetType.video;
    case 'pdf':
      return DemoAssetType.pdf;
    case 'link':
      return DemoAssetType.link;
    case 'text':
      return DemoAssetType.text;
    default:
      return DemoAssetType.none;
  }
}

/// A reusable, fully-optional demo-asset picker.
///
/// It renders a horizontally-scrollable segmented control
/// (None / Image / Video / PDF / Link / Text) modelled on the submission
/// selector in `submit_task_screen.dart`. Depending on the selected type it
/// shows the right input:
///   * image -> [ImageUploadField] (R2 upload),
///   * video -> gallery video picker + R2 upload,
///   * pdf / link -> a URL text field,
///   * text -> a multiline text field.
///
/// The parent receives changes via [onChanged] as `(type, value)` where the
/// value semantics are:
///   * image / video / pdf -> uploaded / pasted R2 or public URL,
///   * link -> the pasted external URL,
///   * text -> the raw text body,
///   * none -> null.
class DemoAssetField extends StatefulWidget {
  /// Folder used for R2 uploads (video). Images use `<storageFolder>` too.
  final String storageFolder;

  /// Prefill type on edit.
  final DemoAssetType initialType;

  /// Prefill value on edit (URL or text body).
  final String? initialValue;

  /// Delivers `(type, value)` to the parent on every change.
  final void Function(DemoAssetType type, String? value) onChanged;

  const DemoAssetField({
    super.key,
    this.storageFolder = 'campaign-demo-assets',
    this.initialType = DemoAssetType.none,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<DemoAssetField> createState() => _DemoAssetFieldState();
}

class _DemoAssetFieldState extends State<DemoAssetField> {
  late DemoAssetType _type;
  final _urlController = TextEditingController();
  final _textController = TextEditingController();

  String? _uploadedUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    final v = widget.initialValue;
    if (v != null && v.isNotEmpty) {
      switch (_type) {
        case DemoAssetType.image:
        case DemoAssetType.video:
          _uploadedUrl = v;
          break;
        case DemoAssetType.pdf:
        case DemoAssetType.link:
          _urlController.text = v;
          break;
        case DemoAssetType.text:
          _textController.text = v;
          break;
        case DemoAssetType.none:
          break;
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ─── Value plumbing ─────────────────────────────────────────────────────────

  void _emit() {
    String? value;
    switch (_type) {
      case DemoAssetType.none:
        value = null;
        break;
      case DemoAssetType.image:
      case DemoAssetType.video:
        value = (_uploadedUrl != null && _uploadedUrl!.isNotEmpty)
            ? _uploadedUrl
            : null;
        break;
      case DemoAssetType.pdf:
      case DemoAssetType.link:
        final t = _urlController.text.trim();
        value = t.isEmpty ? null : t;
        break;
      case DemoAssetType.text:
        final t = _textController.text.trim();
        value = t.isEmpty ? null : t;
        break;
    }
    widget.onChanged(_type, value);
  }

  void _selectType(DemoAssetType type) {
    setState(() {
      _type = type;
      // Reset transient state that does not apply to the new type so we never
      // carry a stale value across types.
      if (type != DemoAssetType.image && type != DemoAssetType.video) {
        _uploadedUrl = null;
      }
      if (type != DemoAssetType.pdf && type != DemoAssetType.link) {
        _urlController.clear();
      }
      if (type != DemoAssetType.text) {
        _textController.clear();
      }
    });
    _emit();
  }

  // ─── Video upload (mirrors submit_task_screen.dart) ──────────────────────────

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    final user = SupabaseService.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(picked.path);
      final ext = file.path.split('.').last.toLowerCase();
      final fileName = '${const Uuid().v4()}.$ext';
      final folder = '${widget.storageFolder}/${user.id}';
      final bytes = await file.readAsBytes();
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
      _emit();
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.sanitize(e)),
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

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DemoAssetTypeSelector(
          selected: _type,
          isDark: isDark,
          onChanged: _selectType,
        ),
        if (_type != DemoAssetType.none) ...[
          const SizedBox(height: AppSpacing.md),
          _buildInput(isDark),
        ],
      ],
    );
  }

  Widget _buildInput(bool isDark) {
    switch (_type) {
      case DemoAssetType.none:
        return const SizedBox.shrink();
      case DemoAssetType.image:
        return ImageUploadField(
          label: 'Demo Image',
          storageFolder: widget.storageFolder,
          currentImageUrl: _uploadedUrl,
          onImageUploaded: (url) {
            setState(() => _uploadedUrl = url);
            _emit();
          },
        );
      case DemoAssetType.video:
        return _VideoUploadArea(
          uploadedUrl: _uploadedUrl,
          isUploading: _isUploading,
          isDark: isDark,
          onTap: _isUploading ? null : _pickVideo,
        );
      case DemoAssetType.pdf:
      case DemoAssetType.link:
        return PremiumTextField(
          controller: _urlController,
          hint: 'Paste a public link / PDF URL',
          prefixIcon: Iconsax.link,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onChanged: (_) => _emit(),
        );
      case DemoAssetType.text:
        return PremiumTextField.multiline(
          controller: _textController,
          hint: 'Write the demo details / example text…',
          minLines: 3,
          maxLines: 8,
          onChanged: (_) => _emit(),
        );
    }
  }
}

// ─── Demo Asset Type Selector ─────────────────────────────────────────────────

class _DemoAssetTypeSelector extends StatelessWidget {
  final DemoAssetType selected;
  final bool isDark;
  final ValueChanged<DemoAssetType> onChanged;

  const _DemoAssetTypeSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  static const _types = <(DemoAssetType, IconData, String)>[
    (DemoAssetType.none, Iconsax.close_circle, 'None'),
    (DemoAssetType.image, Iconsax.gallery, 'Image'),
    (DemoAssetType.video, Iconsax.video, 'Video'),
    (DemoAssetType.pdf, Iconsax.document, 'PDF'),
    (DemoAssetType.link, Iconsax.link, 'Link'),
    (DemoAssetType.text, Iconsax.edit, 'Text'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
          borderRadius: AppRadius.allMd,
        ),
        child: Row(
          children: _types.map((t) {
            final isSelected = t.$1 == selected;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => onChanged(t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
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
      ),
    );
  }
}

// ─── Video Upload Area ────────────────────────────────────────────────────────

class _VideoUploadArea extends StatelessWidget {
  final String? uploadedUrl;
  final bool isUploading;
  final bool isDark;
  final VoidCallback? onTap;

  const _VideoUploadArea({
    required this.uploadedUrl,
    required this.isUploading,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final hint = isDark ? AppColors.darkTextHint : AppColors.textHint;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.allMd,
          border: Border.all(
            color: (uploadedUrl != null && uploadedUrl!.isNotEmpty)
                ? AppColors.success
                : (isUploading ? AppColors.primary : border),
            width: (uploadedUrl != null && uploadedUrl!.isNotEmpty) ? 1.5 : 1,
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
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 20),
        ],
      );
    }

    if (uploadedUrl != null && uploadedUrl!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.tick_circle, size: 36, color: AppColors.success),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Video uploaded successfully',
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

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.video, size: 36, color: hint),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Select a video',
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
}
