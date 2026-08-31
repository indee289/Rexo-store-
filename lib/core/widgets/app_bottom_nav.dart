import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_colors.dart';

/// Instagram-style bottom navigation bar.
/// White background, 1px top border, 5 equal-width tabs.
/// Active: teal icon + teal label below. Inactive: gray icon, no label.
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(
              _items.length,
              (i) => Expanded(
                child: _NavItem(
                  item: _items[i],
                  active: currentIndex == i,
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
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.active,
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
          Icon(
            item.icon,
            size: 22,
            color: active ? AppColors.primary : AppColors.textHint,
          ),
          if (active) ...[
            const SizedBox(height: 3),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 11,
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
