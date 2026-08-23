import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Interactive star rating widget (1-5 stars)
class StarRatingWidget extends StatelessWidget {
  final int rating;
  final double size;
  final bool readonly;
  final ValueChanged<int>? onChanged;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.size = 24,
    this.readonly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating;

        return GestureDetector(
          onTap: readonly ? null : () => onChanged?.call(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: isFilled ? AppColors.warning : Theme.of(context).dividerColor,
            ),
          ),
        );
      }),
    );
  }
}

/// Compact star rating display (for cards)
class StarRatingCompact extends StatelessWidget {
  final double rating;
  final double size;

  const StarRatingCompact({
    super.key,
    required this.rating,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating.round();
        final isHalf = starIndex == rating.ceil() && rating % 1 >= 0.5;

        return Icon(
          isFilled || isHalf
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
          size: size,
          color: isFilled || isHalf ? AppColors.warning : Theme.of(context).dividerColor,
        );
      }),
    );
  }
}
