import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../services/supabase_service.dart';
import '../providers/auth_provider.dart';

/// Login screen — liquid glass.
///
/// The form lives on a single frosted plate floating over the ambient
/// backdrop, so the first thing a new user sees establishes the glass
/// language. Auth flow, validation rules, MFA redirect and routes are
/// unchanged.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.mfaRequired) {
      context.go(AppRoutes.mfaChallenge);
      return;
    }
    if (!authState.isAuthenticated && authState.errorMessage != null) {
      showGlassSnackBar(
        context,
        message: authState.errorMessage!,
        tone: GlassToastTone.error,
      );
    } else if (authState.isAuthenticated) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleForgotPassword() async {
    final controller =
        TextEditingController(text: _emailController.text.trim());

    final email = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.28),
      builder: (dialogContext) => GlassDialog(
        title: 'Reset password',
        icon: Iconsax.lock,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter your email and we'll send you a reset link.",
              textAlign: TextAlign.center,
              style: AppTextStyles.subheadline.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            AppSpacing.gapLg,
            GlassTextField(
              controller: controller,
              hint: 'Email',
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              prefixIcon: Iconsax.sms,
            ),
          ],
        ),
        confirmLabel: 'Send link',
        onConfirm: () =>
            Navigator.pop(dialogContext, controller.text.trim()),
        cancelLabel: 'Cancel',
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );

    controller.dispose();
    if (email == null || email.isEmpty) return;

    try {
      await SupabaseService.resetPassword(email);
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: 'Reset link sent to $email',
        tone: GlassToastTone.success,
      );
    } catch (e) {
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: 'Could not send reset link.',
        tone: GlassToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return GlassScaffold(
      extendBodyBehindAppBar: false,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: GlassSurface(
              level: GlassLevel.modal,
              borderRadius: AppRadius.allXxl,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      cacheWidth: 192,
                      width: 64,
                      height: 64,
                      errorBuilder: (_, __, ___) => Text(
                        'Campster',
                        style: AppTextStyles.largeTitle.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 34,
                        ),
                      ),
                    ),
                    AppSpacing.gapMd,
                    Text(
                      'Welcome back',
                      style: AppTextStyles.title2
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Log in to continue',
                      style: AppTextStyles.footnote
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    AppSpacing.gapXl,

                    GlassTextField(
                      controller: _emailController,
                      hint: 'Email',
                      prefixIcon: Iconsax.sms,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter email';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    AppSpacing.gapMd,

                    // obscureText drives GlassTextField's built-in reveal
                    // toggle, so the screen no longer tracks that state.
                    GlassTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      prefixIcon: Iconsax.lock,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!authState.isLoading) _handleSignIn();
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter password';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                    AppSpacing.gapLg,

                    GlassButton(
                      label: 'Log in',
                      loading: authState.isLoading,
                      onPressed: authState.isLoading ? null : _handleSignIn,
                      size: GlassButtonSize.large,
                    ),
                    AppSpacing.gapSm,

                    GlassButton.ghost(
                      label: 'Forgot password?',
                      onPressed: _handleForgotPassword,
                      size: GlassButtonSize.small,
                    ),
                    AppSpacing.gapMd,

                    const _OrDivider(),
                    AppSpacing.gapMd,

                    GlassButton.glass(
                      label: 'Create an account',
                      icon: Iconsax.user_add,
                      onPressed: () => context.go(AppRoutes.register),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hairline rule with a centred "OR".
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'OR',
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
      ],
    );
  }
}
