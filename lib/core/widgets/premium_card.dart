import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import 'glass/glass.dart';

/// **Deprecated — migration shim.** Use [GlassCard] directly.
///
/// This type now contains no styling of its own: it forwards straight to
/// [GlassCard] so the ~58 call-sites that still say `PremiumCard` render real
/// liquid glass while they are migrated screen by screen. The old treatment
/// (opaque white fill, 0.8px grey border, 12px radius, flat 4% drop shadow) is
/// gone entirely — there is no code path left that can paint it.
///
/// Scheduled for deletion once every call-site is migrated.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  /// Ignored. Retained so existing call-sites compile; [GlassCard] decides its
  /// own gradient from the glass tokens.
  final bool gradient;

  /// Ignored — every card is glass now.
  final bool glass;

  /// Forwarded as the glass tint when supplied. Call-sites passing an opaque
  /// colour will get an opaque card, so these are the ones to migrate first.
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
    return GlassCard(
      padding: padding ?? EdgeInsets.zero,
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      tint: backgroundColor,
      child: child,
    );
  }
}
