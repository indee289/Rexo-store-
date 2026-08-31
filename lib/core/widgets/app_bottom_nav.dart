import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_colors.dart';

/// Premium floating bottom navigation bar with pill indicator.
///
/// The active destination expands into a filled indigo pill showing the icon
/// and label side-by-side. Inactive destinations show only their icon in a
/// muted colour. The bar itself floats on a frosted-glass card with a subtle
/// indigo-tinted shadow so it never competes with page content.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _Item(Iconsax.home_2,     Iconsax.home_2,      'Home'),
    _Item(Iconsax.briefcase,  Iconsax.briefcase,   'Campaigns'),
    _Item(Iconsax.shop,       Iconsax.shop,        'Shop'),
    _Item(Iconsax.messages_2, Iconsax.messages_2,  'Inbox'),
    _Item(Iconsax.user,       Iconsax.user,        'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withOpacity(0.85)
                    : Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder.withOpacity(0.6)
                      : AppColors.border.withOpacity(0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withOpacity(isDark ? 0.15 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  _items.length,
                  (i) => _NavItem(
                    item: _items[i],
                    active: currentIndex == i,
                    onTap: () => onTap(i),
                    isDark: isDark,
                  ),
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
  final IconData activeIcon;
  final String label;

  const _Item(this.icon, this.activeIcon, this.label);
}

class _NavItem extends StatelessWidget {
  final _Item item;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.item,
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 18 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? item.activeIcon : item.icon,
              size: 22,
              color: active
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextHint
                      : AppColors.textHint),
            ),
            if (active) ...[
              const SizedBox(width: 6),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
