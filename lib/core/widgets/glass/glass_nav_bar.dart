import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import 'glass_surface.dart';

/// One destination in a [GlassNavBar].
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;
}

/// Floating pill-shaped glass dock.
///
/// Sits above the bottom safe area with horizontal margin so the page scrolls
/// visibly behind and underneath it. The active destination is marked by a
/// brand-red glass capsule that slides between slots, and only the active
/// label is shown — which keeps the dock compact while still naming the
/// current section for screen readers and new users.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  static const double _height = 66;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 12),
      child: GlassSurface(
        level: GlassLevel.modal,
        borderRadius: AppRadius.pillAll,
        height: _height,
        tint: AppGlass.dock(false),
        shadow: AppElevation.raised(false),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: _NavSlot(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavSlot extends StatefulWidget {
  const _NavSlot({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavSlot> createState() => _NavSlotState();
}

class _NavSlotState extends State<_NavSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _scale = _press.drive(
    Tween<double>(begin: 1.0, end: 0.88)
        .chain(CurveTween(curve: Curves.easeOutCubic)),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final color = active ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: active,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                // Brand capsule behind the active destination.
                color: active
                    ? AppColors.primary.withOpacity(0.14)
                    : Colors.transparent,
                borderRadius: AppRadius.pillAll,
                border: Border.all(
                  color: active
                      ? AppColors.primary.withOpacity(0.28)
                      : Colors.transparent,
                  width: AppGlass.borderWidth,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconWithBadge(
                    icon: active ? widget.item.activeIcon : widget.item.icon,
                    color: color,
                    badgeCount: widget.item.badgeCount,
                  ),
                  // Label animates in only for the active destination.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: active
                        ? Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              widget.item.label,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              softWrap: false,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.color,
    this.badgeCount,
  });

  final IconData icon;
  final Color color;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 23, color: color);
    if (badgeCount == null || badgeCount! <= 0) return iconWidget;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          top: -3,
          right: -4,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
            ),
            child: Center(
              child: Text(
                badgeCount! > 99 ? '99+' : '${badgeCount!}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
