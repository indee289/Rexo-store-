import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Visual indicator showing filled vs total campaign slots
class SlotsIndicator extends StatelessWidget {
  final int filledSlots;
  final int totalSlots;

  const SlotsIndicator({
    super.key,
    required this.filledSlots,
    required this.totalSlots,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSlots > 0 ? filledSlots / totalSlots : 0.0;
    final color = _getColor(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$filledSlots/$totalSlots slots filled',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Color _getColor(double progress) {
    if (progress >= 1.0) return AppColors.error;
    if (progress >= 0.75) return AppColors.warning;
    return AppColors.success;
  }
}
