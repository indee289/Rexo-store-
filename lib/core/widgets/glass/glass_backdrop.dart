import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The app canvas that every screen sits on.
///
/// A single warm off-white wash, top to bottom. Opaque white cards read as
/// lifted against it, which is where the depth in the UI comes from.
///
/// This used to paint five large blurred colour blooms. They existed purely to
/// give the removed `BackdropFilter` something interesting to sample; with
/// opaque surfaces they contributed nothing but five extra full-width gradient
/// fills underneath every screen, so they are gone. A flat canvas is also what
/// makes text and imagery read cleanly — a tinted field behind an opaque card
/// is invisible, and behind a photo it is noise.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({
    super.key,
    required this.child,
    this.showBlobs = true,
  });

  final Widget child;

  /// Retained for call-site compatibility. The canvas no longer has blobs, so
  /// this now selects between the subtle vertical wash and a flat fill.
  final bool showBlobs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: showBlobs
          ? const BoxDecoration(gradient: AppColors.backdropGradient)
          : const BoxDecoration(color: AppColors.background),
      child: child,
    );
  }
}
