import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Instagram-style navigation bar.
///
/// White background with a hairline bottom border. Bold title on the left
/// (or centered when there's a back button), action icons on the right.
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
        kToolbarHeight + (bottom?.preferredSize.height ?? 0) + 0.5,
      );

  @override
  Widget build(BuildContext context) {
    Widget? resolvedLeading = leading;
    final bool canPop = Navigator.of(context).canPop();
    if (resolvedLeading == null &&
        (showBack || (automaticallyImplyLeading && canPop))) {
      resolvedLeading = _BackButton(
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: AppTextStyles.title3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: resolvedLeading,
        automaticallyImplyLeading: false,
        actions: [
          if (actions != null) ...actions!,
          const SizedBox(width: 8),
        ],
        bottom: bottom,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
    );
  }
}

/// Instagram-style back button — thin left arrow, no chrome.
class _BackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
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
          child: Icon(
            Iconsax.arrow_left,
            size: 24,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Sliver version — for scroll-collapsing headers.
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
      leading = _BackButton(
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
        const SizedBox(width: 8),
      ],
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
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
