import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_nav.dart';
import 'glass/glass.dart';

/// App shell — bottom nav only. NO paywall gate here.
///
/// The app is freely accessible to all users. The subscription paywall
/// is enforced ONLY at the point of campaign/job application (Apply button).
/// Admin users are never paywalled.
///
/// The shell now sits on a [GlassScaffold], which paints the ambient glass
/// backdrop behind the branch content and the floating dock so the dock has a
/// real colour field to refract.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      // `extendBody` stays false for now: the dock's height is still reserved,
      // so no branch screen can hide content underneath it. It is flipped to
      // true per screen, together with that screen's bottom padding, as each
      // one is migrated to the glass layout.
      extendBody: false,
      extendBodyBehindAppBar: false,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
