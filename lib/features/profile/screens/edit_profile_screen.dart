import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
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

  /// Shows bottom sheet to pick photo source
  void _showAvatarPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: AppRadius.topXl,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Change Profile Photo',
                style: AppTextStyles.h6.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AvatarOptionButton(
                    icon: Iconsax.camera,
                    label: 'Camera',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _AvatarOptionButton(
                    icon: Iconsax.gallery,
                    label: 'Gallery',
                    color: AppColors.accentPurple,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_currentAvatarUrl != null || _selectedImage != null)
                    _AvatarOptionButton(
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

      // Upload immediately for instant feedback
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
        content: Text(message, style: AppTextStyles.bodySmall),
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
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom dark top bar ─────────────────────────────────────────
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(
                  bottom: BorderSide(color: AppColors.darkBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: AppRadius.allSm,
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(
                        Iconsax.arrow_left,
                        size: 18,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Edit Profile',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h5.copyWith(
                        color: AppColors.darkTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 36,
                            height: 36,
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
                        : Text(
                            'Save',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Avatar section
                      _buildAvatarSection(),
                      const SizedBox(height: AppSpacing.xxl),

                      // Form fields on dark cards
                      _buildDarkField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Iconsax.user,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(
                              delay: const Duration(milliseconds: 50),
                              duration: AppMotion.base)
                          .slideX(begin: 0.02, end: 0),
                      const SizedBox(height: AppSpacing.lg),

                      _buildDarkField(
                        controller: _handleController,
                        label: 'Username',
                        hint: '@your_handle',
                        icon: Iconsax.user_tag,
                      )
                          .animate()
                          .fadeIn(
                              delay: const Duration(milliseconds: 100),
                              duration: AppMotion.base)
                          .slideX(begin: 0.02, end: 0),
                      const SizedBox(height: AppSpacing.lg),

                      _buildDarkMultilineField(
                        controller: _bioController,
                        label: 'Bio',
                        hint: 'Tell the world about yourself...',
                      )
                          .animate()
                          .fadeIn(
                              delay: const Duration(milliseconds: 150),
                              duration: AppMotion.base)
                          .slideX(begin: 0.02, end: 0),
                      const SizedBox(height: AppSpacing.lg),

                      _buildDarkField(
                        controller: _phoneController,
                        label: 'Phone',
                        hint: '+91 98765 43210',
                        icon: Iconsax.call,
                        keyboardType: TextInputType.phone,
                      )
                          .animate()
                          .fadeIn(
                              delay: const Duration(milliseconds: 200),
                              duration: AppMotion.base)
                          .slideX(begin: 0.02, end: 0),
                      const SizedBox(height: AppSpacing.xxl),

                      // Save Changes gradient button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: AppRadius.allMd,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.allMd),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Iconsax.save_2,
                                    color: Colors.white, size: 18),
                            label: Text(
                              'Save Changes',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(
                              delay: const Duration(milliseconds: 250),
                              duration: AppMotion.base),
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
              AnimatedContainer(
                duration: AppMotion.base,
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedImage != null
                        ? AppColors.primary
                        : AppColors.darkBorder,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(
                          _selectedImage != null ? 0.25 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _isUploadingAvatar
                      ? Container(
                          color: AppColors.darkCard,
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
                              width: 108,
                              height: 108,
                              fit: BoxFit.cover,
                            )
                          : PremiumAvatar(
                              imageUrl: _currentAvatarUrl,
                              name: _nameController.text,
                              size: 108,
                              showRing: false,
                            ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: AnimatedScale(
                  scale: _isUploadingAvatar ? 0.8 : 1.0,
                  duration: AppMotion.fast,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.darkBackground, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _isUploadingAvatar
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Iconsax.camera,
                            size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: AppMotion.base)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

        const SizedBox(height: AppSpacing.sm),
        Text(
          _isUploadingAvatar ? 'Uploading...' : 'Tap to change photo',
          style: AppTextStyles.caption.copyWith(
            color: _isUploadingAvatar
                ? AppColors.primary
                : AppColors.darkTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDarkField({
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
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.darkTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.darkTextHint,
            ),
            filled: true,
            fillColor: AppColors.darkCard,
            prefixIcon:
                Icon(icon, color: AppColors.darkTextSecondary, size: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDarkMultilineField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          maxLines: 4,
          minLines: 3,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.darkTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.darkTextHint,
            ),
            filled: true,
            fillColor: AppColors.darkCard,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Avatar picker option button (camera/gallery/remove)
class _AvatarOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AvatarOptionButton({
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadius.allLg,
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
