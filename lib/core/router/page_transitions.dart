import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_motion.dart';

/// Token-driven page transitions for `go_router` pushed (non-shell) routes.
///
/// Implements the design's "Page transition strategy":
/// - **Detail pushes** (campaign detail, creator profile, chat) use a
///   shared-axis horizontal transition (`slideX + fadeThrough`) over
///   [AppMotion.base] — see [sharedAxisPage].
/// - **Modal-ish pushes** (create campaign, apply) use a slide-up transition —
///   see [slideUpPage].
///
/// Tab switches deliberately have no transition: they are handled by
/// `StatefulShellRoute.indexedStack`, which preserves each tab's scroll
/// position and widget state. These helpers are only for routes pushed on top
/// of the shell, so adopting them does not affect tab preservation.
///
/// Usage in a [GoRoute]:
/// ```dart
/// GoRoute(
///   path: AppRoutes.campaignDetail,
///   pageBuilder: (context, state) => sharedAxisPage(
///     key: state.pageKey,
///     child: CampaignDetailScreen(campaignId: state.pathParameters['id']!),
///   ),
/// );
/// ```

/// Shared-axis horizontal transition for detail pushes.
///
/// The incoming route slides in from the trailing edge (`slideX`) while fading
/// through; on pop it reverses with the [AppMotion.exit] curve. Runs over
/// [AppMotion.base] by default.
CustomTransitionPage<T> sharedAxisPage<T>({
  required Widget child,
  LocalKey? key,
  String? name,
  Object? arguments,
  String? restorationId,
  Duration duration = AppMotion.base,
  double slideBegin = 0.20,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.standard,
        reverseCurve: AppMotion.exit,
      );

      final Animation<Offset> slide = Tween<Offset>(
        begin: Offset(slideBegin, 0),
        end: Offset.zero,
      ).animate(curved);

      return SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}

/// Slide-up transition for modal-ish pushes (e.g. create campaign, apply).
///
/// The incoming route rises from the bottom edge and fades in over
/// [AppMotion.base] by default. [slideBegin] is the initial vertical offset as
/// a fraction of the screen height (`1.0` = full-height modal, smaller values
/// give a subtler lift).
CustomTransitionPage<T> slideUpPage<T>({
  required Widget child,
  LocalKey? key,
  String? name,
  Object? arguments,
  String? restorationId,
  Duration duration = AppMotion.base,
  double slideBegin = 1.0,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.emphasized,
        reverseCurve: AppMotion.exit,
      );

      final Animation<Offset> slide = Tween<Offset>(
        begin: Offset(0, slideBegin),
        end: Offset.zero,
      ).animate(curved);

      return SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}
