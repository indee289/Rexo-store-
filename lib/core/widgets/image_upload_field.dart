import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../services/r2_storage_service.dart';
import '../../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/error_utils.dart';
import 'glass/glass.dart';

/// A reusable image upload widget that picks an image from camera/gallery,
/// uploads it to Cloudflare R2 Storage, and returns the public URL.
///
/// Rebuilt: the drop zone was a `Container` with its own radius and border, the
/// label and every caption came from `GoogleFonts.poppins` at hardcoded sizes
/// rather than the type scale, the source picker was a bare
/// `showModalBottomSheet` of two `ListTile`s, and the failure path used a raw
/// `ScaffoldMessenger`. It is now a `GlassCard` drop zone whose rim carries the
/// upload state, type from `AppTextStyles`, a tile grid for the source picker
/// and the shared toast.
///
/// The public API ([currentImageUrl], [storageFolder], [label],
/// [onImageUploaded]), the picker options, the R2 path construction and the
/// content-type table are all unchanged.
class ImageUploadField extends StatefulWidget {
  final String? currentImageUrl;
  final String storageFolder;
  final String label;
  final ValueChanged<String> onImageUploaded;

  const ImageUploadField({
    super.key,
    this.currentImageUrl,
    this.storageFolder = 'product-images',
    this.label = 'Upload Image',
    required this.onImageUploaded,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  File? _selectedFile;
  bool _isUploading = false;
  String? _uploadedUrl;

  @override
  void initState() {
    super.initState();
    _uploadedUrl = widget.currentImageUrl;
  }

  bool get _hasImage =>
      _selectedFile != null ||
      (_uploadedUrl != null && _uploadedUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            widget.label,
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        GlassCard.bare(
          onTap: _isUploading ? null : _showImagePicker,
          rim: _isUploading
              ? AppColors.primaryRim
              : (_hasImage ? AppColors.success.withOpacity(0.40) : null),
          child: SizedBox(
            width: double.infinity,
            height: 160,
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isUploading) {
      return const Center(child: GlassLoader(message: 'Uploading…', size: 26));
    }

    if (_selectedFile != null) {
      return _preview(Image.file(_selectedFile!, fit: BoxFit.cover));
    }

    if (_uploadedUrl != null && _uploadedUrl!.isNotEmpty) {
      return _preview(
        Image.network(
          _uploadedUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  /// Image preview with a replace affordance in the corner.
  Widget _preview(Widget image) {
    return ClipRRect(
      borderRadius: AppRadius.allLg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: GlassIconButton.filled(
              icon: AppIcons.edit_2,
              tooltip: 'Replace image',
              size: 34,
              iconSize: 17,
              onTap: _showImagePicker,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const GlassIconBubble(
          icon: AppIcons.gallery_add,
          size: 48,
          iconSize: 24,
        ),
        AppSpacing.gapMd,
        Text(
          'Tap to upload image',
          style: AppTextStyles.subheadline.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Camera or gallery',
          style: AppTextStyles.caption1.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  void _showImagePicker() {
    showGlassSheet<void>(
      context: context,
      title: 'Select image source',
      child: Builder(
        builder: (sheetContext) => GlassTileGrid(
          columns: 2,
          tiles: [
            GlassTile(
              icon: AppIcons.camera,
              label: 'Camera',
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            GlassTile(
              icon: AppIcons.gallery,
              label: 'Gallery',
              color: AppColors.accentPurple,
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedFile == null) return;

    final user = SupabaseService.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final fileExt = _selectedFile!.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';
      final filePath = '${widget.storageFolder}/${user.id}/$fileName';
      final fileBytes = await _selectedFile!.readAsBytes();

      final contentType = _getContentType(fileExt);

      final publicUrl = await R2StorageService.uploadFile(
        filePath,
        fileBytes,
        contentType,
      );

      setState(() {
        _uploadedUrl = publicUrl;
        _isUploading = false;
      });

      widget.onImageUploaded(publicUrl);
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

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
