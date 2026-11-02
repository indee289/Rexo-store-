import 'package:flutter/material.dart';

import 'glass_backdrop.dart';

/// A [Scaffold] wired for liquid glass.
///
/// Three things differ from a plain `Scaffold`, and all three are required for
/// glass to render correctly:
///
///   * The scaffold background is **transparent** and a [GlassBackdrop] is
///     painted behind the whole stack, so panes have a colour field to refract.
///   * `extendBody` and `extendBodyBehindAppBar` default to **true**, so the
///     glass app bar and glass nav bar have live content sliding underneath
///     them instead of an opaque gap.
///   * The body is padded by the app bar's height when one is supplied, since
///     `extendBodyBehindAppBar` otherwise puts content under the bar.
///
/// Use this instead of `Scaffold` on every screen.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.extendBody = true,
    this.extendBodyBehindAppBar = true,
    this.resizeToAvoidBottomInset,
    this.showBlobs = true,
    this.padBodyForAppBar = true,
    this.bottomSheet,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;
  final Widget? bottomSheet;

  /// Paint the ambient colour blobs. Disable on full-bleed media screens.
  final bool showBlobs;

  /// Insets [body] by the app bar height. Set false when the body is a
  /// `CustomScrollView` that should scroll *under* the bar.
  final bool padBodyForAppBar;

  @override
  Widget build(BuildContext context) {
    Widget? resolvedBody = body;

    if (resolvedBody != null &&
        appBar != null &&
        extendBodyBehindAppBar &&
        padBodyForAppBar) {
      // `GlassAppBar.preferredSize` reports the toolbar height only — the same
      // convention Flutter's own `AppBar` uses — while the bar also renders the
      // status-bar strip. Scaffold therefore lays it out at
      // `preferredSize.height + padding.top`, and the body must clear both.
      resolvedBody = Padding(
        padding: EdgeInsets.only(
          top: appBar!.preferredSize.height +
              MediaQuery.of(context).padding.top,
        ),
        child: resolvedBody,
      );
    }

    return GlassBackdrop(
      showBlobs: showBlobs,
      child: Scaffold(
        // Transparent so the backdrop above shows through the glass panes.
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: resolvedBody,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        drawer: drawer,
        endDrawer: endDrawer,
        bottomSheet: bottomSheet,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }
}
