import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';

/// Instagram-style bottom nav bar.
///
/// White background with a 0.5px top hairline. Outlined icons in black,
/// filled icons when active. No labels (like Instagram). Bigger icons.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Instagram uses:  Home  Search  Reels  Shop  Profile
  // We map to Rexo:  Home  Campaigns Jobs  Profile (4 tabs).
  static const _items = [
    _Item(
      inactive: Iconsax.home_2,
      active: Iconsax.home_2,
    ),
    _Item(
      inactive: Iconsax.send_2,
      active: Iconsax.send_2,
    ),
    _Item(
      inactive: Iconsax.briefcase,
      active: Iconsax.briefcase,
    ),
    _Item(
      inactive: Iconsax.user,
      active: Iconsax.user,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
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
  final IconData inactive;
  final IconData active;
  const _Item({required this.inactive, required this.active});
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.5 : 1.0,
        child: Center(
          child: Icon(
            widget.active ? widget.item.active : widget.item.inactive,
            size: 28,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
