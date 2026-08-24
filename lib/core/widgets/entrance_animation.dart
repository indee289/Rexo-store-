import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_motion.dart';

/// Default number of leading list items that receive a staggered delay.
///
/// Items beyond this index still animate, but they all share the delay of the
/// capped index so a long list never accumulates a multi-second entrance and
/// off-screen items don't "drip" in slowly as the user scrolls.
const int kStaggerCap = 12;

/// Standard premium list-entrance animation.
///
/// Implements the design's standard "List entrance" motion pattern:
/// `fadeIn + slideY(begin: 0.08)` over [AppMotion.base] using
/// [AppMotion.standard], staggered by [AppMotion.stagger] per item index and
/// capped for large lists (see [kStaggerCap]).
///
/// Built on `flutter_animate` (already a dependency). Use it either through the
/// [StaggeredEntranceX.staggeredEntrance] extension on any [Widget] or via the
/// [StaggeredEntrance] wrapper.
///
/// Example (extension — preferred inside `ListView.builder`):
/// ```dart
/// ListView.builder(
///   itemBuilder: (context, index) =>
///       CampaignCard(campaign: items[index]).staggeredEntrance(index),
/// );
/// ```
///
/// Example (wrapper):
/// ```dart
/// StaggeredEntrance(
///   index: index,
///   child: CampaignCard(campaign: items[index]),
/// );
/// ```
extension StaggeredEntranceX on Widget {
  /// Wraps this widget in the standard staggered fade-and-slide entrance.
  ///
  /// - [index]: position of the item in its list; drives the stagger delay.
  /// - [cap]: highest index that receives an increasing delay (default
  ///   [kStaggerCap]). Indices past the cap reuse the capped delay.
  /// - [stagger]: per-index delay step (default [AppMotion.stagger]).
  /// - [duration]: entrance duration (default [AppMotion.base]).
  /// - [curve]: entrance curve (default [AppMotion.standard]).
  /// - [slideBegin]: initial vertical offset as a fraction of the widget
  ///   height (default `0.08`, matching the design pattern).
  Widget staggeredEntrance(
    int index, {
    int cap = kStaggerCap,
    Duration? stagger,
    Duration? duration,
    Curve? curve,
    double slideBegin = 0.08,
  }) {
    final Duration step = stagger ?? AppMotion.stagger;
    final Duration dur = duration ?? AppMotion.base;
    final Curve ease = curve ?? AppMotion.standard;

    // Clamp the index so the delay is bounded for long/scrolling lists.
    final int safeIndex = index < 0 ? 0 : index;
    final int cappedIndex = safeIndex > cap ? cap : safeIndex;
    final Duration delay = step * cappedIndex;

    return animate(delay: delay)
        .fadeIn(duration: dur, curve: ease)
        .slideY(begin: slideBegin, end: 0, duration: dur, curve: ease);
  }
}

/// Widget wrapper equivalent of [StaggeredEntranceX.staggeredEntrance].
///
/// Handy when composing entrance motion declaratively (e.g. for a fixed set of
/// sections) rather than inline in a builder.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.cap = kStaggerCap,
    this.stagger,
    this.duration,
    this.curve,
    this.slideBegin = 0.08,
  });

  /// Position of this item in its list; drives the stagger delay.
  final int index;

  /// The content to animate in.
  final Widget child;

  /// Highest index that receives an increasing delay.
  final int cap;

  /// Per-index delay step (defaults to [AppMotion.stagger]).
  final Duration? stagger;

  /// Entrance duration (defaults to [AppMotion.base]).
  final Duration? duration;

  /// Entrance curve (defaults to [AppMotion.standard]).
  final Curve? curve;

  /// Initial vertical offset as a fraction of the widget height.
  final double slideBegin;

  @override
  Widget build(BuildContext context) {
    return child.staggeredEntrance(
      index,
      cap: cap,
      stagger: stagger,
      duration: duration,
      curve: curve,
      slideBegin: slideBegin,
    );
  }
}
