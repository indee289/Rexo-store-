import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showSnack(String message, Color background) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodySmall),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(profileNotifierProvider.notifier);

      // Upload avatar if changed
      if (_selectedImage != null) {
        final avatarUrl = await notifier.uploadAvatar(_selectedImage!);
        if (avatarUrl != null) {
          _currentAvatarUrl = avatarUrl;
        }
      }

      // Update profile fields
      final fields = <String, dynamic>{
        'name': _nameController.text.trim(),
        'handle': _handleController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      // Include avatar URL in update if it was uploaded
      if (_currentAvatarUrl != null) {
        fields['avatar_url'] = _currentAvatarUrl;
      }

      final success = await notifier.updateProfile(fields);

      if (mounted) {
        if (success) {
          // Refresh profile data
          ref.invalidate(currentUserProfileProvider);
          _showSnack('Profile updated successfully', AppColors.success);
          Navigator.of(context).pop();
        } else {
          // Read the actual error from the notifier for a specific message
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
      appBar: AppBar(
        title: Text('Edit Profile', style: AppTextStyles.h5),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Iconsax.arrow_left, color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    'Save',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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
              // Avatar
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    if (_selectedImage != null)
                      ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      PremiumAvatar(
                        imageUrl: _currentAvatarUrl,
                        name: _nameController.text,
                        size: 100,
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.surface, width: 2),
                        ),
                        child: const Icon(
                          Iconsax.camera,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tap to change photo',
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Name field
              _buildField(
                controller: _nameController,
                label: 'Name',
                hint: 'Enter your full name',
                icon: Iconsax.user,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Handle field
              _buildField(
                controller: _handleController,
                label: 'Handle',
                hint: '@your_handle',
                icon: Iconsax.user_tag,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Bio field
              _buildField(
                controller: _bioController,
                label: 'Bio',
                hint: 'Tell us about yourself...',
                icon: Iconsax.document_text,
                multiline: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Phone field
              _buildField(
                controller: _phoneController,
                label: 'Phone',
                hint: 'Enter your phone number',
                icon: Iconsax.call,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Save button
              PremiumButton(
                label: 'Save Changes',
                gradient: true,
                loading: _isSaving,
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
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
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (multiline)
          PremiumTextField.multiline(
            controller: controller,
            hint: hint,
            minLines: 3,
            maxLines: 4,
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
