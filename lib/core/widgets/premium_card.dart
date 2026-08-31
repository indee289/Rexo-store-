import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A premium card container with optional gradient, proper depth shadows,
/// and theme-aware light/dark surfaces.
///
/// Use [gradient] to enable the subtle indigo-tinted card gradient. Use
/// [backgroundColor] to override the surface colour entirely. The card
/// supports an optional [onTap] handler with an ink splash bounded to the
/// card's rounded corners.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool gradient;
  final Color? backgroundColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 16,
    this.gradient = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkCard : AppColors.surface);

    final cardContent = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: gradient ? null : bgColor,
          gradient: gradient
              ? (isDark
                  ? AppColors.darkCardGradient
                  : AppColors.cardGradient)
              : null,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.primary.withOpacity(0.05),
          highlightColor: AppColors.primary.withOpacity(0.03),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: cardContent,
    );
  }
}
