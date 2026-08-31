import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_button.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _selectedImage;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final profileAsync = ref.read(currentUserProfileProvider);
    profileAsync.whenData((profileState) {
      final profile = profileState.profile;
      if (profile != null) {
        _nameController.text = profile['name'] ?? '';
        _handleController.text = profile['handle'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _currentAvatarUrl = profile['avatar_url'];
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showAvatarPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.topXl,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AvatarOption(
                    icon: Iconsax.camera,
                    label: 'Camera',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _AvatarOption(
                    icon: Iconsax.gallery,
                    label: 'Gallery',
                    color: AppColors.accentPurple,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_currentAvatarUrl != null || _selectedImage != null)
                    _AvatarOption(
                      icon: Iconsax.trash,
                      label: 'Remove',
                      color: AppColors.error,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedImage = null;
                          _currentAvatarUrl = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isUploadingAvatar = true;
      });

      try {
        final notifier = ref.read(profileNotifierProvider.notifier);
        final avatarUrl = await notifier.uploadAvatar(_selectedImage!);
        if (avatarUrl != null && mounted) {
          setState(() {
            _currentAvatarUrl = avatarUrl;
            _isUploadingAvatar = false;
          });
          _showSnack('Photo updated!', AppColors.success);
        } else if (mounted) {
          setState(() => _isUploadingAvatar = false);
          _showSnack('Failed to upload photo', AppColors.error);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploadingAvatar = false);
          _showSnack('Upload failed: ${e.toString()}', AppColors.error);
        }
      }
    }
  }

  void _showSnack(String message, Color background) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(profileNotifierProvider.notifier);
      final fields = <String, dynamic>{
        'name': _nameController.text.trim(),
        'handle': _handleController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      if (_currentAvatarUrl != null) {
        fields['avatar_url'] = _currentAvatarUrl;
      }

      final success = await notifier.updateProfile(fields);

      if (mounted) {
        if (success) {
          ref.invalidate(currentUserProfileProvider);
          _showSnack('Profile updated successfully ✓', AppColors.success);
          Navigator.of(context).pop();
        } else {
          final errorMessage = notifier.lastError != null
              ? ErrorUtils.sanitize(notifier.lastError)
              : 'Failed to update profile';
          _showSnack(errorMessage, AppColors.error);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack(ErrorUtils.sanitize(e), AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ────────────────────────────────────────────────────
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar section — center
                      Center(child: _buildAvatarSection()),
                      const SizedBox(height: AppSpacing.xxl),

                      _buildField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Iconsax.user,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _buildField(
                        controller: _handleController,
                        label: 'Username',
                        hint: '@your_handle',
                        icon: Iconsax.user_tag,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _buildMultilineField(
                        controller: _bioController,
                        label: 'Bio',
                        hint: 'Tell the world about yourself...',
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _buildField(
                        controller: _phoneController,
                        label: 'Phone',
                        hint: '+91 98765 43210',
                        icon: Iconsax.call,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Save button
                      PremiumButton(
                        label: 'Save Changes',
                        loading: _isSaving,
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: Iconsax.save_2,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showAvatarPickerSheet,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: _isUploadingAvatar
                      ? Container(
                          color: AppColors.surfaceAlt,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : PremiumAvatar(
                              imageUrl: _currentAvatarUrl,
                              name: _nameController.text,
                              size: 80,
                            ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Iconsax.camera,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isUploadingAvatar ? 'Uploading...' : 'Tap to change photo',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
              fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 14, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            prefixIcon:
                Icon(icon, color: AppColors.textHint, size: 20),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide:
                  const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultilineField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          minLines: 3,
          style: const TextStyle(
              fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 14, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Avatar picker option button.
class _AvatarOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AvatarOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadius.allMd,
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
