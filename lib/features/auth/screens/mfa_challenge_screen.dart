import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
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
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isCancelling ? null : _cancel,
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                  const SizedBox(height: 16),
                  Text(
                    'Enter Verification Code',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open your authenticator app and enter the 6-digit code to '
                    'finish signing in.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.warning_2,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_isPreparing) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // OTP field (mirrors the enrollment verify step's styling).
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                onSubmitted: (_) {
                  if (!_isVerifying) _verify();
                },
                style: GoogleFonts.robotoMono(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: GoogleFonts.robotoMono(
                    fontSize: 24,
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    letterSpacing: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Verify',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
