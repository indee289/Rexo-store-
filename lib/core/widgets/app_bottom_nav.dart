import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../icons/app_icons.dart';
import 'glass/glass.dart';

/// The app's bottom navigation — a floating pill-shaped glass dock.
///
/// Thin wrapper that supplies this app's four destinations to [GlassNavBar].
/// Destination order and indices are unchanged, so the router's
/// `StatefulShellBranch` ordering (home, campaigns, jobs, profile) still maps
/// one-to-one and no navigation behaviour shifts.
///
/// Previously this widget assembled its own `ClipRRect` + `BackdropFilter` +
/// `Container` dock with hardcoded warm-white colours. All of that now lives in
/// [GlassNavBar], so the dock shares one material with the rest of the app.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Labels come from the existing ARB bundle, so the dock reads correctly in
    // both English and Hindi.
    final l10n = AppLocalizations.of(context);

    return GlassNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        GlassNavItem(
          icon: AppIcons.home_2,
          activeIcon: AppIcons.fill.home_2,
          label: l10n.home,
        ),
        GlassNavItem(
          icon: AppIcons.volume_high,
          activeIcon: AppIcons.fill.volume_high,
          label: l10n.campaigns,
        ),
        GlassNavItem(
          icon: AppIcons.briefcase,
          activeIcon: AppIcons.fill.briefcase,
          label: l10n.jobs,
        ),
        GlassNavItem(
          icon: AppIcons.user,
          activeIcon: AppIcons.fill.user,
          label: l10n.profile,
        ),
      ],
    );
  }
}
