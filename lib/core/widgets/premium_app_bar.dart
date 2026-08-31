import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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
    Widget? resolvedLeading = leading;
    final bool canPop = Navigator.of(context).canPop();
    if (resolvedLeading == null &&
        (showBack || (automaticallyImplyLeading && canPop))) {
      resolvedLeading = _CleanBackButton(
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        leading: resolvedLeading,
        automaticallyImplyLeading: false,
        actions: [
          if (actions != null) ...actions!,
          const SizedBox(width: 4),
        ],
        bottom: bottom,
        backgroundColor: Colors.transparent,
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
  const _CleanBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(
        Icons.chevron_left,
        size: 28,
        color: AppColors.textPrimary,
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
    final bool canPop = Navigator.of(context).canPop();
    Widget? leading;
    if (showBack || canPop) {
      leading = _CleanBackButton(
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return SliverAppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      leading: leading,
      automaticallyImplyLeading: false,
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: 4),
      ],
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      expandedHeight: flexibleSpace != null ? expandedHeight : null,
      pinned: pinned,
      floating: floating,
      flexibleSpace: flexibleSpace,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }
}
