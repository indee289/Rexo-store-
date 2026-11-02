import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass/glass.dart';

/// **Migration shim.** Use [GlassIconButton] directly.
///
/// Forwards to [GlassIconButton]. The old treatment (bare icon, or an opaque
/// grey circle when `background` was set) is gone; icon buttons are now frosted
/// glass discs, and the 44x44 minimum tap target is preserved.
///
/// Scheduled for deletion once every call-site is migrated.
class PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  /// When false the button renders bare, for use inside a pane that already
  /// supplies a glass surface.
  final bool background;

  /// Tints the glyph brand red.
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
  Widget build(BuildContext context) {
    final fg = color ?? (tonal ? AppColors.primary : AppColors.textPrimary);

    if (!background) {
      return GlassIconButton.bare(
        icon: icon,
        onTap: onPressed,
        color: fg,
        iconSize: iconSize,
        tooltip: tooltip,
      );
    }

    return GlassIconButton(
      icon: icon,
      onTap: onPressed,
      color: fg,
      iconSize: iconSize,
      tooltip: tooltip,
      tint: tonal ? AppColors.primaryGlass : null,
    );
  }
}
