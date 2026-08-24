import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Visual style variants for [PremiumButton].
///
/// * [filled]  — solid brand fill (optionally a gradient) for primary CTAs.
/// * [tonal]   — soft brand tint fill for secondary emphasis.
/// * [outline] — transparent fill with a hairline border.
/// * [ghost]   — transparent, borderless, text-only affordance.
/// * [glass]   — translucent, frosted iOS-style glass (the prominent premium
///   look). Renders a `BackdropFilter` blur behind a translucent fill and a
///   light rim border, using the [AppGlass] tokens.
enum PremiumButtonVariant { filled, tonal, outline, ghost, glass }

/// Premium, token-driven button that replaces the stock Material
/// `ElevatedButton` / `OutlinedButton` / `TextButton` look.
///
/// Behaviors (Requirement 11):
/// * Press-scale feedback to [AppMotion.pressScale] over [AppMotion.fast].
/// * Shows a spinner and blocks taps while [loading].
/// * Renders a disabled style and ignores taps when [onPressed] is `null`.
///
/// The redesign favours a modern **translucent / frosted-glass** aesthetic, so
/// the [PremiumButtonVariant.glass] variant produces an iOS-style frosted look
/// that reads as premium in both light and dark themes. The solid
/// [PremiumButtonVariant.filled] variant (with optional [gradient]) remains for
/// primary CTAs.
///
/// This widget is token-driven only: it never uses raw color literals or inline
/// `GoogleFonts` — all values come from [AppColors], [AppSpacing], [AppRadius],
/// [AppMotion], [AppGlass], and [AppTextStyles].
class PremiumButton extends StatefulWidget {
  /// Button label text.
  final String label;

  /// Tap handler. When `null`, the button renders disabled and ignores taps.
  final VoidCallback? onPressed;

  /// Visual style variant.
  final PremiumButtonVariant variant;

  /// Optional leading icon (use an `Iconsax.*` glyph for the premium icon pack).
  final IconData? icon;

  /// When `true`, shows a spinner in place of the content and blocks taps.
  final bool loading;

  /// For the [PremiumButtonVariant.filled] variant, fills with
  /// [AppColors.primaryGradient] instead of a flat color.
  final bool gradient;

  /// When `true` (default), the button expands to the full available width.
  final bool expand;

  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PremiumButtonVariant.filled,
    this.icon,
    this.loading = false,
    this.gradient = false,
    this.expand = true,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _pressed = false;

  /// Fixed premium button height (comfortable 44+ tap target).
  static const double _height = 52;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (!_enabled) return;
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final _ButtonStyle style = _resolveStyle(theme, isDark);

    // Content: spinner while loading, otherwise optional icon + label.
    final Widget content = widget.loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(style.foreground),
            ),
          )
        : Row(
            mainAxisSize:
                widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: style.foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button.copyWith(color: style.foreground),
                ),
              ),
            ],
          );

    // Inner padded surface (shared by all variants).
    final Widget innerSurface = Container(
      height: _height,
      width: widget.expand ? double.infinity : null,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: style.fill,
        gradient: style.gradient,
        borderRadius: AppRadius.allMd,
        border: style.border,
      ),
      child: content,
    );

    // Glass variant wraps the surface in a blur so the background shows through
    // the translucent frosted fill.
    Widget surface;
    if (widget.variant == PremiumButtonVariant.glass) {
      surface = ClipRRect(
        borderRadius: AppRadius.allMd,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: AppGlass.blurSigmaSubtle,
            sigmaY: AppGlass.blurSigmaSubtle,
          ),
          child: innerSurface,
        ),
      );
    } else {
      surface = innerSurface;
    }

    // Disabled visuals: dim the whole surface.
    final Widget styled = Opacity(
      opacity: (widget.onPressed == null) ? 0.5 : 1.0,
      child: surface,
    );

    final Widget scaled = AnimatedScale(
      scale: _pressed ? AppMotion.pressScale : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: styled,
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _enabled ? widget.onPressed : null,
        child: scaled,
      ),
    );
  }

  _ButtonStyle _resolveStyle(ThemeData theme, bool isDark) {
    switch (widget.variant) {
      case PremiumButtonVariant.filled:
        return _ButtonStyle(
          fill: widget.gradient ? null : AppColors.primary,
          gradient: widget.gradient ? AppColors.primaryGradient : null,
          foreground: Colors.white,
        );

      case PremiumButtonVariant.tonal:
        return _ButtonStyle(
          fill: AppColors.primary.withOpacity(isDark ? 0.22 : 0.12),
          foreground: AppColors.primary,
        );

      case PremiumButtonVariant.outline:
        return _ButtonStyle(
          fill: Colors.transparent,
          foreground: theme.colorScheme.onSurface,
          border: Border.all(color: theme.dividerColor, width: 1),
        );

      case PremiumButtonVariant.ghost:
        return _ButtonStyle(
          fill: Colors.transparent,
          foreground: AppColors.primary,
        );

      case PremiumButtonVariant.glass:
        // Frosted translucent fill + light rim border via AppGlass tokens.
        return _ButtonStyle(
          fill: AppGlass.button(isDark),
          foreground: theme.colorScheme.onSurface,
          border: Border.all(color: AppGlass.border(isDark), width: 1),
        );
    }
  }
}

/// Internal resolved visual style for a [PremiumButtonVariant].
class _ButtonStyle {
  final Color? fill;
  final Gradient? gradient;
  final Color foreground;
  final BoxBorder? border;

  const _ButtonStyle({
    this.fill,
    this.gradient,
    required this.foreground,
    this.border,
  });
}
