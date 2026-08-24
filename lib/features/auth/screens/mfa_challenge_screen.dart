import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../services/supabase_service.dart';
import '../providers/auth_provider.dart';

/// Login-time MFA (TOTP) challenge.
///
/// Reached when [AuthStatus.mfaRequired] — i.e. the password step succeeded but
/// the session is still at AAL1 while a verified TOTP factor exists. The user
/// must enter a 6-digit code from their authenticator app to elevate the
/// session to AAL2 before they can access the app.
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
        _errorMessage =
            'Could not start verification. Please try again. (${e.toString()})';
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Two-Factor Verification',
          style: AppTextStyles.h5.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        automaticallyImplyLeading: false,
        actions: [
          PremiumButton(
            label: 'Cancel',
            variant: PremiumButtonVariant.ghost,
            expand: false,
            onPressed: _isCancelling ? null : _cancel,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.shield_tick,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Enter Verification Code',
                    style: AppTextStyles.h3.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Open your authenticator app and enter the 6-digit code to '
                    'finish signing in.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: AppRadius.allSm,
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.warning_2,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            if (_isPreparing) ...[
              const SizedBox(height: AppSpacing.xl),
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xl),
            ] else ...[
              // OTP field (token-driven, spaced digits for a code look).
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                onSubmitted: (_) {
                  if (!_isVerifying) _verify();
                },
                style: AppTextStyles.h3.copyWith(
                  letterSpacing: 8,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: AppTextStyles.h3.copyWith(
                    letterSpacing: 8,
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.allMd,
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.allMd,
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.allMd,
                    borderSide:
                        BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Verify button
              PremiumButton(
                label: 'Verify',
                gradient: true,
                loading: _isVerifying,
                onPressed: _isVerifying ? null : _verify,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
