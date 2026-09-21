import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Fixed bottom navigation bar — premium marketplace green edition.
///
/// Four tabs — Home, Campaigns, Jobs, Profile. Active tab shows a soft
/// emerald gradient pill behind its icon with a smooth animated transition;
/// inactive tabs show a muted icon + label. Theme-aware.
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
    _Item(Iconsax.briefcase, 'Jobs'),
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
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, -4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: IntrinsicHeight(
            child: Row(
              children: List.generate(
                _items.length,
                (i) => Expanded(
                  child: _NavItem(
                    item: _items[i],
                    active: currentIndex == i,
                    inactiveColor: inactive,
                    isDark: isDark,
                    onTap: () => onTap(i),
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
  final String label;
  const _Item(this.icon, this.label);
}

class _NavItem extends StatefulWidget {
  final _Item item;
  final bool active;
  final Color inactiveColor;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.active,
    required this.inactiveColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final activeIconColor = Colors.white;
    final activeLabelColor = AppColors.primary;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                decoration: BoxDecoration(
                  gradient: widget.active ? AppColors.primaryGradient : null,
                  color: widget.active ? null : Colors.transparent,
                  borderRadius: AppRadius.allMd,
                  boxShadow: widget.active
                      ? [
                          BoxShadow(
                            color: AppColors.primary
                                .withOpacity(widget.isDark ? 0.35 : 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.item.icon,
                  size: 22,
                  color:
                      widget.active ? activeIconColor : widget.inactiveColor,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        widget.active ? FontWeight.w700 : FontWeight.w500,
                    color: widget.active
                        ? activeLabelColor
                        : widget.inactiveColor,
                    letterSpacing: 0.1,
                  ),
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
