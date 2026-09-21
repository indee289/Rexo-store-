import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// iOS-style tab bar.
///
/// Four tabs — Home, Campaigns, Jobs, Profile. Follows Apple's tab bar
/// conventions: white background, subtle top hairline, small icons above
/// tiny labels, active tab tinted with the app accent (emerald).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _Item(Iconsax.home_2, Iconsax.home_2, 'Home'),
    _Item(Iconsax.send_2, Iconsax.send_2, 'Campaigns'),
    _Item(Iconsax.briefcase, Iconsax.briefcase, 'Jobs'),
    _Item(Iconsax.user, Iconsax.user, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.separator, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(
              _items.length,
              (i) => Expanded(
                child: _TabItem(
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
  final IconData activeIcon;
  final String label;
  const _Item(this.icon, this.activeIcon, this.label);
}

class _TabItem extends StatefulWidget {
  final _Item item;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color tint =
        widget.active ? AppColors.primary : AppColors.systemGray;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.6 : 1.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.active ? widget.item.activeIcon : widget.item.icon,
              size: 25,
              color: tint,
            ),
            const SizedBox(height: 3),
            Text(
              widget.item.label,
              style: AppTextStyles.caption2.copyWith(
                color: tint,
                fontWeight:
                    widget.active ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
