import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_icon_button.dart';
import 'glass_surface.dart';

/// Frosted navigation bar.
///
/// Content scrolls *underneath* it (pair with `GlassScaffold`, which sets
/// `extendBodyBehindAppBar`), so the bar refracts the page as you scroll. The
/// bottom edge is a hairline rim rather than a Material divider, and the title
/// is centred with glass icon buttons on either side.
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
    this.centerTitle = true,
    this.titleWidget,
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
  final bool centerTitle;

  static const double _barHeight = kToolbarHeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(_barHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    Widget? resolvedLeading = leading;
    if (resolvedLeading == null &&
        (showBack || (automaticallyImplyLeading && Navigator.of(context).canPop()))) {
      resolvedLeading = GlassIconButton(
        icon: Iconsax.arrow_left,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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

    final Widget bar = SizedBox(
      height: _barHeight,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.sm),
          if (resolvedLeading != null) resolvedLeading,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: resolvedLeading == null ? AppSpacing.sm : AppSpacing.xs,
                right: AppSpacing.xs,
              ),
              child: Align(
                alignment:
                    centerTitle ? Alignment.center : Alignment.centerLeft,
                child: titleContent,
              ),
            ),
          ),
          if (actions != null) ...actions!,
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );

    // One blur for the whole bar, including the status-bar strip above it.
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: AppGlass.blurSigmaModal,
          sigmaY: AppGlass.blurSigmaModal,
        ),
        child: GlassBlurScope(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppGlass.surface(false),
              border: const Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: AppGlass.borderWidth,
                ),
              ),
            ),
            child: Stack(
              children: [
                // Specular sheen across the bar.
                const Positioned.fill(child: GlassSheen()),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: topInset),
                    bar,
                    if (bottom != null) bottom!,
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

/// Sliver variant — for screens with a collapsing glass header.
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
    this.centerTitle = true,
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
        icon: Iconsax.arrow_left,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
      // The glass itself is painted by flexibleSpace's backdrop filter below.
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      // Only grow into a collapsing header when the caller supplied one.
      expandedHeight: flexibleSpace == null ? null : expandedHeight,
      pinned: pinned,
      floating: floating,
      // The blurred pane is always present; it carries the caller's header
      // content when there is any, and is a bare glass background otherwise.
      flexibleSpace: _GlassBarBackground(
        child: flexibleSpace ?? const SizedBox.expand(),
      ),
    );
  }
}

/// Blurred translucent background used behind a sliver app bar.
class _GlassBarBackground extends StatelessWidget {
  const _GlassBarBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: AppGlass.blurSigmaModal,
          sigmaY: AppGlass.blurSigmaModal,
        ),
        child: GlassBlurScope(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppGlass.surface(false),
              border: const Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: AppGlass.borderWidth,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
