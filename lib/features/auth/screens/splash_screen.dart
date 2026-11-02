import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../services/supabase_service.dart';

/// Splash screen — liquid glass.
///
/// The logo sits on a frosted glass plate floating over the ambient backdrop,
/// and both fade and lift in so the hand-off from the native launch screen
/// reads as one continuous motion rather than two separate splashes.
///
/// Navigation timing and destinations are unchanged.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _intro,
    curve: Curves.easeOutCubic,
  );

  late final Animation<Offset> _lift = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterDelay() async {
    // Short delay only — the native launch screen already shows the same
    // Campster logo, so this transitions seamlessly without a second splash.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    if (SupabaseService.isAuthenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      extendBodyBehindAppBar: false,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _lift,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: GlassSurface(
                    level: GlassLevel.modal,
                    borderRadius: AppRadius.allXxl,
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: const _CampsterLogo(),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'from',
                        style: AppTextStyles.footnote.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Campster',
                        style: AppTextStyles.headline.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

/// The Campster logo, with a brand-red wordmark fallback if the asset is
/// missing so the splash never renders empty.
class _CampsterLogo extends StatelessWidget {
  const _CampsterLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      cacheWidth: 288,
      width: 96,
      height: 96,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Text(
        'Campster',
        style: AppTextStyles.largeTitle.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 36,
        ),
      ),
    );
  }
}
