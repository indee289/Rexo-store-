import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Instagram-style tag / filter chip.
///
/// Selected → black filled with white text (IG "highlight" active).
/// Unselected → white with a hairline border and black text.
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
    final Color fill =
        widget.selected ? AppColors.textPrimary : Colors.white;
    final Color foreground =
        widget.selected ? Colors.white : AppColors.textPrimary;
    final Color borderColor = widget.selected
        ? AppColors.textPrimary
        : AppColors.border;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            widget.label,
            style: AppTextStyles.footnote.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.count != null) ...[
            const SizedBox(width: 5),
            Text(
              '(${widget.count})',
              style: AppTextStyles.footnote.copyWith(
                color: foreground.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
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
