import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/categories_provider.dart';

/// Local category selection state — used by any screen that embeds
/// [CategoryFilterWidget]. Screens that need to react to the selection
/// should watch this provider directly.
final categoryFilterProvider = StateProvider<String>((ref) => 'All');

/// Horizontal scrollable chip list loaded from product_categories DB table.
/// Falls back to 'All' if categories is empty.
class CategoryFilterWidget extends ConsumerWidget {
  const CategoryFilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);

    return categoriesAsync.when(
      data: (categories) {
        final categoryNames = <String>['All'];
        for (final cat in categories) {
          final name = cat['name'] as String? ?? '';
          if (name.isNotEmpty && !categoryNames.contains(name)) {
            categoryNames.add(name);
          }
        }

        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categoryNames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categoryNames[index];
              final isSelected = category == selectedCategory;

              return GestureDetector(
                onTap: () {
                  ref.read(categoryFilterProvider.notifier).state = category;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        ),
      ),
      error: (_, __) {
        return SizedBox(
          height: 40,
          child: GestureDetector(
            onTap: () {
              ref.read(categoryFilterProvider.notifier).state = 'All';
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'All',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
