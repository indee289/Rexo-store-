import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_utils.dart';
// unused import kept for API compatibility - replaced with custom header
// ignore: unused_import
import '../../../services/supabase_service.dart';

class TwoFactorAuthScreen extends ConsumerStatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  ConsumerState<TwoFactorAuthScreen> createState() =>
      _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState
    extends ConsumerState<TwoFactorAuthScreen> {
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

  // ── Theme-aware helpers ──────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  ColorScheme get _cs => Theme.of(context).colorScheme;
  Color get _pageBg =>
      _isDark ? AppColors.darkBackground : AppColors.background;
  Color get _cardBg => _isDark ? AppColors.darkCard : Colors.white;
  Color get _borderColor =>
      _isDark ? AppColors.darkBorder : AppColors.border;
  Color get _surfaceAlt =>
      _isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
  Color get _textHint => _isDark ? AppColors.darkTextHint : AppColors.textHint;

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
        final verifiedFactors = totpFactors
            .where((f) => f.status == FactorStatus.verified)
            .toList();
        if (verifiedFactors.isNotEmpty) {
          setState(() {
            _isMfaEnabled = true;
            _enrolledFactorId = verifiedFactors.first.id;
          });
        } else {
          setState(() => _isMfaEnabled = false);
        }
      } else {
        setState(() => _isMfaEnabled = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ErrorUtils.sanitize(e);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enrollMfa() async {
    setState(() {
      _isEnrolling = true;
      _errorMessage = null;
    });

    try {
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
        _errorMessage = ErrorUtils.sanitize(e);
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
            content: Text('Two-factor authentication enabled!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = "That code didn't work. Please try again.";
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
          'Are you sure you want to disable two-factor authentication?',
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
      await SupabaseService.client.auth.mfa.unenroll(_enrolledFactorId!);

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
        _errorMessage = ErrorUtils.sanitize(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ────────────────────────────────────────────────────
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              color: _pageBg,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Iconsax.arrow_left,
                        size: 24, color: _cs.onSurface),
                  ),
                  Expanded(
                    child: Text(
                      'Two-Factor Auth',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
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
                          // Status card
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: AppRadius.allLg,
                              border: Border.all(color: _borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _isMfaEnabled
                                        ? AppColors.success.withOpacity(0.12)
                                        : AppColors.primary.withOpacity(0.12),
                                    borderRadius: AppRadius.allSm,
                                  ),
                                  child: Icon(
                                    _isMfaEnabled
                                        ? Iconsax.shield_tick
                                        : Iconsax.shield_cross,
                                    size: 22,
                                    color: _isMfaEnabled
                                        ? AppColors.success
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Two-Factor Auth',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _cs.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'Protect your account',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isMfaEnabled
                                        ? AppColors.success.withOpacity(0.12)
                                        : _surfaceAlt,
                                    borderRadius: AppRadius.pillAll,
                                  ),
                                  child: Text(
                                    _isMfaEnabled ? 'Enabled' : 'Disabled',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isMfaEnabled
                                          ? AppColors.success
                                          : _cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Error message
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.08),
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
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          if (_isMfaEnabled && _qrCodeUrl == null)
                            _buildEnabledView()
                          else if (_qrCodeUrl != null || _factorId != null)
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Benefits
        _benefitItem(
          icon: Iconsax.shield_tick,
          title: 'Prevents unauthorized access',
          desc: 'Extra protection even if your password is compromised.',
        ),
        _benefitItem(
          icon: Iconsax.wallet_3,
          title: 'Required for large withdrawals',
          desc: 'Wallet withdrawals above threshold need 2FA verification.',
        ),
        _benefitItem(
          icon: Iconsax.verify,
          title: 'Industry-standard security',
          desc:
              'Works with Google Authenticator, Authy, and other apps.',
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isEnrolling ? null : _enrollMfa,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.allMd),
            ),
            icon: _isEnrolling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Iconsax.shield_tick, size: 18),
            label: Text(
              _isEnrolling
                  ? 'Setting up...'
                  : 'Enable Two-Factor Authentication',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _benefitItem(
      {required IconData icon,
      required String title,
      required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _cs.onSurface,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: _cs.onSurfaceVariant,
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

  Widget _buildEnrollmentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Scan QR Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Open your authenticator app and scan this QR code:',
          style: TextStyle(fontSize: 14, color: _cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        // QR code — kept on a white card so it always scans (even in dark mode)
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: AppColors.border),
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
                : SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: const Text(
                        'QR unavailable\nUse the manual key below',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
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
              color: _surfaceAlt,
              borderRadius: AppRadius.allSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual entry key:',
                  style: TextStyle(
                    fontSize: 12,
                    color: _cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  _secret!,
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        Text(
          'Step 2: Enter Verification Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code from your authenticator app:',
          style: TextStyle(fontSize: 14, color: _cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 10,
            color: _cs.onSurface,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: GoogleFonts.robotoMono(
              fontSize: 28,
              color: _textHint,
              letterSpacing: 10,
            ),
            filled: true,
            fillColor: _surfaceAlt,
            border: const OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide: BorderSide.none,
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.allMd,
              borderSide:
                  BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isVerifying ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.allMd),
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text(
                    'Verify & Enable',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
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
              foregroundColor: _cs.onSurfaceVariant,
              side: BorderSide(color: _borderColor),
              minimumSize: const Size(double.infinity, 46),
              shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.allMd),
            ),
            child: const Text('Cancel setup'),
          ),
        ),
      ],
    );
  }

  Widget _buildEnabledView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.06),
            borderRadius: AppRadius.allMd,
            border: Border.all(
                color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.shield_tick,
                  color: AppColors.success, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Two-Factor Authentication is Active',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your account is protected with an additional layer.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _cs.onSurfaceVariant,
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
          child: OutlinedButton.icon(
            onPressed: _isUnenrolling ? null : _unenrollMfa,
            icon: _isUnenrolling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.error))
                : const Icon(Iconsax.shield_cross, size: 18),
            label: Text(
              _isUnenrolling ? 'Disabling...' : 'Disable 2FA',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 52),
              shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.allMd),
            ),
          ),
        ),
      ],
    );
  }
}
