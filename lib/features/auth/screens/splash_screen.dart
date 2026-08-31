import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_service.dart';

/// Brand splash — bold full-bleed green gradient with a glassy logo badge.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  Timer? _navTimer;
  String _target = AppRoutes.login;
  String? _blockedStatus;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    _resolveDestination();
    _navTimer = Timer(const Duration(milliseconds: 1800), _navigate);
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scaleIn,
                  child: Column(
                    children: [
                      // Glassy logo badge
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Iconsax.crown_1,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Rexo',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Creator Marketing Platform',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 56),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.9),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
