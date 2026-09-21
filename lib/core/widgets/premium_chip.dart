import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// iOS-style filter / selection chip.
///
/// A pill-shaped button with:
///   * **Unselected** – system-gray filled pill with primary label
///   * **Selected**   – tinted emerald pill with the accent as text/icon
///
/// Optional leading [icon] and trailing [count] badge supported.
class PremiumChip extends StatefulWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final int? count;
  final VoidCallback? onTap;

  const PremiumChip({
    super.key,
    required this.label,
    this.selected = false,
    this.icon,
    this.count,
    this.onTap,
  });

  @override
  State<PremiumChip> createState() => _PremiumChipState();
}

class _PremiumChipState extends State<PremiumChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color fill = widget.selected
        ? AppColors.primaryBg
        : AppColors.surfaceAlt;
    final Color foreground =
        widget.selected ? AppColors.primaryDeep : AppColors.textPrimary;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.sm + 1,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 15, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            widget.label,
            style: AppTextStyles.footnote.copyWith(
              color: foreground,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          if (widget.count != null) ...[
            const SizedBox(width: 6),
            _CountBadge(count: widget.count!, selected: widget.selected),
          ],
        ],
      ),
    );

    if (widget.onTap == null) return chip;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.6 : 1.0,
        child: chip,
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool selected;

  const _CountBadge({required this.count, required this.selected});

  @override
  Widget build(BuildContext context) {
    final Color bg =
        selected ? AppColors.primary : AppColors.systemGray4;
    final Color fg = Colors.white;

    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillAll,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption2.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
