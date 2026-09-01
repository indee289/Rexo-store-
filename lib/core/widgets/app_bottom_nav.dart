import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Fixed bottom navigation bar (matches the Home reference).
///
/// Exactly four tabs — Home, Campaigns, Shop, Profile — each with an icon and
/// a label. The active tab shows a soft violet rounded chip behind its icon
/// plus a violet label; inactive tabs show a muted icon + label. Theme-aware.
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
    _Item(Iconsax.send_2, 'Campaigns'),
    _Item(Iconsax.shop, 'Shop'),
    _Item(Iconsax.user, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final inactive = isDark ? AppColors.darkTextHint : AppColors.textHint;

    return Container(
      decoration: BoxDecoration(
        color: barColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.30 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
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
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: AppRadius.allMd,
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: active ? AppColors.primary : inactiveColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.primary : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
