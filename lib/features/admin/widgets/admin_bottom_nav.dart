import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/widgets/glass/glass.dart';

/// Bottom navigation dock for the Admin Center shell.
///
/// Previously this assembled its own rounded `Container`, its own two-layer
/// drop shadow and its own `_NavItem` that animated horizontal padding and
/// revealed a label only while active — a second, slightly different dock
/// living alongside the storefront one.
///
/// It is now a thin wrapper over [GlassNavBar], exactly like
/// `core/widgets/app_bottom_nav.dart`, so the admin dock and the storefront
/// dock are the same material and the same shape.
class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        GlassNavItem(
          icon: AppIcons.chart_square,
          activeIcon: AppIcons.fill.chart_square,
          label: 'Dashboard',
        ),
        GlassNavItem(
          icon: AppIcons.people,
          activeIcon: AppIcons.fill.people,
          label: 'Users',
        ),
        GlassNavItem(
          icon: AppIcons.task_square,
          activeIcon: AppIcons.fill.task_square,
          label: 'Actions',
        ),
        GlassNavItem(
          icon: AppIcons.setting_2,
          activeIcon: AppIcons.fill.setting_2,
          label: 'Settings',
        ),
        GlassNavItem(
          icon: AppIcons.profile_circle,
          activeIcon: AppIcons.fill.profile_circle,
          label: 'Profile',
        ),
      ],
    );
  }
}
