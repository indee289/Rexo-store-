import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Visual variants for [PremiumButton].
enum PremiumButtonVariant { filled, tonal, outline, ghost, glass }

/// Clean teal button with variants matching the Instagram-style design system.
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

  static const double _height = 46;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (!_enabled) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _resolveStyle(isDark);

    final Widget content = widget.loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(style.foreground),
            ),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: style.foreground),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

    Widget surface = Container(
      height: _height,
      width: widget.expand ? double.infinity : null,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: style.fill,
        gradient: style.gradientDecoration,
        borderRadius: AppRadius.allMd,
        border: style.border,
      ),
      child: content,
    );

    Widget styled = Opacity(
      opacity: (widget.onPressed == null) ? 0.5 : 1.0,
      child: surface,
    );

    Widget scaled = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
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

  _ButtonStyle _resolveStyle(bool isDark) {
    switch (widget.variant) {
      case PremiumButtonVariant.filled:
        return _ButtonStyle(
          fill: widget.gradient ? null : AppColors.primary,
          gradientDecoration: widget.gradient ? AppColors.primaryGradient : null,
          foreground: Colors.white,
        );
      case PremiumButtonVariant.tonal:
        return _ButtonStyle(
          fill: isDark ? AppColors.darkSurfaceAlt : AppColors.primaryBg,
          foreground: isDark ? AppColors.primaryLight : AppColors.primaryDeep,
        );
      case PremiumButtonVariant.outline:
        return _ButtonStyle(
          fill: Colors.transparent,
          foreground: AppColors.primary,
          border: Border.all(color: AppColors.primary, width: 1.5),
        );
      case PremiumButtonVariant.ghost:
        return _ButtonStyle(
          fill: Colors.transparent,
          foreground: AppColors.primary,
        );
      case PremiumButtonVariant.glass:
        return _ButtonStyle(
          fill: Colors.white.withOpacity(isDark ? 0.08 : 0.15),
          foreground: Colors.white,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        );
    }
  }
}

class _ButtonStyle {
  final Color? fill;
  final Gradient? gradientDecoration;
  final Color foreground;
  final BoxBorder? border;

  const _ButtonStyle({
    this.fill,
    this.gradientDecoration,
    required this.foreground,
    this.border,
  });
}
