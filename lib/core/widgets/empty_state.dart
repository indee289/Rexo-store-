import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Modern empty state — "hero card" design.
///
/// Instead of the classic centered illustration, this shows a large tilted
/// rounded-square icon tile with layered gradient shadows, a big bold title,
/// a two-line subtitle, and an optional pill-shaped CTA. Uses gentle rotation
/// + scale animation for subtle life.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final IconData? ctaIcon;
  final Widget? cta;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.ctaIcon,
    this.cta,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.xxl,
    ),
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _rotation = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget? ctaWidget = widget.cta ??
        ((widget.ctaLabel != null && widget.onCta != null)
            ? _PillCta(
                label: widget.ctaLabel!,
                icon: widget.ctaIcon,
                onPressed: widget.onCta!,
              )
            : null);

    return Center(
      child: Padding(
        padding: widget.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Big tilted icon tile
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.rotate(
                angle: _rotation.value,
                child: Transform.scale(scale: _scale.value, child: child),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Layered soft shadow blob behind
                  Positioned(
                    top: 24,
                    left: 24,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.10),
                      ),
                    ),
                  ),
                  // Big rounded-square icon tile
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF34D399),
                          Color(0xFF10B981),
                          Color(0xFF059669),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                          spreadRadius: -8,
                        ),
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  // Highlight dot top-right for depth
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),

            // Subtitle
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],

            // CTA
            if (ctaWidget != null) ...[
              const SizedBox(height: 28),
              ctaWidget,
            ],
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped CTA button — full rounded, gradient background, layered glow.
class _PillCta extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _PillCta({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  State<_PillCta> createState() => _PillCtaState();
}

class _PillCtaState extends State<_PillCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.pillAll,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.40),
                blurRadius: 24,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppTextStyles.headline.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
