import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// iOS-style card / grouped list cell.
///
/// Pure-white surface floating on the systemGroupedBackground. Very subtle
/// shadow, no border rim — iOS relies on the color contrast between the
/// cell (white) and the page background (systemGray6) for definition.
///
/// Backward compatible — the [glass] and [gradient] params are preserved.
class PremiumCard extends StatefulWidget {
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
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _pressed = false;

  bool get _tappable => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final bg = widget.backgroundColor ?? Colors.white;

    Widget card = Container(
      decoration: BoxDecoration(
        color: widget.gradient ? null : bg,
        gradient: widget.gradient ? AppColors.cardGradient : null,
        borderRadius: radius,
        // iOS-style barely-there elevation.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, 6),
            blurRadius: 18,
            spreadRadius: -3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: widget.padding ?? EdgeInsets.zero,
          child: widget.child,
        ),
      ),
    );

    if (!_tappable) return card;

    // iOS-style press feedback: gentle scale + opacity.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _pressed ? 0.85 : 1.0,
          child: card,
        ),
      ),
    );
  }
}
