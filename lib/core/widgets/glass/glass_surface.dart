import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';

/// Marks the subtree of a glass surface that has **already** applied a
/// [BackdropFilter].
///
/// Nested `BackdropFilter`s are the single biggest performance trap in a glass
/// UI: each one forces another full-screen save-layer + blur pass, so a card
/// inside a sheet inside a scaffold would blur three times per frame for no
/// visual gain (the inner blur samples the already-blurred output).
///
/// [GlassSurface] reads this scope and, when it finds one, renders tint + sheen
/// + rim **without** a second blur. The result is visually equivalent and costs
/// one blur instead of N.
class GlassBlurScope extends InheritedWidget {
  const GlassBlurScope({super.key, required super.child});

  /// True when an ancestor already blurs this subtree.
  static bool isBlurred(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassBlurScope>() != null;

  @override
  bool updateShouldNotify(GlassBlurScope oldWidget) => false;
}

/// How heavy a glass pane's blur and tint should be.
enum GlassLevel {
  /// Chips, icon buttons, inline pills — light blur.
  subtle,

  /// Cards, tiles, list rows — the default.
  card,

  /// App bars, nav bars, section panes.
  surface,

  /// Sheets and dialogs — heaviest blur, strongest lift.
  modal,
}

/// The one true liquid-glass pane.
///
/// Every other `Glass*` widget composes this, so the material is defined in
/// exactly one place. Layers, in paint order:
///
///   1. [BackdropFilter] blur — skipped when inside a [GlassBlurScope].
///   2. Translucent tint.
///   3. Specular sheen fading from the top edge.
///   4. 1px rim + a brighter top-edge rim light.
///
/// Set [interactive] (via [onTap]) to get the spring press animation.
class GlassSurface extends StatefulWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.level = GlassLevel.card,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.tint,
    this.rim,
    this.shadow,
    this.gradient,
    this.showSheen = true,
    this.showRimHighlight = true,
    this.width,
    this.height,
    this.constraints,
    this.alignment,
    this.clipBehavior = Clip.antiAlias,
    this.semanticLabel,
  });

  final Widget child;
  final GlassLevel level;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Overrides the level's default tint.
  final Color? tint;

  /// Overrides the level's default rim colour.
  final Color? rim;

  /// Overrides the level's default shadow stack.
  final List<BoxShadow>? shadow;

  /// Paints a gradient instead of a flat [tint].
  final Gradient? gradient;

  final bool showSheen;
  final bool showRimHighlight;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final String? semanticLabel;

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    reverseDuration: const Duration(milliseconds: 260),
  );

  // A gentle spring: overshoots very slightly on release so the press feels
  // physical rather than linear.
  late final Animation<double> _scale = _press.drive(
    Tween<double>(begin: 1.0, end: 0.972)
        .chain(CurveTween(curve: Curves.easeOutCubic)),
  );

  bool get _tappable => widget.onTap != null || widget.onLongPress != null;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  double get _blurSigma {
    switch (widget.level) {
      case GlassLevel.subtle:
        return AppGlass.blurSigmaSubtle;
      case GlassLevel.card:
        return AppGlass.blurSigma;
      case GlassLevel.surface:
        return AppGlass.blurSigma;
      case GlassLevel.modal:
        return AppGlass.blurSigmaModal;
    }
  }

  Color get _tint {
    if (widget.tint != null) return widget.tint!;
    switch (widget.level) {
      case GlassLevel.subtle:
        return AppColors.surfaceAlt;
      case GlassLevel.card:
        return AppColors.card;
      case GlassLevel.surface:
      case GlassLevel.modal:
        return AppColors.surface;
    }
  }

  List<BoxShadow> get _shadow {
    if (widget.shadow != null) return widget.shadow!;
    switch (widget.level) {
      case GlassLevel.subtle:
        return const [];
      case GlassLevel.card:
        return AppElevation.card(false);
      case GlassLevel.surface:
        return AppElevation.raised(false);
      case GlassLevel.modal:
        return AppElevation.modal(false);
    }
  }

  BorderRadius get _radius {
    if (widget.borderRadius != null) return widget.borderRadius!;
    switch (widget.level) {
      case GlassLevel.subtle:
        return AppRadius.allSm;
      case GlassLevel.card:
        return AppRadius.allLg;
      case GlassLevel.surface:
        return AppRadius.allLg;
      case GlassLevel.modal:
        return AppRadius.allXl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = _radius;
    final alreadyBlurred = GlassBlurScope.isBlurred(context);

    // ── Layers 2-4: tint, sheen, rim ────────────────────────────────────────
    Widget pane = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.gradient == null ? _tint : null,
        gradient: widget.gradient,
        borderRadius: radius,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Specular sheen — curved-glass cue.
          if (widget.showSheen)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: AppGlass.sheen,
                  ),
                ),
              ),
            ),
          // Top-edge rim light.
          if (widget.showRimHighlight)
            Positioned(
              top: 0,
              left: radius.topLeft.x,
              right: radius.topRight.x,
              height: AppGlass.borderWidth,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: AppGlass.rimHighlight,
                  ),
                ),
              ),
            ),
          // Content.
          Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: widget.child,
          ),
          // Hairline rim, painted last so content cannot cover it.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: widget.rim ?? AppGlass.border(false),
                    width: AppGlass.borderWidth,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // ── Layer 1: blur (only if no ancestor already blurred us) ──────────────
    pane = ClipRRect(
      borderRadius: radius,
      clipBehavior: widget.clipBehavior,
      child: alreadyBlurred
          ? pane
          : GlassBlurScope(
              child: BackdropFilter(
                filter: AppGlass.blurOf(_blurSigma),
                child: pane,
              ),
            ),
    );

    // Shadow must sit outside the clip or it gets clipped away.
    Widget result = DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: _shadow),
      child: pane,
    );

    if (widget.width != null ||
        widget.height != null ||
        widget.constraints != null ||
        widget.alignment != null) {
      result = Container(
        width: widget.width,
        height: widget.height,
        constraints: widget.constraints,
        alignment: widget.alignment,
        child: result,
      );
    }

    if (widget.margin != null) {
      result = Padding(padding: widget.margin!, child: result);
    }

    if (_tappable) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: ScaleTransition(scale: _scale, child: result),
      );
    }

    if (widget.semanticLabel != null) {
      result = Semantics(
        label: widget.semanticLabel,
        button: _tappable,
        child: result,
      );
    }

    return result;
  }
}
