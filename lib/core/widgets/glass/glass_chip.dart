import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

/// Pill-shaped glass chip — filters, tags, status pills, selectable options.
///
/// Selected chips fill with brand-red glass and gain a red rim; unselected
/// chips are a plain frosted pill. The transition between the two is animated
/// so filter rows feel responsive.
class GlassChip extends StatefulWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.trailingIcon,
    this.onTrailingTap,
    this.color,
    this.dense = false,
  });

  /// Non-interactive coloured status pill (campaign / order / KYC states).
  const GlassChip.status({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = true,
  })  : selected = true,
        onTap = null,
        trailingIcon = null,
        onTrailingTap = null;

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;

  /// Accent colour when selected. Defaults to brand red.
  final Color? color;
  final bool dense;

  @override
  State<GlassChip> createState() => _GlassChipState();
}

class _GlassChipState extends State<GlassChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 200),
  );

  late final Animation<double> _scale = _press.drive(
    Tween<double>(begin: 1.0, end: 0.94)
        .chain(CurveTween(curve: Curves.easeOutCubic)),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AppColors.primary;
    final selected = widget.selected;
    final fg = selected ? accent : AppColors.textSecondary;
    final iconSize = widget.dense ? 13.0 : 15.0;

    Widget chip = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: widget.dense ? 11 : 15,
        vertical: widget.dense ? 6 : 9,
      ),
      decoration: BoxDecoration(
        color: selected
            ? accent.withOpacity(0.14)
            : AppGlass.recessed(false),
        borderRadius: AppRadius.pillAll,
        border: Border.all(
          color: selected ? accent.withOpacity(0.42) : AppColors.border,
          width: AppGlass.borderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: iconSize, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            widget.label,
            style: (widget.dense
                    ? AppTextStyles.labelSmall
                    : AppTextStyles.labelMedium)
                .copyWith(
              color: fg,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: 5),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTrailingTap,
              child: Icon(widget.trailingIcon, size: iconSize, color: fg),
            ),
          ],
        ],
      ),
    );

    if (widget.onTap == null) return chip;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(scale: _scale, child: chip),
      ),
    );
  }
}

/// Horizontally scrolling row of filter chips.
class GlassChipRow extends StatelessWidget {
  const GlassChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
              child: GlassChip(
                label: labels[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}
