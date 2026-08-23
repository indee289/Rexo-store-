import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_service.dart';

/// Animated brand splash shown once on cold start.
///
/// Flow: app open -> this splash (logo fades/scales in, then a dot morphs into
/// a full-screen circle reveal) -> navigates straight to Home (if a valid
/// session exists) or Login (otherwise). No taps, no extra/second splash, and
/// no flicker (the router is never recreated on auth change).
///
/// Background is the brand orange.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  bool _isDotCenter = false;
  bool _isScaleCircle = false;

  late final AnimationController _fadeInController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;

  Timer? _startTimer;
  Timer? _animationTimer;
  Timer? _navigationTimer;

  /// Destination resolved (async) while the brand animation plays, so
  /// navigation at the end of the reveal is instant.
  String _target = AppRoutes.login;
  String? _blockedStatus;

  @override
  void initState() {
    super.initState();

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoFade = CurvedAnimation(
      parent: _fadeInController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeInController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _fadeInController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _fadeInController.forward();

    // Decide where to go while the brand moment plays (no artificial wait).
    _resolveDestination();

    _startTimer = Timer(const Duration(milliseconds: 1200), _startAnimation);
  }

  Future<void> _resolveDestination() async {
    if (!SupabaseService.isAuthenticated) {
      _target = AppRoutes.login;
      return;
    }
    // Authenticated: block banned/suspended accounts on next launch.
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
      // A status read failure must not block a legitimate launch.
      _target = AppRoutes.home;
    }
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _startTimer?.cancel();
    _animationTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    if (_isDotCenter || !mounted) return;

    setState(() => _isDotCenter = true);

    _animationTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isScaleCircle = true);

      _navigationTimer = Timer(const Duration(milliseconds: 600), () {
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
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Orange brand backdrop (radial gradient for depth).
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFFFF7A45),
                    Color(0xFFFF5722),
                    Color(0xFFE64A19),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: SizedBox.expand(),
            ),

            // Soft glow behind the logo mark.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 700),
              opacity: _isScaleCircle ? 0.0 : 1.0,
              child: Container(
                width: screenWidth * 0.7,
                height: screenWidth * 0.7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33FFFFFF),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Brand mark + name, fading/scaling in and out.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isDotCenter ? 0.0 : 1.0,
              child: FadeTransition(
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 24,
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
                            errorBuilder: (_, __, ___) => Text(
                              'R',
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Rexo',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Text(
                          'Connect. Create. Earn.',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Morph dot -> full-screen white circle reveal.
            Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 600),
                curve: const Cubic(0.58, -0.30, 0.365, 1),
                scale: _isScaleCircle ? 12.0 : 1.0,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: _isScaleCircle
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        _isScaleCircle ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: const Cubic(0.47, -1.26, 0.36, 1),
              left: (screenWidth / 2) - 12 - (_isDotCenter ? 0 : 80),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isScaleCircle ? 0.0 : 1.0,
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            // Subtle pulsing loading dots near the bottom.
            Positioned(
              bottom: screenHeight * 0.08,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isDotCenter ? 0.0 : 1.0,
                child: const _PulsingDots(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three dots that gently pulse in sequence — a premium loading touch.
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
                    color: Colors.white,
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
