import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Instagram-style icon button — flat, minimal, 44×44 tap target.
///
/// Instagram uses simple outlined black icons with no background chrome.
/// Optional [background] renders a subtle gray circular fill (like the
/// IG "search" bar hint area). Opacity press feedback (no ripple).
class PremiumIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool background;
  final bool tonal;
  final double iconSize;
  final Color? color;
  final String? tooltip;

  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.background = false,
    this.tonal = false,
    this.iconSize = 24,
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
    final Color foreground = widget.color ??
        (widget.tonal ? AppColors.primary : AppColors.textPrimary);
    final Color effectiveForeground =
        _enabled ? foreground : foreground.withOpacity(0.30);

    Widget glyph = Icon(
      widget.icon,
      size: widget.iconSize,
      color: effectiveForeground,
    );

    if (widget.background) {
      glyph = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: widget.tonal
              ? AppColors.primaryBg
              : AppColors.surfaceAlt,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: glyph,
      );
    }

    final button = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      child: Center(child: glyph),
    );

    final gesture = GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: !_enabled ? 0.4 : (_pressed ? 0.4 : 1.0),
        child: button,
      ),
    );

    final semantics = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.tooltip,
      child: gesture,
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: semantics);
    }
    return semantics;
  }
}
