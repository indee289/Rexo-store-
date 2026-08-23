import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Generic shimmer loading placeholder for list screens
class ShimmerLoading extends StatelessWidget {
  final double? height;

  const ShimmerLoading({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB);
    final highlightColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F4F6);
    final childColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: height,
          child: Column(
            children: List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: childColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rectangular shimmer placeholder for cards
class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB);
    final highlightColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F4F6);
    final childColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: childColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Circular shimmer placeholder for avatars
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB);
    final highlightColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F4F6);
    final childColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: childColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Horizontal line shimmer for text placeholders
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB);
    final highlightColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F4F6);
    final childColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: childColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for a campaign card
class ShimmerCampaignCard extends StatelessWidget {
  const ShimmerCampaignCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB);
    final highlightColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F4F6);
    final childColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: childColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: childColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 180,
                    color: childColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    color: childColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for a creator card
class ShimmerCreatorCard extends StatelessWidget {
  const ShimmerCreatorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB);
    final highlightColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F4F6);
    final childColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: childColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: childColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 80,
              color: childColor,
            ),
            const SizedBox(height: 4),
            Container(
              height: 10,
              width: 60,
              color: childColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for profile screen
class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB);
    final highlightColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F4F6);
    final childColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: childColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 20, width: 150, color: childColor),
            const SizedBox(height: 8),
            Container(height: 14, width: 100, color: childColor),
            const SizedBox(height: 24),
            Container(
                height: 60, width: double.infinity, color: childColor),
            const SizedBox(height: 16),
            Container(
                height: 48, width: double.infinity, color: childColor),
            const SizedBox(height: 12),
            Container(
                height: 48, width: double.infinity, color: childColor),
            const SizedBox(height: 12),
            Container(
                height: 48, width: double.infinity, color: childColor),
          ],
        ),
      ),
    );
  }
}
