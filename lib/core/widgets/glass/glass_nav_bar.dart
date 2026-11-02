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

/// Floating pill-shaped glass dock with a sliding indicator.
///
/// ### Overflow safety
/// The previous version laid each destination out as a horizontal
/// `Row(mainAxisSize: min)` of icon + label inside an `Expanded`. That row
/// sizes to its content but is handed a *tight* slot width, so any label wider
/// than the remaining space overflowed: on a 360dp screen each slot is ~78px
/// while "Campaigns" plus its icon and padding needed ~109px, which clipped the
/// label and bled into the neighbouring slot.
///
/// This version makes overflow structurally impossible:
///   * every slot is an explicit `SizedBox(width: slotWidth)` rather than an
///     `Expanded` wrapping an intrinsically-sized row, so a slot can never be
///     asked to paint wider than its share of the bar;
///   * icon and label stack **vertically**, so the label gets the slot's full
///     width instead of competing with the icon for it;
///   * the label is wrapped in a `FittedBox(scaleDown)` with `maxLines: 1` and
///     ellipsis, so a long label shrinks (and finally truncates) inside the
///     slot instead of pushing past it.
///
/// The sliding indicator is a single capsule positioned over the active slot
/// and animated with `AnimatedPositioned`, so it is always exactly one slot
/// wide by construction.
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

  static const double _height = 68;
  static const double _inset = 6;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final count = items.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset + 10),
      child: GlassSurface(
        level: GlassLevel.modal,
        borderRadius: AppRadius.pillAll,
        height: _height,
        tint: AppGlass.dock(false),
        shadow: AppElevation.raised(false),
        padding: const EdgeInsets.all(_inset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The padding above is already removed from maxWidth, so this is
            // the exact width available to the slots.
            final slot = constraints.maxWidth / count;
            final index = currentIndex.clamp(0, count - 1);

            return Stack(
              children: [
                // Sliding indicator — one slot wide, by construction.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: slot * index,
                  top: 0,
                  bottom: 0,
                  width: slot,
                  child: const _SlidingIndicator(),
                ),
                Row(
                  children: [
                    for (int i = 0; i < count; i++)
                      SizedBox(
                        width: slot,
                        child: _NavSlot(
                          item: items[i],
                          active: i == index,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The brand-tinted capsule that slides between destinations.
///
/// No `BackdropFilter` here: [GlassNavBar]'s surface already established a
/// blur scope, and a second blur would cost another save-layer every frame
/// while the indicator animates.
class _SlidingIndicator extends StatelessWidget {
  const _SlidingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0x2E8B1A1A), Color(0x1FA52020)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: AppRadius.pillAll,
          border: Border.fromBorderSide(
            BorderSide(color: Color(0x4D8B1A1A), width: 1),
          ),
        ),
        child: GlassSheen(radius: AppRadius.pillAll),
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
    Tween<double>(begin: 1.0, end: 0.90)
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconWithBadge(
                icon: active ? widget.item.activeIcon : widget.item.icon,
                color: color,
                badgeCount: widget.item.badgeCount,
              ),
              const SizedBox(height: 3),
              // Horizontal padding keeps the label clear of the capsule's
              // rounded ends; FittedBox guarantees it fits whatever is left.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption2.copyWith(
                      color: color,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      height: 1.1,
                    ),
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
    final iconWidget = Icon(icon, size: 22, color: color);
    if (badgeCount == null || badgeCount! <= 0) return iconWidget;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          top: -3,
          right: -5,
          child: Container(
            constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              border: const Border.fromBorderSide(
                BorderSide(color: Colors.white, width: 1.5),
              ),
            ),
            child: Center(
              child: Text(
                badgeCount! > 9 ? '9+' : '${badgeCount!}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
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
