import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import 'glass_surface.dart';

/// Segmented glass tab bar.
///
/// A frosted track holding a brand-red glass pill that slides to the selected
/// segment. Used instead of Material's underline [TabBar]: an underline
/// indicator disappears against a translucent pane, whereas a sliding pill
/// stays legible.
///
/// Drop-in for a `TabBar` inside a `DefaultTabController` — pass the
/// controller and it stays in sync, or drive it manually with
/// [selectedIndex] + [onSelected].
class GlassTabBar extends StatefulWidget implements PreferredSizeWidget {
  const GlassTabBar({
    super.key,
    required this.labels,
    this.controller,
    this.selectedIndex,
    this.onSelected,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> labels;

  /// When supplied, the bar reads and drives this controller.
  final TabController? controller;

  /// Manual selection, used when [controller] is null.
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;
  final EdgeInsetsGeometry margin;

  static const double _height = 46;

  @override
  Size get preferredSize => const Size.fromHeight(_height + 16);

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar> {
  int _manualIndex = 0;

  @override
  void initState() {
    super.initState();
    _manualIndex = widget.selectedIndex ?? 0;
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(GlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
    if (widget.selectedIndex != null &&
        widget.selectedIndex != oldWidget.selectedIndex) {
      _manualIndex = widget.selectedIndex!;
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  int get _index => widget.controller?.index ?? _manualIndex;

  void _select(int i) {
    if (widget.controller != null) {
      widget.controller!.animateTo(i);
    } else {
      setState(() => _manualIndex = i);
    }
    widget.onSelected?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.labels.length;

    return Padding(
      padding: widget.margin.add(const EdgeInsets.symmetric(vertical: 8)),
      child: GlassSurface(
        level: GlassLevel.subtle,
        borderRadius: AppRadius.pillAll,
        height: GlassTabBar._height,
        tint: AppGlass.recessed(false),
        padding: const EdgeInsets.all(4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 8 = the 4px padding on each side applied above.
            final slot = (constraints.maxWidth) / count;

            return Stack(
              children: [
                // Sliding brand pill.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: slot * _index,
                  top: 0,
                  bottom: 0,
                  width: slot,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppRadius.pillAll,
                      boxShadow: AppElevation.brand(false),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (int i = 0; i < count; i++)
                      Expanded(
                        child: _Segment(
                          label: widget.labels[i],
                          active: i == _index,
                          onTap: () => _select(i),
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

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            style: AppTextStyles.labelMedium.copyWith(
              color: active ? AppColors.textOnPrimary : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
