import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The ambient colour field that every glass pane blurs.
///
/// Glass is only visible when there is something behind it to refract, so this
/// is the app's base layer: a soft diagonal gradient plus five overlapping
/// colour blooms in brand red, rose, peach and lavender. Nothing in the app
/// renders on a flat grey background.
///
/// ### Why gradients instead of blurred shapes
/// Each bloom is a [RadialGradient], not a circle pushed through a
/// [BackdropFilter]. A radial gradient is already perfectly soft, so this costs
/// one gradient fill per bloom rather than a full save-layer plus blur pass —
/// which matters because this widget sits underneath every screen in the app
/// and is itself sampled by every glass pane above it.
///
/// ### Why it does not animate
/// An animating backdrop would invalidate every glass pane's blur every frame.
/// The blooms are static; motion comes from content scrolling behind the glass.
///
/// Use [GlassScaffold], which wraps this automatically, rather than placing it
/// by hand.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({
    super.key,
    required this.child,
    this.showBlobs = true,
  });

  final Widget child;

  /// Set false only on screens that paint their own full-bleed media.
  final bool showBlobs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backdropGradient),
      child: showBlobs
          ? Stack(
              fit: StackFit.passthrough,
              children: [
                const Positioned.fill(
                  child: IgnorePointer(child: _ColourField()),
                ),
                child,
              ],
            )
          : child,
    );
  }
}

/// The five blooms. Positions are expressed as fractions of the viewport so the
/// field composes the same way on a small phone and a tablet.
class _ColourField extends StatelessWidget {
  const _ColourField();

  // Alphas are deliberately low (8-24%). The blooms must give the glass
  // something to refract without dropping body-text contrast on the panes
  // above them.
  static const Color _brand = Color(0x3D8B1A1A); // brand red @ 24%
  static const Color _rose = Color(0x33D98FA0); // rose @ 20%
  static const Color _peach = Color(0x2EF2B98C); // peach @ 18%
  static const Color _lavender = Color(0x2EB9A8E0); // lavender @ 18%
  static const Color _roseDeep = Color(0x1FC2707F); // rose @ 12%

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Blooms are sized against the shorter edge so they stay circular and
        // proportionate in both orientations.
        final unit = w < h ? w : h;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Brand red, top-left — anchors the palette.
            _Bloom(
              color: _brand,
              diameter: unit * 1.15,
              left: -unit * 0.38,
              top: -unit * 0.34,
            ),
            // Peach, top-right — warms the status-bar area.
            _Bloom(
              color: _peach,
              diameter: unit * 1.0,
              left: w - unit * 0.62,
              top: -unit * 0.28,
            ),
            // Rose, upper-middle-right — sits behind most app bars.
            _Bloom(
              color: _rose,
              diameter: unit * 1.1,
              left: w - unit * 0.72,
              top: h * 0.24,
            ),
            // Lavender, lower-left — cools the bottom half so the field does
            // not read as uniformly warm.
            _Bloom(
              color: _lavender,
              diameter: unit * 1.2,
              left: -unit * 0.42,
              top: h * 0.52,
            ),
            // Deep rose, bottom-centre — gives the floating nav dock something
            // with contrast to blur.
            _Bloom(
              color: _roseDeep,
              diameter: unit * 1.05,
              left: w * 0.5 - unit * 0.52,
              top: h - unit * 0.52,
            ),
          ],
        );
      },
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({
    required this.color,
    required this.diameter,
    required this.left,
    required this.top,
  });

  final Color color;
  final double diameter;
  final double left;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: diameter,
      height: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            // Hard-stop at 0 alpha by 100% so blooms blend with no visible rim.
            colors: [color, color.withOpacity(0.0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
