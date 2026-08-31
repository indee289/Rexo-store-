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
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_text_field.dart';
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Change Profile Photo',
                style: AppTextStyles.h6.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Edit Profile',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : TextButton(
                    onPressed: _saveProfile,
                    child: Text(
                      'Save',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar section with upload indicator
              _buildAvatarSection(theme),
              const SizedBox(height: AppSpacing.xxl),

              // Fields
              _buildField(
                context,
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

              _buildField(
                context,
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

              _buildField(
                context,
                controller: _bioController,
                label: 'Bio',
                hint: 'Tell the world about yourself...',
                icon: Iconsax.document_text,
                multiline: true,
              )
                  .animate()
                  .fadeIn(
                      delay: const Duration(milliseconds: 150),
                      duration: AppMotion.base)
                  .slideX(begin: 0.02, end: 0),
              const SizedBox(height: AppSpacing.lg),

              _buildField(
                context,
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

              // Save button
              PremiumButton(
                label: 'Save Changes',
                icon: Iconsax.save_2,
                gradient: true,
                loading: _isSaving,
                onPressed: _isSaving ? null : _saveProfile,
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
    );
  }

  Widget _buildAvatarSection(ThemeData theme) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showAvatarPickerSheet,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar with upload overlay
              AnimatedContainer(
                duration: AppMotion.base,
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedImage != null
                        ? AppColors.primary
                        : theme.dividerColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(
                          _selectedImage != null ? 0.2 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _isUploadingAvatar
                      ? Container(
                          color: theme.colorScheme.surface,
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

              // Camera button overlay (bottom right)
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
                          color: theme.colorScheme.surface, width: 2),
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
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool multiline = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (multiline)
          PremiumTextField.multiline(
            controller: controller,
            hint: hint,
            minLines: 3,
            maxLines: 5,
            validator: validator,
          )
        else
          PremiumTextField(
            controller: controller,
            hint: hint,
            prefixIcon: icon,
            keyboardType: keyboardType,
            validator: validator,
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
