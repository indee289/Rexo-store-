import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import 'glass_surface.dart';

/// Circular frosted icon button — the only icon-button treatment in the app.
///
/// Always presents a 44x44 tap target (the iOS minimum) even when the visible
/// glass disc is smaller, so dense toolbars stay accessible.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 38,
    this.iconSize = 20,
    this.tooltip,
    this.color,
    this.tint,
    this.badgeCount,
    this.filled = false,
    this.showDisc = true,
  });

  /// Brand-red filled variant — for a single emphasised toolbar action.
  const GlassIconButton.filled({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 38,
    this.iconSize = 20,
    this.tooltip,
    this.badgeCount,
  })  : color = AppColors.textOnPrimary,
        tint = null,
        filled = true,
        showDisc = true;

  /// No glass disc at all — a bare tappable icon, for inside a glass pane that
  /// already provides the surface.
  const GlassIconButton.bare({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 38,
    this.iconSize = 20,
    this.tooltip,
    this.color,
    this.badgeCount,
  })  : tint = null,
        filled = false,
        showDisc = false;

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final String? tooltip;

  /// Icon colour. Defaults to primary ink, or white when [filled].
  final Color? color;

  /// Overrides the glass tint.
  final Color? tint;

  /// Renders a small count badge on the top-right when non-null and > 0.
  final int? badgeCount;
  final bool filled;
  final bool showDisc;

  @override
  Widget build(BuildContext context) {
    final fg = color ??
        (filled ? AppColors.textOnPrimary : AppColors.textPrimary);

    Widget disc = Icon(icon, size: iconSize, color: fg);

    if (filled) {
      disc = Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
        ),
        child: Center(child: disc),
      );
    } else if (showDisc) {
      disc = GlassSurface(
        level: GlassLevel.subtle,
        borderRadius: BorderRadius.circular(size),
        width: size,
        height: size,
        tint: tint ?? AppGlass.button(false),
        alignment: Alignment.center,
        child: Center(child: disc),
      );
    } else {
      disc = SizedBox(width: size, height: size, child: Center(child: disc));
    }

    if (badgeCount != null && badgeCount! > 0) {
      disc = Stack(
        clipBehavior: Clip.none,
        children: [
          disc,
          Positioned(
            top: -2,
            right: -2,
            child: _CountBadge(count: badgeCount!),
          ),
        ],
      );
    }

    Widget result = Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          // Guarantee the 44pt minimum tap target.
          width: size < 44 ? 44 : size,
          height: size < 44 ? 44 : size,
          child: Center(child: disc),
        ),
      ),
    );

    if (tooltip != null) {
      result = Tooltip(message: tooltip!, child: result);
    }

    return result;
  }
}

/// Small red count badge used by notification / message icons.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withOpacity(0.75), width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
