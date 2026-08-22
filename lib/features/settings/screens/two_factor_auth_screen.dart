import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_service.dart';

class TwoFactorAuthScreen extends ConsumerStatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  ConsumerState<TwoFactorAuthScreen> createState() =>
      _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends ConsumerState<TwoFactorAuthScreen> {
  bool _isLoading = true;
  bool _isEnrolled = false;
  bool _isEnrolling = false;
  bool _mfaNotSupported = false;
  String? _qrCodeUrl;
  String? _secret;
  String? _factorId;
  String? _challengeId;
  final _otpController = TextEditingController();
  String? _errorMessage;

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

  Future<void> _checkMfaStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final factors = await SupabaseService.client.auth.mfa.listFactors();
      final totp = factors.totp;

      if (totp.isNotEmpty && totp.first.status == FactorStatus.verified) {
        setState(() {
          _isEnrolled = true;
          _factorId = totp.first.id;
        });
      } else {
        setState(() => _isEnrolled = false);
      }
    } catch (e) {
      // ANY error from MFA = treat as not supported
      // This prevents auth state changes from crashing the app
      setState(() => _mfaNotSupported = true);
    } finally {
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
      final response = await SupabaseService.client.auth.mfa.enroll(
        factorType: FactorType.totp,
        friendlyName: 'Rexo Authenticator',
      );

      setState(() {
        _qrCodeUrl = response.totp?.qrCode;
        _secret = response.totp?.secret;
        _factorId = response.id;
        _isEnrolling = false;
      });
    } catch (e) {
      // ANY error = MFA not supported, show coming soon
      setState(() {
        _mfaNotSupported = true;
        _isEnrolling = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter a 6-digit code');
      return;
    }

    setState(() {
      _isEnrolling = true;
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

      setState(() {
        _isEnrolled = true;
        _isEnrolling = false;
        _qrCodeUrl = null;
        _secret = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Two-factor authentication enabled!',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed. Please check the code and try again.';
        _isEnrolling = false;
      });
    }
  }

  Future<void> _unenrollMfa() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Disable 2FA',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to disable two-factor authentication? This will make your account less secure.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Disable',
              style: GoogleFonts.poppins(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || _factorId == null) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.client.auth.mfa.unenroll(_factorId!);
      setState(() {
        _isEnrolled = false;
        _factorId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Two-factor authentication disabled',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      setState(
          () => _errorMessage = 'Failed to disable 2FA. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Two-Factor Authentication',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _mfaNotSupported
              ? _buildComingSoon()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status card
                      _buildStatusCard(),
                      const SizedBox(height: 24),

                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.warning_2,
                                  color: AppColors.error, size: 20),
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
                        const SizedBox(height: 16),
                      ],

                      // QR Code enrollment flow
                      if (_qrCodeUrl != null) ...[
                        _buildEnrollmentFlow(),
                      ] else if (!_isEnrolled) ...[
                        _buildEnrollButton(),
                      ] else ...[
                        _buildUnenrollButton(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildComingSoon() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Two-factor authentication is not yet available for your account. '
              'We are working on enabling this feature. Please check back later.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (_isEnrolled ? AppColors.success : AppColors.warning)
            .withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_isEnrolled ? AppColors.success : AppColors.warning)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEnrolled ? Iconsax.shield_tick : Iconsax.shield_cross,
            color: _isEnrolled ? AppColors.success : AppColors.warning,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEnrolled ? '2FA is Enabled' : '2FA is Not Enabled',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isEnrolled
                      ? 'Your account is protected with TOTP authentication.'
                      : 'Add an extra layer of security to your account.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isEnrolling ? null : _enrollMfa,
        icon: _isEnrolling
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Iconsax.shield_tick),
        label: Text(
          'Enable Two-Factor Authentication',
          style:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildEnrollmentFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Scan QR Code',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Open your authenticator app (Google Authenticator, Authy, etc.) and scan the QR code below.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // QR Code display - show as SVG image from the URL
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: _qrCodeUrl != null
                ? Image.network(
                    _qrCodeUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.scan,
                              size: 40, color: AppColors.textHint),
                          const SizedBox(height: 8),
                          Text(
                            'QR Code',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 16),

        // Manual secret key
        if (_secret != null) ...[
          Text(
            'Or enter this key manually:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _secret!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _secret!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Secret key copied!')),
                    );
                  },
                  icon: const Icon(Iconsax.copy,
                      size: 20, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Step 2: Enter verification code
        Text(
          'Step 2: Enter Verification Code',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code from your authenticator app to complete setup.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: GoogleFonts.poppins(
              fontSize: 24,
              color: AppColors.textHint.withOpacity(0.4),
              letterSpacing: 8,
            ),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isEnrolling ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isEnrolling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Verify & Enable',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnenrollButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _unenrollMfa,
        icon: const Icon(Iconsax.shield_cross, color: AppColors.error),
        label: Text(
          'Disable Two-Factor Authentication',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
