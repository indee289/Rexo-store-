import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Clean card used across the app.
///
/// Opaque white surface with a soft hairline border and a very light shadow on
/// the Sand Dune background. (Previously every card ran its own
/// `BackdropFilter` blur; with 10-20 cards in a list that made scrolling slow
/// on mid-range phones, so the per-card blur was removed. Visually the card is
/// nearly identical on the flat sand background, but it is far cheaper to
/// paint.)
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

    final Widget card = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // 4% black
            blurRadius: 10,
            offset: Offset(0, 2),
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _pressed ? 0.985 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 90),
          opacity: _pressed ? 0.85 : 1.0,
          child: card,
        ),
      ),
    );
  }
}
