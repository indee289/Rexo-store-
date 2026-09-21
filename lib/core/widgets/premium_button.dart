import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Visual variants for [PremiumButton] — mapped to iOS button styles.
///
/// - [filled]: iOS filled — solid emerald fill, white text
/// - [tonal]: iOS tinted — soft tinted background, colored text
/// - [outline]: iOS plain with visible border (rare on iOS but supported)
/// - [ghost]: iOS plain — text only, no fill (bordered variant of tonal)
/// - [glass]: iOS UIVisualEffect — kept for compatibility, renders as tinted
enum PremiumButtonVariant { filled, tonal, outline, ghost, glass }

/// iOS-style button — tactile, refined, no ripple.
///
/// iOS buttons don't ripple. They use an opacity/scale press feedback.
/// Height fixed at 50 (iOS system button standard).
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

  static const double _height = 50;

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
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(style.foreground),
            ),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: style.foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button.copyWith(
                    color: style.foreground,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.24,
                  ),
                ),
              ),
            ],
          );

    Widget surface = Container(
      constraints: const BoxConstraints(minHeight: _height),
      width: widget.expand ? double.infinity : null,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: AppRadius.allMd,
        border: style.border,
      ),
      child: content,
    );

    // iOS button feedback: opacity dim + slight scale
    Widget styled = AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: !_enabled ? 0.4 : (_pressed ? 0.75 : 1.0),
      child: surface,
    );

    Widget scaled = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: styled,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _enabled ? widget.onPressed : null,
      child: scaled,
    );
  }

  _ButtonStyle _resolveStyle() {
    switch (widget.variant) {
      case PremiumButtonVariant.filled:
        return const _ButtonStyle(
          fill: AppColors.primary,
          foreground: Colors.white,
        );
      case PremiumButtonVariant.tonal:
        return const _ButtonStyle(
          fill: AppColors.primaryBg,
          foreground: AppColors.primaryDeep,
        );
      case PremiumButtonVariant.outline:
        return _ButtonStyle(
          fill: Colors.white,
          foreground: AppColors.primary,
          border: Border.all(color: AppColors.primary, width: 1.5),
        );
      case PremiumButtonVariant.ghost:
        return const _ButtonStyle(
          fill: Colors.transparent,
          foreground: AppColors.primary,
        );
      case PremiumButtonVariant.glass:
        // iOS-style tinted variant (compatibility with old glass callers).
        return const _ButtonStyle(
          fill: AppColors.primaryBg,
          foreground: AppColors.primaryDeep,
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
