import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// White base, #F1F5F9 highlight shimmer loading toolkit.

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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
      ),
    );
  }
}

class _ShimmerScope extends StatelessWidget {
  final Widget child;
  const _ShimmerScope({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
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
  const ShimmerCircle({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(child: _Block.circle(size: size));
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

/// Shimmer placeholder for campaign card (horizontal).
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

/// Shimmer placeholder for compact campaign card (full-width list).
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
    return Container(
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: coverHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Block(height: 16, width: 180),
                SizedBox(height: AppSpacing.sm),
                _Block(height: 12, width: 120),
                SizedBox(height: AppSpacing.sm),
                _Block(height: 4, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for a creator card.
class ShimmerCreatorCard extends StatelessWidget {
  const ShimmerCreatorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

/// Shimmer placeholder for a conversation row.
class ShimmerConversationRow extends StatelessWidget {
  const ShimmerConversationRow({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Block.circle(size: 52),
            SizedBox(width: AppSpacing.md),
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
            _Block(height: 10, width: 32),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a profile screen.
class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            _Block.circle(size: 100),
            SizedBox(height: AppSpacing.lg),
            _Block(height: 20, width: 150),
            SizedBox(height: AppSpacing.sm),
            _Block(height: 14, width: 100),
            SizedBox(height: AppSpacing.xl),
            _Block(height: 60, width: double.infinity, borderRadius: AppRadius.allMd),
            SizedBox(height: AppSpacing.lg),
            _Block(height: 48, width: double.infinity, borderRadius: AppRadius.allMd),
            SizedBox(height: AppSpacing.md),
            _Block(height: 48, width: double.infinity, borderRadius: AppRadius.allMd),
          ],
        ),
      ),
    );
  }
}
