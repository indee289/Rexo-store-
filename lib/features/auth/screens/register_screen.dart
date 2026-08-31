import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'creator';

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Normalize a raw username input: strip a leading '@', trim, lowercase.
  String _normalizeHandle(String value) {
    var handle = value.trim();
    if (handle.startsWith('@')) {
      handle = handle.substring(1);
    }
    return handle.trim().toLowerCase();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          role: _selectedRole,
          handle: _normalizeHandle(_usernameController.text),
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.error &&
        authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        ),
      );
    } else if (authState.isAuthenticated) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Back button ─────────────────────────────────────────────
                GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: AppRadius.allMd,
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: const Icon(
                      Iconsax.arrow_left,
                      size: 20,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Heading ─────────────────────────────────────────────────
                Text(
                  'Create Account',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join Rexo and start your journey',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Full Name ───────────────────────────────────────────────
                _RegDarkField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Iconsax.user,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Username ────────────────────────────────────────────────
                _RegDarkField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'e.g. jane_doe',
                  icon: Iconsax.user_tag,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_@]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return newValue.copyWith(
                          text: newValue.text.toLowerCase());
                    }),
                  ],
                  validator: (value) {
                    final handle = _normalizeHandle(value ?? '');
                    if (handle.isEmpty) return 'Please choose a username';
                    if (handle.length < 3 || handle.length > 20) {
                      return 'Username must be 3-20 characters';
                    }
                    if (!RegExp(r'^[a-z]').hasMatch(handle)) {
                      return 'Username must start with a letter';
                    }
                    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(handle)) {
                      return 'Only lowercase letters, numbers and underscore';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Email ───────────────────────────────────────────────────
                _RegDarkField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Iconsax.sms,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ────────────────────────────────────────────────
                _RegDarkField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a password',
                  icon: Iconsax.lock,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                      color: AppColors.darkTextSecondary,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!value.contains(RegExp(r'[A-Za-z]'))) {
                      return 'Password must contain at least one letter';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain at least one number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Confirm Password ────────────────────────────────────────
                _RegDarkField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Iconsax.lock,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: GestureDetector(
                    onTap: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    child: Icon(
                      _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
                      color: AppColors.darkTextSecondary,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // ── Role selector ───────────────────────────────────────────
                Text(
                  'I am a',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        title: 'Creator',
                        icon: Iconsax.user,
                        description: 'Content creator or influencer',
                        isSelected: _selectedRole == 'creator',
                        onTap: () => setState(() => _selectedRole = 'creator'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        title: 'Brand',
                        icon: Iconsax.building,
                        description: 'Business or brand',
                        isSelected: _selectedRole == 'brand',
                        onTap: () => setState(() => _selectedRole = 'brand'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Sign Up CTA ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: !authState.isLoading
                          ? AppColors.primaryGradient
                          : const LinearGradient(
                              colors: [Color(0xFF4B4D72), Color(0xFF4B4D72)]),
                      borderRadius: AppRadius.allMd,
                      boxShadow: !authState.isLoading
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              )
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.allMd,
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Sign Up',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Login link ──────────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: Text(
                          'Sign In',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Role selection card widget (dark premium).
class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.darkCard,
          borderRadius: AppRadius.allMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.darkSurfaceAlt,
                borderRadius: AppRadius.allSm,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.darkTextSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark field variant for register screen (same style as login _DarkField but
/// with extra inputFormatters support).
class _RegDarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _RegDarkField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
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
            prefixIcon: Icon(icon, color: AppColors.darkTextSecondary, size: 20),
            suffixIcon: suffixIcon,
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
}
