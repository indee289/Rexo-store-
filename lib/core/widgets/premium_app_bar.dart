import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// iOS-style navigation bar.
///
/// Transparent background over the systemGroupedBackground scaffold, centered
/// 17pt semibold title, iOS chevron back button that says the parent screen
/// name style (here: just the chevron), and green tinted actions.
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
    Widget? resolvedLeading = leading;
    final bool canPop = Navigator.of(context).canPop();
    if (resolvedLeading == null &&
        (showBack || (automaticallyImplyLeading && canPop))) {
      resolvedLeading = _IosBackButton(
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: resolvedLeading,
      leadingWidth: resolvedLeading is _IosBackButton ? 60 : null,
      automaticallyImplyLeading: false,
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
      bottom: bottom,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    );
  }
}

/// iOS-style chevron back button — accent-colored, no ripple.
class _IosBackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _IosBackButton({required this.onTap});

  @override
  State<_IosBackButton> createState() => _IosBackButtonState();
}

class _IosBackButtonState extends State<_IosBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.4 : 1.0,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.arrow_left_2,
                size: 24,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sliver version — used for large-title scroll effects.
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
    final bool canPop = Navigator.of(context).canPop();
    Widget? leading;
    if (showBack || canPop) {
      leading = _IosBackButton(
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return SliverAppBar(
      title: Text(
        title,
        style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: leading,
      leadingWidth: leading != null ? 60 : null,
      automaticallyImplyLeading: false,
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.primary,
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
