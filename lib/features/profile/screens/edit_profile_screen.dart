import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../providers/profile_provider.dart';

/// Edit profile — rebuilt layout.
///
/// Old layout: a hand-assembled fake app bar (a `Container` with a bare
/// `GestureDetector` back chevron and a text "Save"), a bare centred avatar,
/// then four fields each built by a local `_buildField` helper that declared
/// its own `OutlineInputBorder`s and its own label `Text`. The whole screen
/// also carried a parallel set of dark-mode colour getters.
///
/// New layout: the standard collapsing large title; the avatar promoted into a
/// card that states what tapping it does; the fields grouped under named
/// headings (identity, about, contact) with labels and borders coming from the
/// shared text field; the photo-source picker rebuilt as a tile grid in a
/// glass sheet instead of three hand-drawn squares; and Save pinned to the
/// bottom as the single primary action rather than a small text target in the
/// corner. The dark-mode getters are gone — the app is light mode only.
///
/// `currentUserProfileProvider`, `profileNotifierProvider.uploadAvatar`,
/// `updateProfile`, `lastError`, the exact field keys and the image-picker
/// options are unchanged.
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
        _handleController.text = profile['username'] ?? ''; // live: username
        _bioController.text = profile['bio'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _currentAvatarUrl = profile['profileImage']; // live: profileImage
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
    showGlassSheet<void>(
      context: context,
      title: 'Profile photo',
      subtitle: 'Pick a new photo or remove the current one',
      child: Builder(
        builder: (sheetContext) => GlassTileGrid(
          columns: 3,
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
            if (_currentAvatarUrl != null || _selectedImage != null)
              GlassTile(
                icon: AppIcons.trash,
                label: 'Remove',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _selectedImage = null;
                    _currentAvatarUrl = null;
                  });
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
          _showSnack('Photo updated!', GlassToastTone.success);
        } else if (mounted) {
          setState(() => _isUploadingAvatar = false);
          _showSnack('Failed to upload photo', GlassToastTone.error);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploadingAvatar = false);
          _showSnack(ErrorUtils.sanitize(e), GlassToastTone.error);
        }
      }
    }
  }

  void _showSnack(String message, GlassToastTone tone) {
    showGlassSnackBar(context, message: message, tone: tone);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(profileNotifierProvider.notifier);
      final fields = <String, dynamic>{
        'name': _nameController.text.trim(),
        'username': _handleController.text.trim(), // live: username
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      if (_currentAvatarUrl != null) {
        fields['profileImage'] = _currentAvatarUrl; // live: profileImage
      }

      final success = await notifier.updateProfile(fields);

      if (mounted) {
        if (success) {
          ref.invalidate(currentUserProfileProvider);
          _showSnack('Profile updated successfully', GlassToastTone.success);
          Navigator.of(context).pop();
        } else {
          final errorMessage = notifier.lastError != null
              ? ErrorUtils.sanitize(notifier.lastError)
              : 'Failed to update profile';
          _showSnack(errorMessage, GlassToastTone.error);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack(ErrorUtils.sanitize(e), GlassToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                const GlassLargeTitleHeader(
                  title: 'Edit profile',
                  subtitle: 'How others see you across Campster',
                  showBack: true,
                ),

                // Avatar hero — a card, so the tap target reads as deliberate
                // rather than as a floating circle.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: GlassCard(
                      onTap: _isUploadingAvatar ? null : _showAvatarPickerSheet,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAvatar(),
                          AppSpacing.gapMd,
                          Text(
                            _isUploadingAvatar
                                ? 'Uploading photo…'
                                : 'Tap to change photo',
                            style: AppTextStyles.subheadline.copyWith(
                              color: _isUploadingAvatar
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'JPG or PNG, square works best',
                            style: AppTextStyles.caption1.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Identity
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
                        _sectionLabel('Identity'),
                        GlassTextField(
                          controller: _nameController,
                          label: 'Full name',
                          hint: 'Enter your full name',
                          prefixIcon: AppIcons.user,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapLg,
                        GlassTextField(
                          controller: _handleController,
                          label: 'Username',
                          hint: '@your_handle',
                          prefixIcon: AppIcons.user_tag,
                        ),
                      ],
                    ),
                  ),
                ),

                // About
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
                        _sectionLabel('About'),
                        GlassTextField.multiline(
                          controller: _bioController,
                          label: 'Bio',
                          hint: 'Tell the world about yourself…',
                          helperText:
                              'Shown on your public profile and applications',
                          minLines: 3,
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ),

                // Contact
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
                        _sectionLabel('Contact'),
                        GlassTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          hint: '+91 98765 43210',
                          prefixIcon: AppIcons.call,
                          keyboardType: TextInputType.phone,
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
              label: 'Save changes',
              icon: AppIcons.save_2,
              size: GlassButtonSize.large,
              loading: _isSaving,
              onPressed: _isSaving ? null : _saveProfile,
            ),
          ),
        ],
      ),
    );
  }

  /// The avatar itself, with its camera badge and upload state.
  Widget _buildAvatar() {
    const double diameter = 96;

    Widget inner;
    if (_isUploadingAvatar) {
      inner = const ColoredBox(
        color: AppColors.surfaceAlt,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.4,
            ),
          ),
        ),
      );
    } else if (_selectedImage != null) {
      inner = Image.file(
        _selectedImage!,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
      );
    } else {
      inner = PremiumAvatar(
        imageUrl: _currentAvatarUrl,
        name: _nameController.text,
        size: diameter,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: diameter,
          height: diameter,
          child: ClipOval(child: inner),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2.5),
            ),
            child: const Icon(
              AppIcons.camera,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
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
}
