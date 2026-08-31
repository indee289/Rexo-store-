import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
// unused import kept for API compatibility - replaced with custom header
// ignore: unused_import
import '../../../services/supabase_service.dart';
class TwoFactorAuthScreen extends ConsumerStatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  ConsumerState<TwoFactorAuthScreen> createState() =>
      _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends ConsumerState<TwoFactorAuthScreen> {
  bool _isLoading = true;
  bool _isMfaEnabled = false;
  bool _isEnrolling = false;
  bool _isVerifying = false;
  bool _isUnenrolling = false;

  String? _qrCodeUrl;
  String? _otpAuthUri;
  String? _secret;
  String? _factorId;
  String? _challengeId;
  String? _enrolledFactorId;
  String? _errorMessage;

  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkMfaStatus();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  /// The string encoded into the scannable QR image.
  ///
  /// Supabase returns `totp.uri` as a proper `otpauth://` URI which is exactly
  /// what authenticator apps expect. If it is missing we synthesise a standard
  /// otpauth URI from the shared secret so enrollment still works. We never
  /// feed Supabase's `totp.qrCode` (a raw SVG string) into an image loader —
  /// doing so crashed the screen because Image.network throws synchronously on
  /// a non-URL string, and errorBuilder only catches async load failures.
  String? get _qrData {
    if (_otpAuthUri != null && _otpAuthUri!.isNotEmpty) return _otpAuthUri;
    if (_secret != null && _secret!.isNotEmpty) {
      final account = SupabaseService.currentUser?.email ?? 'account';
      return 'otpauth://totp/Rexo:$account'
          '?secret=$_secret&issuer=Rexo&algorithm=SHA1&digits=6&period=30';
    }
    return null;
  }

  Future<void> _checkMfaStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final factors = await SupabaseService.client.auth.mfa.listFactors();
      final totpFactors = factors.totp;

      if (!mounted) return;

      if (totpFactors.isNotEmpty) {
        // Check for verified factors
        final verifiedFactors = totpFactors
            .where((f) => f.status == FactorStatus.verified)
            .toList();
        if (verifiedFactors.isNotEmpty) {
          setState(() {
            _isMfaEnabled = true;
            _enrolledFactorId = verifiedFactors.first.id;
          });
        } else {
          // Has unverified factors, clean state
          setState(() => _isMfaEnabled = false);
        }
      } else {
        setState(() => _isMfaEnabled = false);
      }
    } catch (e) {
      // Never rethrow: keep the screen self-contained so an MFA lookup
      // failure shows inline error UI instead of bubbling to the router
      // (which would otherwise bounce the user away from this screen).
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to check MFA status: ${e.toString()}';
        });
      }
    } finally {
      // Always leave loading state so the screen never spins forever.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _enrollMfa() async {
    setState(() {
      _isEnrolling = true;
      _errorMessage = null;
    });

    try {
      // Supabase requires an `issuer` for TOTP factors (and a unique
      // friendlyName per user). Without `issuer` enroll fails with
      // "expected an issuer for totp factor type". The timestamped
      // friendlyName avoids "factor already exists" on retry.
      final response = await SupabaseService.client.auth.mfa.enroll(
        factorType: FactorType.totp,
        issuer: 'Rexo',
        friendlyName: 'Rexo ${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      setState(() {
        _factorId = response.id;
        _qrCodeUrl = response.totp?.qrCode;
        _otpAuthUri = response.totp?.uri;
        _secret = response.totp?.secret;
        _isEnrolling = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEnrolling = false;
        _errorMessage = 'Failed to enroll MFA: ${e.toString()}';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty || code.length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final challengeResponse =
          await SupabaseService.client.auth.mfa.challenge(
        factorId: _factorId!,
      );
      _challengeId = challengeResponse.id;

      await SupabaseService.client.auth.mfa.verify(
        factorId: _factorId!,
        challengeId: _challengeId!,
        code: code,
      );

      if (!mounted) return;

      setState(() {
        _isMfaEnabled = true;
        _enrolledFactorId = _factorId;
        _qrCodeUrl = null;
        _otpAuthUri = null;
        _secret = null;
        _factorId = null;
        _challengeId = null;
        _isVerifying = false;
      });

      _otpController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-factor authentication enabled successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Verification failed: ${e.toString()}';
      });
    }
  }

  Future<void> _unenrollMfa() async {
    if (_enrolledFactorId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable 2FA'),
        content: const Text(
          'Are you sure you want to disable two-factor authentication? '
          'This will make your account less secure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUnenrolling = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.client.auth.mfa.unenroll(
        _enrolledFactorId!,
      );

      if (!mounted) return;

      setState(() {
        _isMfaEnabled = false;
        _enrolledFactorId = null;
        _isUnenrolling = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-factor authentication disabled'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUnenrolling = false;
        _errorMessage = 'Failed to disable 2FA: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom dark header ──────────────────────────────────────────
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(
                  bottom: BorderSide(color: AppColors.darkBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: AppRadius.allSm,
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(
                        Iconsax.arrow_left,
                        size: 18,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Two-Factor Auth',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h5.copyWith(
                        color: AppColors.darkTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status card with shield icon
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: _isMfaEnabled
                                        ? AppColors.success.withOpacity(0.12)
                                        : AppColors.primary.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isMfaEnabled
                                          ? AppColors.success
                                              .withOpacity(0.3)
                                          : AppColors.primary
                                              .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    _isMfaEnabled
                                        ? Iconsax.shield_tick
                                        : Iconsax.shield_cross,
                                    size: 44,
                                    color: _isMfaEnabled
                                        ? AppColors.success
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'Two-Factor Authentication',
                                  style: AppTextStyles.h4.copyWith(
                                    color: AppColors.darkTextPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xs + 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isMfaEnabled
                                        ? AppColors.success.withOpacity(0.12)
                                        : AppColors.darkSurfaceAlt,
                                    borderRadius: AppRadius.pillAll,
                                    border: Border.all(
                                      color: _isMfaEnabled
                                          ? AppColors.success
                                              .withOpacity(0.3)
                                          : AppColors.darkBorder,
                                    ),
                                  ),
                                  child: Text(
                                    _isMfaEnabled ? 'Enabled' : 'Disabled',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _isMfaEnabled
                                          ? AppColors.success
                                          : AppColors.darkTextSecondary,
                                    ),
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
                                border: Border.all(
                                  color: AppColors.error.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Iconsax.warning_2,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl - 4),
                          ],

                          if (_isMfaEnabled && _qrCodeUrl == null)
                            _buildEnabledView()
                          else if (_qrCodeUrl != null)
                            _buildEnrollmentView()
                          else
                            _buildDisabledView(),

                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefits of 2FA',
          style: AppTextStyles.h6.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildBenefitItem(
          icon: Iconsax.shield_tick,
          title: 'Prevents unauthorized access',
          description:
              'Even if your password is compromised, attackers cannot access your account without the second factor.',
        ),
        _buildBenefitItem(
          icon: Iconsax.wallet_3,
          title: 'Required for large withdrawals',
          description:
              'Wallet withdrawals above a certain threshold will require 2FA verification for added security.',
        ),
        _buildBenefitItem(
          icon: Iconsax.lock,
          title: 'Protects sensitive account changes',
          description:
              'Email changes, password resets, and other critical actions will need 2FA confirmation.',
        ),
        _buildBenefitItem(
          icon: Iconsax.verify,
          title: 'Industry-standard security',
          description:
              'TOTP-based authentication works with Google Authenticator, Authy, and other authenticator apps.',
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.allMd,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isEnrolling ? null : _enrollMfa,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.allMd),
              ),
              icon: _isEnrolling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Iconsax.shield_tick,
                      color: Colors.white, size: 18),
              label: Text(
                _isEnrolling
                    ? 'Setting up...'
                    : 'Enable Two-Factor Authentication',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Scan QR Code',
          style: AppTextStyles.h6.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Open your authenticator app and scan this QR code:',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.darkTextSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: _qrData != null
                ? QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  )
                : Container(
                    width: 200,
                    height: 200,
                    alignment: Alignment.center,
                    child: Text(
                      'QR unavailable\nUse the manual key below',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ),
          ),
        ),
        if (_secret != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: AppRadius.allSm,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual entry key:',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  _secret!,
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Step 2: Enter Verification Code',
          style: AppTextStyles.h6.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Enter the 6-digit code from your authenticator app:',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.darkTextSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 10,
            color: AppColors.darkTextPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: GoogleFonts.robotoMono(
              fontSize: 28,
              color: AppColors.darkTextHint,
              letterSpacing: 10,
            ),
            filled: true,
            fillColor: AppColors.darkCard,
            border: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: const BorderSide(color: AppColors.darkBorder),
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
        const SizedBox(height: AppSpacing.xl - 4),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.allMd,
            ),
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.allMd),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Verify and Enable',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _qrCodeUrl = null;
                _otpAuthUri = null;
                _secret = null;
                _factorId = null;
                _errorMessage = null;
              });
              _otpController.clear();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkTextSecondary,
              side: const BorderSide(color: AppColors.darkBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.allMd),
            ),
            child: Text(
              'Cancel Setup',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnabledView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.shield_tick,
                  color: AppColors.success, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Two-Factor Authentication is Active',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your account is protected with an additional layer of security.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isUnenrolling ? null : _unenrollMfa,
            icon: _isUnenrolling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : const Icon(Iconsax.shield_cross),
            label: Text(
              _isUnenrolling
                  ? 'Disabling...'
                  : 'Disable Two-Factor Authentication',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.allMd,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.darkTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
