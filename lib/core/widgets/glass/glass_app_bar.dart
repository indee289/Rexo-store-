import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_icon_button.dart';

/// Fixed navigation bar.
///
/// Prefer [GlassLargeTitleHeader], which gives the iOS large title that
/// collapses on scroll. Use this only where a screen genuinely needs a static
/// bar — a modal step, or a screen whose body is not scrollable.
///
/// The bar is an opaque surface with a hairline bottom edge and no elevation
/// until content scrolls under it. The previous version ran a `BackdropFilter`
/// over the whole bar and painted a specular sheen; both are removed.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.centerTitle = false,
    this.titleWidget,
    this.transparent = false,
  });

  final String title;

  /// Replaces the [title] text entirely (e.g. with a search field).
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  /// Left-aligned by default. Centre only for modal-style screens.
  final bool centerTitle;

  /// Draw no fill or edge — for a bar over full-bleed imagery.
  final bool transparent;

  static const double _barHeight = 52;

  @override
  Size get preferredSize =>
      Size.fromHeight(_barHeight + (bottom?.preferredSize.height ?? 0));

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

    final Widget titleContent = titleWidget ??
        Text(
          title,
          style: AppTextStyles.title3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: centerTitle ? TextAlign.center : TextAlign.start,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : AppColors.surface,
        border: transparent
            ? null
            : const Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: AppGlass.borderWidth,
                ),
              ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topInset),
          SizedBox(
            height: _barHeight,
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.sm),
                if (resolvedLeading != null) resolvedLeading,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: resolvedLeading == null
                          ? AppSpacing.sm
                          : AppSpacing.xs,
                      right: AppSpacing.xs,
                    ),
                    child: Align(
                      alignment: centerTitle
                          ? Alignment.center
                          : Alignment.centerLeft,
                      child: titleContent,
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

/// Sliver bar with a collapsing image/content header.
///
/// For a plain collapsing title use [GlassLargeTitleHeader] instead.
class GlassSliverAppBar extends StatelessWidget {
  const GlassSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.onBack,
    this.flexibleSpace,
    this.expandedHeight = 220,
    this.pinned = true,
    this.floating = false,
    this.centerTitle = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? flexibleSpace;
  final double expandedHeight;
  final bool pinned;
  final bool floating;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    Widget? leading;
    if (showBack || Navigator.of(context).canPop()) {
      leading = GlassIconButton(
        icon: AppIcons.arrow_left,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        size: 36,
        iconSize: 19,
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return SliverAppBar(
      title: Text(
        title,
        style: AppTextStyles.title3.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: leading,
      automaticallyImplyLeading: false,
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: AppSpacing.sm),
      ],
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      expandedHeight: flexibleSpace == null ? null : expandedHeight,
      pinned: pinned,
      floating: floating,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.bottomXl,
      ),
      flexibleSpace: flexibleSpace,
    );
  }
}
