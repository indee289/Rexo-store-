import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_icon_button.dart';
import 'glass_surface.dart';

/// iOS-style large-title header that collapses into a glass bar on scroll.
///
/// This replaces the old centred-title `AppBar` + hairline-divider pattern
/// everywhere. Behaviour, matching iOS:
///
///   * **At rest** the bar is *transparent* — the page's own content and the
///     ambient backdrop show through, with a large left-aligned title below the
///     toolbar row.
///   * **On scroll** the large title slides up and fades out, the compact title
///     fades in on the toolbar row, and the pane's frost ramps from clear to
///     fully frosted. The frost appearing only once content is underneath is
///     what makes the bar read as glass rather than as a coloured strip.
///   * There is **no bottom divider** at any point. Separation comes from the
///     frost and the specular rim.
///
/// Use inside a [CustomScrollView] as the first sliver:
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     GlassLargeTitleHeader(title: 'Wallet', actions: [...]),
///     ...
///   ],
/// )
/// ```
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
    this.largeTitleHeight = 60,
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
        icon: Iconsax.arrow_left,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        size: 36,
        iconSize: 19,
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return SliverPersistentHeader(
      pinned: true,
      delegate: _GlassHeaderDelegate(
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

class _GlassHeaderDelegate extends SliverPersistentHeaderDelegate {
  _GlassHeaderDelegate({
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
  double get maxExtent =>
      topInset + _toolbar + largeTitleHeight + bottomHeight;

  @override
  bool shouldRebuild(_GlassHeaderDelegate old) =>
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

    // Frost ramps in slightly ahead of the title swap so the bar never shows
    // compact text over unfrosted content.
    final frost = Curves.easeOut.transform(math.min(1.0, t * 1.25));
    final largeOpacity = (1.0 - t * 1.6).clamp(0.0, 1.0);
    final compactOpacity = ((t - 0.45) / 0.45).clamp(0.0, 1.0);

    return ClipRect(
      child: BackdropFilter(
        // Blur sigma scales with collapse: no blur at rest (nothing is behind
        // the bar yet), full modal blur once content slides underneath.
        filter: ui.ImageFilter.blur(
          sigmaX: AppGlass.blurSigmaModal * frost,
          sigmaY: AppGlass.blurSigmaModal * frost,
        ),
        child: GlassBlurScope(
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Scale the pane tint by the collapse amount so the bar starts
              // fully clear and frosts in as content slides under it.
              color: Colors.white
                  .withOpacity(AppGlass.surfaceOpacity * frost),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Positioned must be a direct child of Stack, so the Opacity
                // goes inside it rather than wrapping it.
                Positioned.fill(
                  child: Opacity(
                    opacity: frost,
                    child: const GlassSheen(),
                  ),
                ),
                Column(
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
                        height: (largeTitleHeight * (1 - t))
                            .clamp(0.0, largeTitleHeight),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTextStyles.largeTitle.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 32,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.footnote
                                            .copyWith(
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
                    if (bottom != null)
                      SizedBox(height: bottomHeight, child: bottom!),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
