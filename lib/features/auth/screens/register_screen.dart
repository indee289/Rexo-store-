import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

/// Instagram-style register screen.
///
/// Clean, centered layout: logo, name + email + password fields,
/// role selector (Creator / Brand), blue "Sign up" button,
/// "Already have an account? Log in" link at bottom.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _handleController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'creator';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          role: _selectedRole,
          handle: _handleController.text.trim().isEmpty
              ? _emailController.text.trim().split('@').first
              : _handleController.text.trim(),
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated && authState.errorMessage != null) {
      _showSnack(authState.errorMessage!, AppColors.error);
    } else if (authState.isAuthenticated) {
      _showSnack('Account created!', AppColors.success);
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // Logo
                  Image.asset(
                    'assets/logo.png',
                    width: 64,
                    height: 64,
                    errorBuilder: (_, __, ___) => Text(
                      'Rexo',
                      style: AppTextStyles.largeTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign up to get started',
                    style: AppTextStyles.subheadline.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Name
                  _IgTextField(
                    controller: _nameController,
                    hint: 'Full name',
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Email
                  _IgTextField(
                    controller: _emailController,
                    hint: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter email';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Username
                  _IgTextField(
                    controller: _handleController,
                    hint: 'Username',
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Choose a username';
                      if (v.trim().length < 3) return 'Min 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Password
                  _IgTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter password';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Role selector — Instagram-style segmented
                  Row(
                    children: [
                      Expanded(
                        child: _RoleChip(
                          label: 'Creator',
                          icon: Iconsax.user,
                          selected: _selectedRole == 'creator',
                          onTap: () =>
                              setState(() => _selectedRole = 'creator'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RoleChip(
                          label: 'Brand',
                          icon: Iconsax.briefcase,
                          selected: _selectedRole == 'brand',
                          onTap: () =>
                              setState(() => _selectedRole = 'brand'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Sign Up button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: GestureDetector(
                      onTap: authState.isLoading ? null : _handleSignUp,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 100),
                        opacity: authState.isLoading ? 0.6 : 1.0,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppRadius.allMd,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Sign up',
                                  style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // OR divider
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Expanded(
                          child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Log in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.subheadline
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: Text(
                          'Log in',
                          style: AppTextStyles.subheadline.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Instagram-style role selector chip.
class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: AppRadius.allMd,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.headline.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Instagram-style text field.
class _IgTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _IgTextField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      validator: validator,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      cursorColor: AppColors.textPrimary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
