import 'package:flutter/material.dart';

import 'glass/glass.dart';

/// **Migration shim.** Use [GlassAppBar] directly.
///
/// Forwards to [GlassAppBar]. The old treatment (opaque sand-coloured bar,
/// 0.5px grey bottom border, Material `AppBar` inside a `Container`) is gone;
/// every bar is now a blurred translucent pane that page content scrolls
/// under.
///
/// Scheduled for deletion once every call-site is migrated.
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
    return GlassAppBar(
      title: title,
      actions: actions,
      leading: leading,
      showBack: showBack,
      onBack: onBack,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
    );
  }
}

/// **Migration shim.** Use [GlassSliverAppBar] directly.
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
    return GlassSliverAppBar(
      title: title,
      actions: actions,
      showBack: showBack,
      onBack: onBack,
      flexibleSpace: flexibleSpace,
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
    );
  }
}
