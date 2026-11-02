import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';

/// How prominent a surface should be.
enum GlassLevel {
  /// Chips, icon buttons, inline pills — recessed fill, no shadow.
  subtle,

  /// Cards, tiles, grouped sections — the default.
  card,

  /// Bars and section panels.
  surface,

  /// Sheets and dialogs — the heaviest lift.
  modal,
}

/// The app's one surface primitive.
///
/// Every other component composes this, so the material is defined in exactly
/// one place. Three layers:
///
///   1. an opaque fill,
///   2. a hairline border at very low alpha,
///   3. a layered shadow from [AppElevation].
///
/// Previously this widget wrapped its content in a [BackdropFilter] and
/// painted a specular sheen and rim light on top, with an inherited scope to
/// stop nested panes blurring twice. All of that is gone: the blur cost a
/// save-layer plus a blur pass per pane, which dominated frame time in
/// scrolling lists, and on a light canvas the opaque version is visually
/// near-identical.
///
/// Pass [onTap] to get the shared spring press animation.
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
    this.bordered = true,
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

  /// Overrides the level's default fill colour.
  final Color? tint;

  /// Overrides the border colour. Ignored when [bordered] is false.
  final Color? rim;

  /// Overrides the level's default shadow stack.
  final List<BoxShadow>? shadow;

  /// Paints a gradient instead of a flat [tint].
  final Gradient? gradient;

  /// Draw the hairline border.
  final bool bordered;

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
    duration: const Duration(milliseconds: 130),
    reverseDuration: const Duration(milliseconds: 250),
  );

  late final Animation<double> _scale = _press.drive(
    Tween<double>(begin: 1.0, end: 0.978)
        .chain(CurveTween(curve: Curves.easeOutCubic)),
  );

  bool get _tappable => widget.onTap != null || widget.onLongPress != null;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Color get _fill {
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
        return AppElevation.card(false);
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
      case GlassLevel.surface:
        return AppRadius.allLg;
      case GlassLevel.modal:
        return AppRadius.allXl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = _radius;

    // Fill + border + shadow in one decoration, so this is a single paint.
    Widget result = Container(
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      alignment: widget.alignment,
      clipBehavior: widget.clipBehavior,
      decoration: BoxDecoration(
        color: widget.gradient == null ? _fill : null,
        gradient: widget.gradient,
        borderRadius: radius,
        border: widget.bordered
            ? Border.all(
                color: widget.rim ?? AppGlass.border(false),
                width: AppGlass.borderWidth,
              )
            : null,
        boxShadow: _shadow,
      ),
      child: widget.padding == null
          ? widget.child
          : Padding(padding: widget.padding!, child: widget.child),
    );

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
