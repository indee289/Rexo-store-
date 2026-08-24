import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/premium_chip.dart';
import '../providers/home_provider.dart';

/// Horizontal scrollable list of category filter chips.
///
/// Uses the premium, token-driven [PremiumChip] (frosted glass, iOS-style)
/// instead of a stock Material `ChoiceChip`, so category filters match the rest
/// of the redesigned surface in both light and dark themes.
class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  static const List<String> _categories = [
    'All',
    'Fashion',
    'Tech',
    'Food',
    'Beauty',
    'Fitness',
    'Travel',
    'Gaming',
    'Music',
    'Education',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPadding,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == selectedCategory;

          return PremiumChip(
            label: category,
            selected: isSelected,
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = category;
            },
          );
        },
      ),
    );
  }
}
