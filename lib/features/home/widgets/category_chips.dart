import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/home_provider.dart';

/// Horizontal scrollable list of category filter chips.
///
/// Now built from [GlassChip]: a frosted pill that fills with brand-red glass
/// and gains a red rim when selected, with the shared spring press. Replaces
/// the previous black-filled `PremiumChip`.
///
/// The selected-category provider and its values are unchanged.
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
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPadding,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = _categories[index];

          return Center(
            child: GlassChip(
              label: category,
              selected: category == selectedCategory,
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).state = category;
              },
            ),
          );
        },
      ),
    );
  }
}
