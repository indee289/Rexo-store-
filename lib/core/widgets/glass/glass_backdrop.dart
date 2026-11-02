import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The ambient colour field that every glass pane blurs.
///
/// Glass is only visible when there is something behind it to refract, so this
/// paints the app's base layer: a diagonal gradient plus three soft brand-red
/// colour blobs.
///
/// The blobs are drawn as [RadialGradient]s rather than blurred shapes. A
/// radial gradient is already perfectly soft, so this costs one gradient fill
/// per blob instead of a full save-layer + [BackdropFilter] pass — which
/// matters because this widget sits under every screen in the app.
///
/// Wrap a screen body with it, or let `GlassScaffold` do it for you.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({
    super.key,
    required this.child,
    this.showBlobs = true,
  });

  final Widget child;

  /// Set false on screens that paint their own full-bleed imagery.
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
                  child: IgnorePointer(child: _ColourBlobs()),
                ),
                child,
              ],
            )
          : child,
    );
  }
}

/// Three static brand-tinted blobs. Deliberately not animated: an animating
/// backdrop under a blurred pane repaints the blur every frame.
class _ColourBlobs extends StatelessWidget {
  const _ColourBlobs();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        // Warm red bloom, top-left.
        Positioned(
          top: -140,
          left: -120,
          width: 420,
          height: 420,
          child: _Blob(
            color: Color(0x3D8B1A1A), // brand red @ 24%
          ),
        ),
        // Highlight red, mid-right.
        Positioned(
          top: 180,
          right: -160,
          width: 460,
          height: 460,
          child: _Blob(
            color: Color(0x2EA52020), // highlight red @ 18%
          ),
        ),
        // Cool counterweight, bottom-left — stops the field going muddy.
        Positioned(
          bottom: -180,
          left: -100,
          width: 480,
          height: 480,
          child: _Blob(
            color: Color(0x234A52C4), // indigo @ 14%
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
