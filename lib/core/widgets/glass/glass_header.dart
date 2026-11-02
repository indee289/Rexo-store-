import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_icon_button.dart';

/// iOS-style large-title header that collapses into a compact bar on scroll.
///
/// This is the app's primary navigation header; it replaces the old
/// centred-title-plus-hairline `AppBar` pattern everywhere.
///
/// Behaviour:
///   * **At rest** the bar is fully transparent — the canvas shows through, and
///     a large left-aligned title sits below the toolbar row.
///   * **On scroll** the large title slides up and fades out, the compact title
///     fades in on the toolbar row, and the bar's fill and shadow ramp in so it
///     separates from the content passing underneath.
///   * There is **no divider** at any point. Separation comes from the fill and
///     the soft shadow.
///
/// The transition previously animated a `BackdropFilter` sigma from 0 to 30.
/// Animating a blur means re-running a save-layer plus blur pass on every frame
/// of every scroll, which is the worst-case use of it; the fill now carries the
/// transition instead and costs nothing.
///
/// Use as the first sliver of a [CustomScrollView].
class GlassLargeTitleHeader extends StatelessWidget {
  const GlassLargeTitleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.bottomHeight = 0,
    this.largeTitleHeight = 58,
  });

  final String title;

  /// Rendered under the large title while expanded; hidden once collapsed.
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;

  /// Pinned content below the title row — a segmented control or search field.
  /// Stays visible when collapsed, so pass [bottomHeight] to reserve space.
  final Widget? bottom;
  final double bottomHeight;

  /// Height of the large-title band that collapses away.
  final double largeTitleHeight;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    Widget? resolvedLeading = leading;
    if (resolvedLeading == null &&
        (showBack ||
            (automaticallyImplyLeading && Navigator.of(context).canPop()))) {
      resolvedLeading = GlassIconButton(
        icon: AppIcons.arrow_left,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        size: 36,
        iconSize: 19,
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderDelegate(
        title: title,
        subtitle: subtitle,
        actions: actions,
        leading: resolvedLeading,
        bottom: bottom,
        bottomHeight: bottom == null ? 0 : bottomHeight,
        largeTitleHeight: largeTitleHeight,
        topInset: topInset,
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.leading,
    required this.bottom,
    required this.bottomHeight,
    required this.largeTitleHeight,
    required this.topInset,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottom;
  final double bottomHeight;
  final double largeTitleHeight;
  final double topInset;

  static const double _toolbar = 52;

  @override
  double get minExtent => topInset + _toolbar + bottomHeight;

  @override
  double get maxExtent => topInset + _toolbar + largeTitleHeight + bottomHeight;

  @override
  bool shouldRebuild(_HeaderDelegate old) =>
      old.title != title ||
      old.subtitle != subtitle ||
      old.bottomHeight != bottomHeight ||
      old.largeTitleHeight != largeTitleHeight ||
      old.topInset != topInset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final range = maxExtent - minExtent;
    // t: 0 = fully expanded, 1 = fully collapsed.
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);

    // The fill arrives slightly ahead of the title swap, so compact text never
    // sits over unfilled content.
    final settle = Curves.easeOut.transform((t * 1.3).clamp(0.0, 1.0));
    final largeOpacity = (1.0 - t * 1.6).clamp(0.0, 1.0);
    final compactOpacity = ((t - 0.45) / 0.45).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(settle),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(settle),
            width: AppGlass.borderWidth,
          ),
        ),
        boxShadow: settle < 0.98
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          SizedBox(height: topInset),
          // Toolbar row: leading, compact title, actions.
          SizedBox(
            height: _toolbar,
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.sm),
                if (leading != null) leading!,
                Expanded(
                  child: Opacity(
                    opacity: compactOpacity,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: leading == null ? AppSpacing.sm : 0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
          // Large-title band — collapses to zero height.
          if (largeTitleHeight > 0)
            SizedBox(
              height:
                  (largeTitleHeight * (1 - t)).clamp(0.0, largeTitleHeight),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minHeight: 0,
                  maxHeight: largeTitleHeight,
                  child: Opacity(
                    opacity: largeOpacity,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.largeTitle.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 31,
                              letterSpacing: -0.7,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.footnote.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (bottom != null) SizedBox(height: bottomHeight, child: bottom!),
        ],
      ),
    );
  }
}

/// A pinned search field for a header's [GlassLargeTitleHeader.bottom] slot.
class GlassHeaderSearch extends StatelessWidget {
  const GlassHeaderSearch({super.key, required this.child});

  final Widget child;

  static const double height = 60;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: child,
      ),
    );
  }
}
