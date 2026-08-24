import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A consistent empty / zero-data placeholder (Component_Library).
///
/// Replaces ad-hoc "empty columns" with one token-driven primitive: an Iconsax
/// glyph inside a soft tonal circle, a title, an optional subtitle, and an
/// optional call-to-action button.
///
/// The CTA is rendered by a self-contained, token-driven fallback button so
/// this primitive has no dependency on other (not-yet-built) primitives. Once
/// `PremiumButton` lands, screens may pass their own via [cta] instead.
class EmptyState extends StatelessWidget {
  /// Iconsax glyph shown in the tonal circle.
  final IconData icon;

  /// Primary line describing the empty state.
  final String title;

  /// Optional supporting explanation.
  final String? subtitle;

  /// Label for the built-in fallback CTA button. Ignored when [cta] is set.
  final String? ctaLabel;

  /// Tap handler for the built-in fallback CTA button. Ignored when [cta] set.
  final VoidCallback? onCta;

  /// Optional leading Iconsax icon inside the fallback CTA button.
  final IconData? ctaIcon;

  /// Fully custom CTA widget (e.g. a `PremiumButton`). Overrides
  /// [ctaLabel]/[onCta].
  final Widget? cta;

  /// Outer padding around the centered content.
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
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Widget? ctaWidget = cta ??
        ((ctaLabel != null && onCta != null)
            ? _FallbackCtaButton(
                label: ctaLabel!,
                icon: ctaIcon,
                onPressed: onCta!,
              )
            : null);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Soft tonal glyph circle (iOS-style translucent fill).
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.10),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.h6.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (ctaWidget != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ctaWidget,
            ],
          ],
        ),
      ),
    );
  }
}

/// Self-contained, token-driven fallback CTA button used by [EmptyState] until
/// the shared `PremiumButton` primitive is available.
class _FallbackCtaButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _FallbackCtaButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  State<_FallbackCtaButton> createState() => _FallbackCtaButtonState();
}

class _FallbackCtaButtonState extends State<_FallbackCtaButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (value == _pressed) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppRadius.allMd,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: AppTextStyles.button,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
