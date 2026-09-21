import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';

/// Clean Instagram-style AppBar.
/// White background, 0 elevation, 1px bottom border, title 18px w600 centered.
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final fg = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    Widget? resolvedLeading = leading;
    final bool canPop = Navigator.of(context).canPop();
    if (resolvedLeading == null &&
        (showBack || (automaticallyImplyLeading && canPop))) {
      resolvedLeading = _CleanBackButton(
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
        color: fg,
      );
    }

    return Container(
      color: bg,
      child: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: resolvedLeading,
        automaticallyImplyLeading: false,
        actions: [
          if (actions != null) ...actions!,
          const SizedBox(width: 4),
        ],
        bottom: bottom,
        backgroundColor: Colors.transparent,
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
    );
  }
}

class _CleanBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color? color;
  const _CleanBackButton({required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        Iconsax.arrow_left,
        size: 24,
        color: color ?? AppColors.textPrimary,
      ),
    );
  }
}

/// Sliver version of the clean AppBar.
class PremiumSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? flexibleSpace;
  final double expandedHeight;
  final bool pinned;
  final bool floating;

  const PremiumSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.onBack,
    this.flexibleSpace,
    this.expandedHeight = 200,
    this.pinned = true,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final fg = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    final bool canPop = Navigator.of(context).canPop();
    Widget? leading;
    if (showBack || canPop) {
      leading = _CleanBackButton(
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
        color: fg,
      );
    }

    return SliverAppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: -0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: leading,
      automaticallyImplyLeading: false,
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: 4),
      ],
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      expandedHeight: flexibleSpace != null ? expandedHeight : null,
      pinned: pinned,
      floating: floating,
      flexibleSpace: flexibleSpace,
    );
  }
}
