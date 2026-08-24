import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_motion.dart';

/// Cross-fades between a loading **skeleton** and resolved **content** over
/// [AppMotion.base], implementing the design's "Skeleton → content" motion
/// principle.
///
/// Wrap any loading UI so the transition from shimmer placeholder to real data
/// is a subtle fade rather than a hard swap:
///
/// ```dart
/// SkeletonSwitcher(
///   showSkeleton: isLoading,
///   skeleton: const ShimmerCampaignCardCompact(),
///   child: CampaignCard(campaign: campaign),
/// )
/// ```
///
/// For Riverpod `AsyncValue`s, prefer [AsyncSkeleton] which wires the
/// loading/error/data states to this switcher for you.
class SkeletonSwitcher extends StatelessWidget {
  /// The resolved content, shown once [showSkeleton] is false.
  final Widget child;

  /// The skeleton placeholder shown while [showSkeleton] is true.
  final Widget skeleton;

  /// Whether to show the [skeleton] (true) or the [child] (false).
  final bool showSkeleton;

  /// Cross-fade duration. Defaults to [AppMotion.base].
  final Duration duration;

  /// How child/skeleton are laid out during the transition.
  final AlignmentGeometry alignment;

  const SkeletonSwitcher({
    super.key,
    required this.child,
    required this.skeleton,
    required this.showSkeleton,
    this.duration = AppMotion.base,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: alignment,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      transitionBuilder: (widget, animation) =>
          FadeTransition(opacity: animation, child: widget),
      // Distinct keys ensure the switcher animates between the two states.
      child: showSkeleton
          ? KeyedSubtree(key: const ValueKey('skeleton'), child: skeleton)
          : KeyedSubtree(key: const ValueKey('content'), child: child),
    );
  }
}

/// An `AsyncValue`-aware builder that cross-fades from a [skeleton] to resolved
/// content over [AppMotion.base] when a Riverpod provider resolves.
///
/// It renders:
/// * the [skeleton] while loading (and, by default, during silent refreshes
///   that still expose previous data — see [showSkeletonOnRefresh]),
/// * the [error] builder (or the skeleton if none is supplied) on failure,
/// * the [data] builder once the value is available,
///
/// all wrapped in a [SkeletonSwitcher] so state changes fade smoothly.
///
/// ```dart
/// AsyncSkeleton<List<Campaign>>(
///   value: ref.watch(campaignsProvider),
///   skeleton: const ShimmerCampaignCardCompact(),
///   data: (campaigns) => CampaignList(campaigns),
///   error: (e, _) => ErrorState(message: ErrorUtils.sanitize(e)),
/// )
/// ```
class AsyncSkeleton<T> extends StatelessWidget {
  /// The async value to render.
  final AsyncValue<T> value;

  /// Skeleton placeholder shown while loading.
  final Widget skeleton;

  /// Builds the resolved content.
  final Widget Function(T data) data;

  /// Optional error builder. Falls back to the [skeleton] when omitted.
  final Widget Function(Object error, StackTrace? stackTrace)? error;

  /// When true (default), keep showing the [skeleton] while a provider is
  /// refreshing in the background even if stale data is present. When false,
  /// existing data stays visible during the refresh.
  final bool showSkeletonOnRefresh;

  /// Cross-fade duration. Defaults to [AppMotion.base].
  final Duration duration;

  /// Layout alignment during the transition.
  final AlignmentGeometry alignment;

  const AsyncSkeleton({
    super.key,
    required this.value,
    required this.skeleton,
    required this.data,
    this.error,
    this.showSkeletonOnRefresh = true,
    this.duration = AppMotion.base,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.hasValue;
    final isLoading = value.isLoading;
    final hasError = value.hasError;

    // Decide whether to present the skeleton for this frame.
    final showSkeleton = showSkeletonOnRefresh
        ? (isLoading && !hasError) || (!hasValue && !hasError)
        : (isLoading && !hasValue && !hasError);

    late final Widget content;
    if (hasError && !isLoading) {
      content = error?.call(value.error!, value.stackTrace) ?? skeleton;
    } else if (hasValue) {
      content = data(value.requireValue);
    } else {
      // No value yet and not an error: fall back to the skeleton as content so
      // the switcher always has something to render.
      content = skeleton;
    }

    return SkeletonSwitcher(
      showSkeleton: showSkeleton,
      skeleton: skeleton,
      duration: duration,
      alignment: alignment,
      child: content,
    );
  }
}
