import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Token-driven caching image loader (Layer 2 loading infrastructure).
///
/// A thin, reusable wrapper around [CachedNetworkImage] that fulfils the
/// redesign's image-performance requirement: images are cached (memory + disk)
/// and **decoded at their display size** via `memCacheWidth`/`memCacheHeight`
/// to cut memory usage (Requirement 12.4).
///
/// It is the single place cover/product/thumbnail images should be rendered so
/// the caching + decode-at-size behaviour stays consistent. (`PremiumAvatar`
/// already applies the same technique for circular avatars.)
///
/// ```dart
/// CachedImage(
///   imageUrl: campaign.coverUrl,
///   width: double.infinity,
///   height: 96,
///   borderRadius: AppRadius.allLg,
/// )
/// ```
class CachedImage extends StatelessWidget {
  /// Remote image URL. When null/empty the [errorBuilder] (or the default
  /// fallback) is rendered instead.
  final String? imageUrl;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// Optional rounding applied via [ClipRRect].
  final BorderRadius? borderRadius;

  /// Optional custom placeholder shown while the image loads.
  final WidgetBuilder? placeholderBuilder;

  /// Optional custom fallback shown when the URL is empty or the load fails.
  final WidgetBuilder? errorBuilder;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    Widget result;
    if (url == null || url.isEmpty) {
      result = _fallback(context);
    } else {
      final cacheDims = _cacheDimensions(context);
      result = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        // Decode at display size to reduce memory usage (Requirement 12.4).
        memCacheWidth: cacheDims.$1,
        memCacheHeight: cacheDims.$2,
        placeholder: (context, _) => _placeholder(context),
        errorWidget: (context, _, __) => _fallback(context),
      );
    }

    final radius = borderRadius;
    if (radius != null) {
      result = ClipRRect(borderRadius: radius, child: result);
    }
    return result;
  }

  /// Computes the memory cache dimensions in physical pixels, honouring the
  /// device pixel ratio, so the decoded bitmap matches the on-screen size.
  /// Returns `(null, null)` for any unbounded dimension so the full image is
  /// decoded rather than being clamped incorrectly.
  (int?, int?) _cacheDimensions(BuildContext context) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;

    int? toCache(double? logical) {
      if (logical == null || !logical.isFinite || logical <= 0) return null;
      return (logical * dpr).round();
    }

    return (toCache(width), toCache(height));
  }

  Widget _placeholder(BuildContext context) {
    if (placeholderBuilder != null) return placeholderBuilder!(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: width,
      height: height,
      color: onSurface.withOpacity(0.06),
    );
  }

  Widget _fallback(BuildContext context) {
    if (errorBuilder != null) return errorBuilder!(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: onSurface.withOpacity(0.06),
      child: Icon(
        Iconsax.gallery,
        color: onSurface.withOpacity(0.3),
        size: 28,
      ),
    );
  }
}
