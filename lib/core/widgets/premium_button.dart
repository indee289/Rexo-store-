import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Visual variants for [PremiumButton] — mapped to Instagram button styles.
///
/// - [filled]: IG "Follow" style — solid blue with white text
/// - [tonal]: Same as filled (kept for API compat)
/// - [outline]: IG "Following" / "Message" style — white with hairline border
/// - [ghost]: IG plain text button (blue text)
/// - [glass]: Kept for compat — renders as outline
enum PremiumButtonVariant { filled, tonal, outline, ghost, glass }

/// Instagram-style button — flat, tight, no shadow.
///
/// Height 44 (IG standard). No ripple, opacity press feedback.
class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final PremiumButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool gradient;
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

  static const double _height = 44;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (!_enabled) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();

    final Widget content = widget.loading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(style.foreground),
            ),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: style.foreground),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button.copyWith(
                    color: style.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

    Widget surface = Container(
      constraints: const BoxConstraints(minHeight: _height),
      width: widget.expand ? double.infinity : null,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: AppRadius.allMd,
        border: style.border,
      ),
      child: content,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: !_enabled ? 0.4 : (_pressed ? 0.7 : 1.0),
        child: surface,
      ),
    );
  }

  _ButtonStyle _resolveStyle() {
    switch (widget.variant) {
      case PremiumButtonVariant.filled:
      case PremiumButtonVariant.tonal:
        return const _ButtonStyle(
          fill: AppColors.primary,
          foreground: Colors.white,
        );
      case PremiumButtonVariant.outline:
      case PremiumButtonVariant.glass:
        return _ButtonStyle(
          fill: Colors.white,
          foreground: AppColors.textPrimary,
          border: Border.all(color: AppColors.border, width: 1),
        );
      case PremiumButtonVariant.ghost:
        return const _ButtonStyle(
          fill: Colors.transparent,
          foreground: AppColors.primary,
        );
    }
  }
}

class _ButtonStyle {
  final Color? fill;
  final Color foreground;
  final BoxBorder? border;

  const _ButtonStyle({
    this.fill,
    required this.foreground,
    this.border,
  });
}
