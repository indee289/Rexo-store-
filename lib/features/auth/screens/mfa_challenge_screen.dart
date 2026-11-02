import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../services/supabase_service.dart';
import '../providers/auth_provider.dart';

/// Login-time MFA (TOTP) challenge — liquid glass.
///
/// Reached when [AuthStatus.mfaRequired] — i.e. the password step succeeded but
/// the session is still at AAL1 while a verified TOTP factor exists. The user
/// must enter a 6-digit code from their authenticator app to elevate the
/// session to AAL2 before they can access the app.
///
/// The challenge logic (factor lookup, challenge creation, verify, re-arm on
/// failure, cancel-signs-out) is unchanged. Only the presentation moved to
/// glass: the code entry is a wide recessed glass well with tracked-out
/// digits, and the inline error is a red-rimmed glass banner.
class MfaChallengeScreen extends ConsumerStatefulWidget {
  const MfaChallengeScreen({super.key});

  @override
  ConsumerState<MfaChallengeScreen> createState() => _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends ConsumerState<MfaChallengeScreen> {
  final _otpController = TextEditingController();

  bool _isPreparing = true;
  bool _isVerifying = false;
  bool _isCancelling = false;
  String? _factorId;
  String? _challengeId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prepareChallenge();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  /// List the user's factors, pick the first VERIFIED TOTP factor and create a
  /// challenge for it. Errors are shown inline — never rethrown — so a lookup
  /// failure can't bounce the user out of this screen.
  Future<void> _prepareChallenge() async {
    setState(() {
      _isPreparing = true;
      _errorMessage = null;
    });

    try {
      final factors = await SupabaseService.client.auth.mfa.listFactors();
      final verified = factors.totp
          .where((f) => f.status == FactorStatus.verified)
          .toList();

      if (verified.isEmpty) {
        // No verified factor after all — nothing to challenge. Let the user
        // straight through so they are never stuck here.
        if (!mounted) return;
        ref.read(authProvider.notifier).completeMfa();
        if (mounted) context.go(AppRoutes.home);
        return;
      }

      final factorId = verified.first.id;
      final challenge =
          await SupabaseService.client.auth.mfa.challenge(factorId: factorId);

      if (!mounted) return;
      setState(() {
        _factorId = factorId;
        _challengeId = challenge.id;
        _isPreparing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPreparing = false;
        _errorMessage = 'Could not start verification. Please try again.';
      });
    }
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit code');
      return;
    }

    // If the challenge could not be prepared, try again before verifying.
    if (_factorId == null || _challengeId == null) {
      await _prepareChallenge();
      if (_factorId == null || _challengeId == null) return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.client.auth.mfa.verify(
        factorId: _factorId!,
        challengeId: _challengeId!,
        code: code,
      );

      if (!mounted) return;

      // Session is now elevated to AAL2 — mark the account authenticated and
      // proceed to home.
      ref.read(authProvider.notifier).completeMfa();
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        // A fresh challenge is needed after a failed verify attempt.
        _challengeId = null;
        _errorMessage = 'Verification failed. Please try a new code.';
      });
      // Re-arm a challenge in the background so the next attempt is ready.
      _prepareChallenge();
    }
  }

  /// Cancel the challenge: sign out (drops the half-finished AAL1 session) and
  /// return to the login screen.
  Future<void> _cancel() async {
    setState(() => _isCancelling = true);
    try {
      await ref.read(authProvider.notifier).signOut();
    } catch (_) {
      // Ignore — we navigate to login regardless.
    }
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: 'Two-Factor Verification',
        showBack: false,
        automaticallyImplyLeading: false,
        actions: [
          GlassButton.ghost(
            label: 'Cancel',
            onPressed: _isCancelling ? null : _cancel,
            size: GlassButtonSize.small,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          borderRadius: AppRadius.allXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: GlassIconBubble(
                  icon: Iconsax.shield_tick,
                  size: 72,
                  iconSize: 34,
                ),
              ),
              AppSpacing.gapLg,
              Text(
                'Enter verification code',
                textAlign: TextAlign.center,
                style: AppTextStyles.title2
                    .copyWith(color: AppColors.textPrimary),
              ),
              AppSpacing.gapSm,
              Text(
                'Open your authenticator app and enter the 6-digit code to '
                'finish signing in.',
                textAlign: TextAlign.center,
                style: AppTextStyles.subheadline.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              AppSpacing.gapXl,

              if (_errorMessage != null) ...[
                _ErrorBanner(message: _errorMessage!),
                AppSpacing.gapLg,
              ],

              if (_isPreparing) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: GlassLoader(message: 'Starting verification'),
                ),
              ] else ...[
                _CodeField(
                  controller: _otpController,
                  onSubmitted: () {
                    if (!_isVerifying) _verify();
                  },
                ),
                AppSpacing.gapLg,
                GlassButton(
                  label: 'Verify',
                  loading: _isVerifying,
                  onPressed: _isVerifying ? null : _verify,
                  size: GlassButtonSize.large,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Wide recessed glass well for the 6-digit code, with heavy letter tracking
/// so the digits read as a code rather than ordinary text.
class _CodeField extends StatefulWidget {
  const _CodeField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  State<_CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<_CodeField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focused != _focusNode.hasFocus) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digitStyle = AppTextStyles.title1.copyWith(
      letterSpacing: 10,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: _focused ? AppColors.primaryRim : AppColors.border,
          width: _focused ? 1.4 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
              ]
            : const [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 6,
        textAlign: TextAlign.center,
        autofocus: true,
        onSubmitted: (_) => widget.onSubmitted(),
        style: digitStyle,
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          counterText: '',
          hintText: '000000',
          hintStyle: digitStyle.copyWith(color: AppColors.textHint),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
        ),
      ),
    );
  }
}

/// Red-rimmed glass banner for the inline challenge error.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.10),
        borderRadius: AppRadius.allSm,
        border: Border.all(color: AppColors.error.withOpacity(0.32), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, color: AppColors.error, size: 18),
          AppSpacing.gapSm,
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.footnote.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
