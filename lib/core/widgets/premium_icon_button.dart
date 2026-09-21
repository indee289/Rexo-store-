import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';

/// A premium, iOS-style icon button (Layer-2 primitive).
///
/// Replaces the stock `IconButton`. It guarantees a comfortable **44×44**
/// minimum tap target (matching the platform touch guideline), renders an
/// Iconsax glyph, and animates a subtle press-scale for tactile feedback.
///
/// A [background] can optionally be shown behind the glyph. When enabled it is
/// a frosted, translucent surface built from the [AppGlass] tokens so it reads
/// as glassy rather than a flat Material tint. Pass [tonal] to give that glass
/// surface a brand-primary tint instead of the neutral frost.
class PremiumIconButton extends StatefulWidget {
  /// The icon to render. Prefer an `Iconsax.*` glyph.
  final IconData icon;

  /// Tap handler. When null the button renders disabled and ignores taps.
  final VoidCallback? onPressed;

  /// Whether to render a frosted translucent background behind the glyph.
  final bool background;

  /// When true (and [background] is enabled) the frosted background is tinted
  /// with the brand primary; otherwise it uses a neutral glass frost.
  final bool tonal;

  /// Glyph size. The tap target stays 44×44 regardless of this value.
  final double iconSize;

  /// Optional explicit icon color. Defaults to the theme's onSurface, or the
  /// brand primary when [tonal] is set.
  final Color? color;

  /// Optional semantic label for accessibility.
  final String? tooltip;

  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.background = false,
    this.tonal = false,
    this.iconSize = 22,
    this.color,
    this.tooltip,
  });

  @override
  State<PremiumIconButton> createState() => _PremiumIconButtonState();
}

class _PremiumIconButtonState extends State<PremiumIconButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final Color foreground = widget.color ??
        (widget.tonal ? primary : theme.colorScheme.onSurface);
    // Disabled glyphs are dimmed so the state is legible in both themes.
    final Color effectiveForeground =
        _enabled ? foreground : foreground.withOpacity(0.35);

    Widget glyph = Icon(
      widget.icon,
      size: widget.iconSize,
      color: effectiveForeground,
    );

    if (widget.background) {
      final Color fill = widget.tonal
          ? primary.withOpacity(isDark ? 0.22 : 0.12)
          : AppGlass.button(isDark);
      final Color rim = widget.tonal
          ? primary.withOpacity(0.45)
          : AppGlass.border(isDark);

      glyph = ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: AppGlass.blurSigmaSubtle,
            sigmaY: AppGlass.blurSigmaSubtle,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: rim, width: 1),
            ),
            alignment: Alignment.center,
            child: glyph,
          ),
        ),
      );
    }

    final button = AnimatedScale(
      scale: _pressed ? AppMotion.pressScale : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Center(child: glyph),
      ),
    );

    final semantics = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: button,
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: semantics);
    }
    return semantics;
  }
}
