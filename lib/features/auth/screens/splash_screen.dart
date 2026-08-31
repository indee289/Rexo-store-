import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/supabase_service.dart';

/// Clean brand splash shown once on cold start.
///
/// Blue brand background, a single centered Rexo logo that fades/scales in, then
/// navigates straight to Home (valid session) or Login. No white reveal
/// circle, no duplicate logo, no extra splash, no flicker.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;

  Timer? _navTimer;
  String _target = AppRoutes.login;
  String? _blockedStatus;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();

    _resolveDestination();

    // Brief brand moment, then navigate — no artificial long delay.
    _navTimer = Timer(const Duration(milliseconds: 1600), _navigate);
  }

  Future<void> _resolveDestination() async {
    if (!SupabaseService.isAuthenticated) {
      _target = AppRoutes.login;
      return;
    }
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final profile = await SupabaseService.getUserProfile(user.id);
        final status = (profile?['account_status'] as String?)?.toLowerCase();
        if (status == 'banned' || status == 'suspended') {
          await SupabaseService.signOut();
          _blockedStatus = status;
          _target = AppRoutes.login;
          return;
        }
      }
      _target = AppRoutes.home;
    } catch (_) {
      _target = AppRoutes.home;
    }
  }

  void _navigate() {
    if (!mounted) return;
    if (_blockedStatus != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _blockedStatus == 'banned'
                ? 'Your account has been banned. Please contact support.'
                : 'Your account has been suspended. Please contact support.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
    context.go(_target);
  }

  @override
  void dispose() {
    _controller.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radial glow behind logo
            Positioned(
              top: screenHeight * 0.25,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.25),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Logo + wordmark
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppRadius.allXl,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 36,
                            spreadRadius: 6,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Iconsax.crown_1,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Rexo',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.darkTextPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Connect. Create. Earn.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.darkTextSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pulsing dots at the bottom
            Positioned(
              bottom: screenHeight * 0.08,
              child: const _PulsingDots(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three dots that gently pulse in sequence.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final t = (_controller.value - delay) % 1.0;
            final opacity =
                t < 0.5 ? 0.3 + (t * 2 * 0.7) : 0.3 + ((1 - t) * 2 * 0.7);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.darkTextSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
