import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Shimmer skeleton toolkit (Layer 2 loading infrastructure).
///
/// All colors and radii here are sourced from the [Theme_System] tokens
/// ([AppColors], [AppRadius], [AppSpacing]) so skeletons stay consistent with
/// the premium look in both light and dark themes — no raw `Color(0xFF...)`
/// literals or ad-hoc magic numbers.
///
/// Skeletons are intended to match the final content layout ("skeleton before
/// spinner") so the switch from loading → resolved content is a subtle
/// cross-fade rather than a jarring layout jump. See [SkeletonSwitcher] /
/// [AsyncSkeleton] for the cross-fade helpers.

/// Resolves the token-driven shimmer palette for the current theme brightness.
///
/// * [base] / [highlight] drive the animated shimmer gradient.
/// * [block] is the opaque colour used for the skeleton shapes themselves; it
///   follows the theme surface so blocks read as "empty" content placeholders.
class _ShimmerPalette {
  final Color base;
  final Color highlight;
  final Color block;

  const _ShimmerPalette({
    required this.base,
    required this.highlight,
    required this.block,
  });

  factory _ShimmerPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _ShimmerPalette(
      base: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
      highlight:
          isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
      // Theme-driven surface keeps the placeholder blocks matched to the real
      // card/background colour in both themes.
      block: theme.colorScheme.surface,
    );
  }
}

/// A single opaque skeleton block. Reused internally by every skeleton so the
/// shape colour + radius always come from tokens.
class _Block extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final BoxShape shape;

  const _Block({
    this.width,
    this.height,
    this.borderRadius = AppRadius.allSm,
    this.shape = BoxShape.rectangle,
  });

  const _Block.circle({required double size})
      : width = size,
        height = size,
        borderRadius = AppRadius.allSm,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final block = _ShimmerPalette.of(context).block;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: block,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
      ),
    );
  }
}

/// Wraps [child] in the token-driven shimmer animation for the current theme.
class _ShimmerScope extends StatelessWidget {
  final Widget child;

  const _ShimmerScope({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = _ShimmerPalette.of(context);
    return Shimmer.fromColors(
      baseColor: palette.base,
      highlightColor: palette.highlight,
      child: child,
    );
  }
}

/// Generic shimmer loading placeholder for list screens.
class ShimmerLoading extends StatelessWidget {
  final double? height;

  const ShimmerLoading({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          height: height,
          child: Column(
            children: List.generate(
              4,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: _Block(
                  height: 80,
                  width: double.infinity,
                  borderRadius: AppRadius.allMd,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rectangular shimmer placeholder for cards.
class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.borderRadius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: _Block(
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Circular shimmer placeholder for avatars.
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: _Block.circle(size: size),
    );
  }
}

/// Horizontal line shimmer for text placeholders.
class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: _Block(
        width: width,
        height: height,
        borderRadius: AppRadius.allSm,
      ),
    );
  }
}

/// Shimmer loading placeholder for a campaign card (horizontal carousel).
///
/// Matches the horizontal home [CampaignCard] footprint (280px wide,
/// 140px cover).
class ShimmerCampaignCard extends StatelessWidget {
  const ShimmerCampaignCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: _CampaignSkeletonBody(
        width: 280,
        coverHeight: 140,
        margin: const EdgeInsets.only(right: AppSpacing.lg),
      ),
    );
  }
}

/// Shimmer loading placeholder matching the **compact** [CampaignCard]
/// (full-width list layout, 96px cover, total height ≤ 210px).
///
/// Mirrors the compact card's structure — cover, title line, metadata line and
/// slot-progress bar — so the cross-fade to real content does not shift layout.
class ShimmerCampaignCardCompact extends StatelessWidget {
  const ShimmerCampaignCardCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: _CampaignSkeletonBody(
        width: double.infinity,
        coverHeight: 96,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
      ),
    );
  }
}

/// Shared body for the campaign-card skeletons. Keeps the horizontal and
/// compact variants pixel-consistent with the real cards.
class _CampaignSkeletonBody extends StatelessWidget {
  final double width;
  final double coverHeight;
  final EdgeInsets margin;

  const _CampaignSkeletonBody({
    required this.width,
    required this.coverHeight,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final block = _ShimmerPalette.of(context).block;
    return Container(
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: block,
        borderRadius: AppRadius.allLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cover placeholder with matching top-rounded corners.
          Container(
            height: coverHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: block,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // Title line.
                _Block(height: 16, width: 180),
                SizedBox(height: AppSpacing.sm),
                // Metadata / deadline line.
                _Block(height: 12, width: 120),
                SizedBox(height: AppSpacing.sm),
                // Slot-progress bar.
                _Block(height: 4, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder for a creator card.
class ShimmerCreatorCard extends StatelessWidget {
  const ShimmerCreatorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final block = _ShimmerPalette.of(context).block;
    return _ShimmerScope(
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: block,
          borderRadius: AppRadius.allMd,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _Block.circle(size: 56),
            SizedBox(height: AppSpacing.sm),
            _Block(height: 14, width: 80),
            SizedBox(height: AppSpacing.xs),
            _Block(height: 10, width: 60),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for a conversation / inbox row.
///
/// Matches the messaging inbox conversation tile: a circular avatar, a name
/// line and preview line stacked in the middle, and a short timestamp block on
/// the trailing edge.
class ShimmerConversationRow extends StatelessWidget {
  const ShimmerConversationRow({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            // Avatar.
            _Block.circle(size: 52),
            SizedBox(width: AppSpacing.md),
            // Name + preview lines.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Block(height: 14, width: 140),
                  SizedBox(height: AppSpacing.sm),
                  _Block(height: 12, width: double.infinity),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // Timestamp.
            _Block(height: 10, width: 32),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for a profile screen.
class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: const [
            _Block.circle(size: 100),
            SizedBox(height: AppSpacing.lg),
            _Block(height: 20, width: 150),
            SizedBox(height: AppSpacing.sm),
            _Block(height: 14, width: 100),
            SizedBox(height: AppSpacing.xl),
            _Block(
              height: 60,
              width: double.infinity,
              borderRadius: AppRadius.allMd,
            ),
            SizedBox(height: AppSpacing.lg),
            _Block(
              height: 48,
              width: double.infinity,
              borderRadius: AppRadius.allMd,
            ),
            SizedBox(height: AppSpacing.md),
            _Block(
              height: 48,
              width: double.infinity,
              borderRadius: AppRadius.allMd,
            ),
            SizedBox(height: AppSpacing.md),
            _Block(
              height: 48,
              width: double.infinity,
              borderRadius: AppRadius.allMd,
            ),
          ],
        ),
      ),
    );
  }
}
