import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import 'glass_surface.dart';

/// Visual variants for [GlassButton].
enum GlassButtonVariant {
  /// Solid brand-red gradient with a red glow — the single primary action.
  filled,

  /// Frosted translucent fill with a light rim — secondary actions.
  glass,

  /// Transparent with a brand-red rim — tertiary / "cancel-ish" actions.
  outline,

  /// No fill, no rim, red label — inline links.
  ghost,

  /// Solid error red — irreversible actions (delete, block, withdraw).
  destructive,
}

/// Size steps. All are pill-shaped; only height, padding and type size change.
enum GlassButtonSize { small, medium, large }

/// The app's only button.
///
/// Pill-shaped, with the shared spring press animation, a loading state that
/// preserves the button's width (so layouts never jump), and a disabled state
/// that dims rather than greys out.
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GlassButtonVariant.filled,
    this.size = GlassButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = true,
  });

  /// Secondary frosted button.
  const GlassButton.glass({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = GlassButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = true,
  }) : variant = GlassButtonVariant.glass;

  /// Outlined tertiary button.
  const GlassButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = GlassButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = true,
  }) : variant = GlassButtonVariant.outline;

  /// Text-only button.
  const GlassButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = GlassButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = false,
  }) : variant = GlassButtonVariant.ghost;

  /// Destructive action button.
  const GlassButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = GlassButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = true,
  }) : variant = GlassButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final GlassButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final bool expand;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 240),
  );

  late final Animation<double> _scale = _press.drive(
    Tween<double>(begin: 1.0, end: 0.96)
        .chain(CurveTween(curve: Curves.easeOutCubic)),
  );

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  /// Height per step.
  ///
  /// `medium` and `large` were originally 50 and 58. At those heights a primary
  /// action read as oversized — a pinned 58px pill dominated the screen it sat
  /// on. They are now 46 and 52, which still clears the 44pt minimum target
  /// while looking like a button rather than a banner. `small` stays at 38: it
  /// is only ever used inline inside a card, where it sits next to text.
  double get _height {
    switch (widget.size) {
      case GlassButtonSize.small:
        return 38;
      case GlassButtonSize.medium:
        return 46;
      case GlassButtonSize.large:
        return 52;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case GlassButtonSize.small:
        return 13;
      case GlassButtonSize.medium:
        return 15;
      case GlassButtonSize.large:
        return 16;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case GlassButtonSize.small:
        return 16;
      case GlassButtonSize.medium:
        return 18;
      case GlassButtonSize.large:
        return 20;
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case GlassButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16);
      case GlassButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 22);
      case GlassButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 26);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.pill);
    final fg = _foreground;

    final Widget content = widget.loading
        ? SizedBox(
            height: _iconSize,
            width: _iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: _iconSize, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: fg,
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(widget.trailingIcon, size: _iconSize, color: fg),
              ],
            ],
          );

    Widget surface;

    switch (widget.variant) {
      case GlassButtonVariant.filled:
      case GlassButtonVariant.destructive:
        surface = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: _enabled ? AppElevation.brand(false) : const [],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: _solidGradient),
              child: _Body(
                height: _height,
                padding: _padding,
                expand: widget.expand,
                child: content,
              ),
            ),
          ),
        );
        break;

      case GlassButtonVariant.glass:
        surface = GlassSurface(
          level: GlassLevel.subtle,
          borderRadius: radius,
          tint: AppGlass.button(false),
          shadow: AppElevation.card(false),
          child: _Body(
            height: _height,
            padding: _padding,
            expand: widget.expand,
            child: content,
          ),
        );
        break;

      case GlassButtonVariant.outline:
        surface = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.primaryRim, width: 1.2),
          ),
          child: _Body(
            height: _height,
            padding: _padding,
            expand: widget.expand,
            child: content,
          ),
        );
        break;

      case GlassButtonVariant.ghost:
        surface = _Body(
          height: _height,
          padding: _padding,
          expand: widget.expand,
          child: content,
        );
        break;
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _press.forward() : null,
        onTapUp: _enabled ? (_) => _press.reverse() : null,
        onTapCancel: _enabled ? () => _press.reverse() : null,
        onTap: _enabled ? widget.onPressed : null,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: _enabled ? 1.0 : 0.42,
            child: surface,
          ),
        ),
      ),
    );
  }

  /// Gradient for the two solid variants.
  Gradient get _solidGradient {
    if (widget.variant == GlassButtonVariant.destructive) {
      return const LinearGradient(
        colors: [Color(0xFFD32F2F), AppColors.error],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return AppColors.primaryGradient;
  }

  Color get _foreground {
    switch (widget.variant) {
      case GlassButtonVariant.filled:
      case GlassButtonVariant.destructive:
        return AppColors.textOnPrimary;
      case GlassButtonVariant.glass:
        return AppColors.textPrimary;
      case GlassButtonVariant.outline:
      case GlassButtonVariant.ghost:
        return AppColors.primary;
    }
  }
}

/// Shared sizing box for every variant, so all buttons of one size line up.
class _Body extends StatelessWidget {
  const _Body({
    required this.height,
    required this.padding,
    required this.expand,
    required this.child,
  });

  final double height;
  final EdgeInsets padding;
  final bool expand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: expand ? double.infinity : null,
      padding: padding,
      alignment: Alignment.center,
      child: child,
    );
  }
}
