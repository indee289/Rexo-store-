import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Modern floating dock navigation.
///
/// A rounded, elevated bar that floats above the content (thanks to the
/// [Scaffold.extendBody] on [AppShell]). The active tab is highlighted with a
/// green pill containing the icon + label; inactive tabs show a muted icon.
/// Fully theme-aware for light and dark mode.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _Item(Iconsax.home_2, 'Home'),
    _Item(Iconsax.briefcase, 'Campaigns'),
    _Item(Iconsax.shop, 'Shop'),
    _Item(Iconsax.messages_2, 'Inbox'),
    _Item(Iconsax.user, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkCard : Colors.white;
    final inactive = isDark ? AppColors.darkTextHint : AppColors.textHint;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1,
            ),
            boxShadow: AppElevation.raised(isDark),
          ),
          child: Row(
            children: List.generate(
              _items.length,
              (i) => Expanded(
                child: _NavItem(
                  item: _items[i],
                  active: currentIndex == i,
                  inactiveColor: inactive,
                  onTap: () => onTap(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String label;
  const _Item(this.icon, this.label);
}

class _NavItem extends StatelessWidget {
  final _Item item;
  final bool active;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.active,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: AppRadius.pillAll,
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: active ? Colors.white : inactiveColor,
            ),
          ),
          if (active) ...[
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
