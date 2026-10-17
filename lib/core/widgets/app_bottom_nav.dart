import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Instagram iOS-style floating dock nav bar.
///
/// A pill-shaped frosted-glass dock floating above the bottom edge with
/// horizontal margin and a subtle shadow. Icons are black, active icon is
/// slightly bolder/filled. No labels (like IG). BackdropFilter gives the
/// frosted translucent look.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _Item(inactive: Iconsax.home_2, active: Iconsax.home_2),
    _Item(inactive: Iconsax.send_2, active: Iconsax.send_2),
    _Item(inactive: Iconsax.briefcase, active: Iconsax.briefcase),
    _Item(inactive: Iconsax.user, active: Iconsax.user),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      // Float above the bottom edge — 12px above the safe area
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 12),
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              // Semi-transparent warm white — frosted glass on sand dune bg
              color: const Color(0xFFFAF8F3).withOpacity(0.88),
              borderRadius: AppRadius.pillAll,
              border: Border.all(
                color: AppColors.border.withOpacity(0.5),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Center(
            child: Icon(
              widget.active ? widget.item.active : widget.item.inactive,
              size: widget.active ? 28 : 26,
              color: widget.active
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
