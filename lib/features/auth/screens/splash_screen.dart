import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_service.dart';

/// Clean brand splash — white background, teal logo, loading indicator.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  Timer? _navTimer;
  String _target = AppRoutes.login;
  String? _blockedStatus;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Logo square
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Iconsax.crown_1,
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 20),

            // App name
            const Text(
              'Rexo',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Creator Marketing Platform',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),

            const Spacer(),

            // Loading indicator at bottom
            const Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
