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
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../services/supabase_service.dart';

/// Two-factor auth — rebuilt layout.
///
/// Old layout: a hand-assembled fake app bar (a `Container` with an
/// `IconButton` and a centred `Text`), then one long `SingleChildScrollView`
/// in which the status card, the error banner, the benefit rows, the QR frame
/// and the manual-key block were each a bespoke `Container` with its own
/// `BoxDecoration`, and the actions were raw `ElevatedButton`s and
/// `OutlinedButton`s. Disabling 2FA went through an `AlertDialog`. The screen
/// also carried a parallel set of dark-mode colour getters.
///
/// New layout: the standard collapsing large title; the status reduced to one
/// card with a state chip; the three selling points turned into a grouped
/// section instead of hand-built rows; the enrolment flow laid out as two
/// explicitly numbered steps with the QR on its own card and the manual key in
/// a copyable block; and every action now a `GlassButton`. The disable
/// confirmation is a glass confirm dialog. The dark-mode getters are gone —
/// the app is light mode only.
///
/// Note the one deliberate departure from the usual screen pattern: the
/// primary action is **not** a pinned pill here, because this screen has three
/// mutually exclusive states with different primary actions, and pinning one
/// of them would leave the other two stranded. Each state owns its own
/// full-width action at the end of its block.
///
/// Every Supabase MFA call — `listFactors`, `enroll`, `challenge`, `verify`,
/// `unenroll` — along with the factor/challenge bookkeeping and the
/// `otpauth://` URI construction, is unchanged.
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

  String? get _qrData {
    if (_otpAuthUri != null && _otpAuthUri!.isNotEmpty) return _otpAuthUri;
    if (_secret != null && _secret!.isNotEmpty) {
      final account = SupabaseService.currentUser?.email ?? 'account';
      return 'otpauth://totp/Campster:$account'
          '?secret=$_secret&issuer=Campster&algorithm=SHA1&digits=6&period=30';
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
        issuer: 'Campster',
        friendlyName: 'Campster ${DateTime.now().millisecondsSinceEpoch}',
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
      final challengeResponse = await SupabaseService.client.auth.mfa.challenge(
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
        showGlassSnackBar(
          context,
          message: 'Two-factor authentication enabled!',
          tone: GlassToastTone.success,
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

    final confirmed = await showGlassConfirm(
      context: context,
      title: 'Disable 2FA',
      message: 'Are you sure you want to disable two-factor authentication?',
      icon: AppIcons.shield_cross,
      confirmLabel: 'Disable',
      destructive: true,
    );

    if (!confirmed) return;

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
        showGlassSnackBar(
          context,
          message: 'Two-factor authentication disabled',
          tone: GlassToastTone.warning,
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

  /// Cancels an in-progress enrolment and clears the setup state.
  void _cancelSetup() {
    setState(() {
      _qrCodeUrl = null;
      _otpAuthUri = null;
      _secret = null;
      _factorId = null;
      _errorMessage = null;
    });
    _otpController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(
            title: 'Two-factor auth',
            subtitle: 'An extra step when signing in',
            showBack: true,
            onBack: () => context.pop(),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: GlassLoader())
          else
            ..._contentSlivers(),
        ],
      ),
    );
  }

  List<Widget> _contentSlivers() {
    return [
      // Current state, always first.
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: _buildStatusCard(),
        ),
      ),

      if (_errorMessage != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: _buildErrorBanner(_errorMessage!),
          ),
        ),

      if (_isMfaEnabled && _qrCodeUrl == null)
        ..._enabledSlivers()
      else if (_qrCodeUrl != null || _factorId != null)
        ..._enrollmentSlivers()
      else
        ..._disabledSlivers(),

      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
    ];
  }

  Widget _buildStatusCard() {
    final on = _isMfaEnabled;
    return GlassCard(
      rim: on ? AppColors.success.withOpacity(0.28) : null,
      child: Row(
        children: [
          GlassIconBubble(
            icon: on ? AppIcons.shield_tick : AppIcons.shield_cross,
            color: on ? AppColors.success : AppColors.primary,
            size: 44,
            iconSize: 22,
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Two-factor auth',
                  style: AppTextStyles.headline
                      .copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  on ? 'Your account is protected' : 'Protect your account',
                  style: AppTextStyles.footnote
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          GlassChip.status(
            label: on ? 'Enabled' : 'Disabled',
            color: on ? AppColors.success : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  /// Inline, persistent error. Kept as a banner rather than a toast because it
  /// explains why the step in front of the user failed.
  Widget _buildErrorBanner(String message) {
    return GlassCard(
      rim: AppColors.error.withOpacity(0.30),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.warning_2, color: AppColors.error, size: 19),
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

  // ── Disabled ────────────────────────────────────────────────────────────

  List<Widget> _disabledSlivers() {
    return [
      SliverToBoxAdapter(
        child: GlassSection(
          title: 'Why turn it on',
          children: const [
            GlassRow(
              icon: AppIcons.shield_tick,
              title: 'Prevents unauthorised access',
              subtitle:
                  'Extra protection even if your password is compromised.',
              showChevron: false,
            ),
            GlassRow(
              icon: AppIcons.wallet_3,
              title: 'Required for large withdrawals',
              subtitle:
                  'Wallet withdrawals above threshold need 2FA verification.',
              showChevron: false,
            ),
            GlassRow(
              icon: AppIcons.verify,
              title: 'Industry-standard security',
              subtitle:
                  'Works with Google Authenticator, Authy, and other apps.',
              showChevron: false,
            ),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GlassButton(
            label: _isEnrolling
                ? 'Setting up…'
                : 'Enable two-factor authentication',
            icon: AppIcons.shield_tick,
            size: GlassButtonSize.large,
            loading: _isEnrolling,
            onPressed: _isEnrolling ? null : _enrollMfa,
          ),
        ),
      ),
    ];
  }

  // ── Enrolment ───────────────────────────────────────────────────────────

  List<Widget> _enrollmentSlivers() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _stepHeading(1, 'Scan the QR code',
                  'Open your authenticator app and scan this code.'),
              AppSpacing.gapLg,
              Center(child: _buildQrCard()),
              if (_secret != null) ...[
                AppSpacing.gapLg,
                _buildManualKey(_secret!),
              ],
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _stepHeading(2, 'Enter the verification code',
                  'Type the 6-digit code from your authenticator app.'),
              AppSpacing.gapLg,
              _buildOtpField(),
              AppSpacing.gapXl,
              GlassButton(
                label: 'Verify & enable',
                icon: AppIcons.tick_circle,
                size: GlassButtonSize.large,
                loading: _isVerifying,
                onPressed: _isVerifying ? null : _verifyOtp,
              ),
              AppSpacing.gapMd,
              GlassButton.outline(
                label: 'Cancel setup',
                onPressed: _isVerifying ? null : _cancelSetup,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  /// A numbered step heading — the enrolment flow is explicitly sequential.
  Widget _stepHeading(int step, String title, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        AppSpacing.gapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.headline
                    .copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: AppTextStyles.footnote
                    .copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The QR frame stays explicitly white with black modules: scanners need the
  /// contrast, so this one surface must not pick up the warm canvas tint.
  Widget _buildQrCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.card(false),
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
                child: Text(
                  'QR unavailable\nUse the manual key below',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.footnote
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
    );
  }

  Widget _buildManualKey(String secret) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const GlassIconBubble(
            icon: AppIcons.key,
            size: 36,
            iconSize: 18,
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Manual entry key',
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  secret,
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Six-digit code input.
  ///
  /// Hand-built rather than a `GlassTextField` because it needs centred,
  /// wide-tracked monospace digits, which the shared field deliberately does
  /// not expose. The well matches the shared field's recessed treatment.
  Widget _buildOtpField() {
    return GlassSurface(
      level: GlassLevel.subtle,
      borderRadius: AppRadius.allMd,
      child: TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: GoogleFonts.robotoMono(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 10,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          counterText: '',
          hintText: '000000',
          hintStyle: GoogleFonts.robotoMono(
            fontSize: 28,
            letterSpacing: 10,
            color: AppColors.textHint,
          ),
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

  // ── Enabled ─────────────────────────────────────────────────────────────

  List<Widget> _enabledSlivers() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: GlassCard(
            rim: AppColors.success.withOpacity(0.30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlassIconBubble(
                  icon: AppIcons.shield_tick,
                  color: AppColors.success,
                  size: 40,
                  iconSize: 20,
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Two-factor authentication is active',
                        style: AppTextStyles.headline
                            .copyWith(color: AppColors.success),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your account is protected with an additional layer.',
                        style: AppTextStyles.footnote.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GlassButton.destructive(
            label: _isUnenrolling ? 'Disabling…' : 'Disable 2FA',
            icon: AppIcons.shield_cross,
            size: GlassButtonSize.large,
            loading: _isUnenrolling,
            onPressed: _isUnenrolling ? null : _unenrollMfa,
          ),
        ),
      ),
    ];
  }
}
