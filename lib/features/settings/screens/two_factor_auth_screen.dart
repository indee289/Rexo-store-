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
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Two-Factor Authentication',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
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
                            color: _isMfaEnabled
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isMfaEnabled
                                ? Iconsax.shield_tick
                                : Iconsax.shield_cross,
                            size: 40,
                            color: _isMfaEnabled
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Two-Factor Authentication',
                          style: AppTextStyles.h3.copyWith(
                            color: theme.colorScheme.onSurface,
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
                                ? AppColors.success.withOpacity(0.1)
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.05),
                            borderRadius: AppRadius.pillAll,
                          ),
                          child: Text(
                            _isMfaEnabled ? 'Enabled' : 'Disabled',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _isMfaEnabled
                                  ? AppColors.success
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.6),
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

                  // MFA enabled state - show disable option
                  if (_isMfaEnabled && _qrCodeUrl == null) ...[
                    _buildEnabledView(theme),
                  ]
                  // Enrollment in progress - show QR code and verification
                  else if (_qrCodeUrl != null) ...[
                    _buildEnrollmentView(theme),
                  ]
                  // MFA not enabled - show enable option
                  else ...[
                    _buildDisabledView(theme),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
    );
  }

  Widget _buildDisabledView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Benefits section
        Text(
          'Benefits of 2FA',
          style: AppTextStyles.h6.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildBenefitItem(
          theme,
          icon: Iconsax.shield_tick,
          title: 'Prevents unauthorized access',
          description:
              'Even if your password is compromised, attackers cannot access your account without the second factor.',
        ),
        _buildBenefitItem(
          theme,
          icon: Iconsax.wallet_3,
          title: 'Required for large withdrawals',
          description:
              'Wallet withdrawals above a certain threshold will require 2FA verification for added security.',
        ),
        _buildBenefitItem(
          theme,
          icon: Iconsax.lock,
          title: 'Protects sensitive account changes',
          description:
              'Email changes, password resets, and other critical actions will need 2FA confirmation.',
        ),
        _buildBenefitItem(
          theme,
          icon: Iconsax.verify,
          title: 'Industry-standard security',
          description:
              'TOTP-based authentication works with Google Authenticator, Authy, and other authenticator apps.',
        ),

        const SizedBox(height: AppSpacing.xl),

        // Enable button
        PremiumButton(
          label: _isEnrolling
              ? 'Setting up...'
              : 'Enable Two-Factor Authentication',
          icon: Iconsax.shield_tick,
          loading: _isEnrolling,
          onPressed: _isEnrolling ? null : _enrollMfa,
        ),
      ],
    );
  }

  Widget _buildEnrollmentView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step 1: QR Code
        Text(
          'Step 1: Scan QR Code',
          style: AppTextStyles.h6.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Open your authenticator app (Google Authenticator, Authy, etc.) and scan this QR code:',
          style: AppTextStyles.bodySmall.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // QR Code display
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: theme.dividerColor),
            ),
            child: _qrData != null
                ? QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    // Keep QR modules black on the white card so any
                    // authenticator app can scan it in both themes.
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
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Manual secret key
        if (_secret != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.allSm,
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual entry key:',
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  _secret!,
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // Step 2: Enter code
        Text(
          'Step 2: Enter Verification Code',
          style: AppTextStyles.h6.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Enter the 6-digit code from your authenticator app:',
          style: AppTextStyles.bodySmall.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 8,
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
              borderRadius: AppRadius.allMd,
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl - 4),

        // Verify button
        PremiumButton(
          label: 'Verify and Enable',
          loading: _isVerifying,
          onPressed: _isVerifying ? null : _verifyOtp,
        ),

        const SizedBox(height: AppSpacing.md),

        // Cancel button
        PremiumButton(
          label: 'Cancel Setup',
          variant: PremiumButtonVariant.ghost,
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
        ),
      ],
    );
  }

  Widget _buildEnabledView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success message
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
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Disable button
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

  Widget _buildBenefitItem(
    ThemeData theme, {
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
              color: AppColors.primary.withOpacity(0.1),
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
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
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
