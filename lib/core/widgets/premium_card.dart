import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Floating premium card.
///
/// Modern minimal design: layered soft shadows in light mode, subtle rim +
/// depth in dark mode. Theme-aware. Optional glassmorphism variant via
/// [glass].
///
/// Backward compatible — the [glass] param is new and defaults to `false`.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool gradient;
  final bool glass;
  final Color? backgroundColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = AppRadius.lg,
    this.gradient = false,
    this.glass = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    // Glassmorphism variant — frosted surface with BackdropFilter blur.
    if (glass) {
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.white)
                    .withOpacity(isDark ? 0.06 : 0.55),
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.12 : 0.55),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                splashColor: AppColors.primary.withOpacity(0.06),
                highlightColor: AppColors.primary.withOpacity(0.04),
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Standard solid card with layered premium shadow.
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkCard : Colors.white);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: gradient ? null : bgColor,
          gradient: gradient
              ? (isDark
                  ? AppColors.darkCardGradient
                  : AppColors.cardGradient)
              : null,
          borderRadius: radius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            // Deep soft shadow — the gentle floating lift.
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.30 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            // Close crisp shadow — defines the edge.
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.20 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: -1,
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: AppColors.primary.withOpacity(0.06),
          highlightColor: AppColors.primary.withOpacity(0.04),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
