import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../services/supabase_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    // Password OK but a verified second factor is required — go finish the
    // MFA challenge (the router redirect also enforces this).
    if (authState.status == AuthStatus.mfaRequired) {
      context.go(AppRoutes.mfaChallenge);
      return;
    }
    // Surface ANY login failure. signIn reports bad credentials as
    // `unauthenticated` + errorMessage (not `error`), so gate on the message,
    // not the status, otherwise password errors were silently swallowed.
    if (!authState.isAuthenticated && authState.errorMessage != null) {
      _showSnack(authState.errorMessage!, AppColors.error);
    } else if (authState.isAuthenticated) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleForgotPassword() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Reset Password',
            style: AppTextStyles.h6,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your account email and we\'ll send you a link to reset '
                'your password.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              PremiumTextField(
                controller: controller,
                hint: 'you@example.com',
                prefixIcon: Iconsax.sms,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            PremiumButton(
              label: 'Cancel',
              variant: PremiumButtonVariant.ghost,
              expand: false,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            PremiumButton(
              label: 'Send Link',
              expand: false,
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (email == null || email.isEmpty) return;
    // Basic email sanity check before hitting the network.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      if (!mounted) return;
      _showSnack('Please enter a valid email address', AppColors.error);
      return;
    }

    try {
      await SupabaseService.resetPassword(email);
      if (!mounted) return;
      _showSnack('Password reset link sent to $email', AppColors.success);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Could not send reset link. Please try again.',
        AppColors.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Logo
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppRadius.allLg,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'R',
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Welcome text
                Text(
                  'Welcome Back',
                  style: AppTextStyles.h2.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sign in to continue to Rexo',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Email field
                PremiumTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Iconsax.sms,
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

                const SizedBox(height: AppSpacing.lg),

                // Password field
                PremiumTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Iconsax.lock,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      size: 20,
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!authState.isLoading) _handleSignIn();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: PremiumButton(
                    label: 'Forgot Password?',
                    variant: PremiumButtonVariant.ghost,
                    expand: false,
                    onPressed: _handleForgotPassword,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Sign In button
                PremiumButton(
                  label: 'Sign In',
                  gradient: true,
                  loading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _handleSignIn,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Register link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.register),
                        child: Text(
                          'Sign Up',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
