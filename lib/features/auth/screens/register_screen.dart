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
import '../providers/auth_provider.dart';

/// Register screen — liquid glass.
///
/// Mirrors the login plate so the two auth screens feel like one surface.
/// The Creator / Brand picker is now a glass segmented control instead of two
/// separate filled chips, which makes it read as a single either/or choice.
///
/// Sign-up payload, validation rules, the username fallback and routes are
/// unchanged.
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
  String _selectedRole = 'creator';

  static const _roles = ['creator', 'brand'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _handleController.dispose();
    super.dispose();
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
      showGlassSnackBar(
        context,
        message: authState.errorMessage!,
        tone: GlassToastTone.error,
      );
    } else if (authState.isAuthenticated) {
      showGlassSnackBar(
        context,
        message: 'Account created!',
        tone: GlassToastTone.success,
      );
      context.go(AppRoutes.home);
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
              vertical: AppSpacing.xl,
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
                      'Create your account',
                      style: AppTextStyles.title2
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sign up to get started',
                      style: AppTextStyles.footnote
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    AppSpacing.gapXl,

                    GlassTextField(
                      controller: _nameController,
                      hint: 'Full name',
                      prefixIcon: AppIcons.user,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter name';
                        return null;
                      },
                    ),
                    AppSpacing.gapMd,

                    GlassTextField(
                      controller: _emailController,
                      hint: 'Email',
                      prefixIcon: AppIcons.sms,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter email';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    AppSpacing.gapMd,

                    GlassTextField(
                      controller: _handleController,
                      hint: 'Username',
                      prefixIcon: AppIcons.user_tag,
                      prefixText: '@',
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Choose a username';
                        }
                        if (v.trim().length < 3) return 'Min 3 characters';
                        return null;
                      },
                    ),
                    AppSpacing.gapMd,

                    GlassTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      prefixIcon: AppIcons.lock,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter password';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                    AppSpacing.gapLg,

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          bottom: AppSpacing.sm,
                        ),
                        child: Text(
                          'I am a',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    GlassTabBar(
                      labels: const ['Creator', 'Brand'],
                      selectedIndex: _roles.indexOf(_selectedRole),
                      onSelected: (i) =>
                          setState(() => _selectedRole = _roles[i]),
                      margin: EdgeInsets.zero,
                    ),
                    AppSpacing.gapLg,

                    GlassButton(
                      label: 'Sign up',
                      loading: authState.isLoading,
                      onPressed: authState.isLoading ? null : _handleSignUp,
                      size: GlassButtonSize.large,
                    ),
                    AppSpacing.gapMd,

                    GlassButton.glass(
                      label: 'I already have an account',
                      onPressed: () => context.go(AppRoutes.login),
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

