import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../services/r2_storage_service.dart';

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
    // Normalize stored URLs (private R2 S3 endpoint -> public URL) so both new
    // and previously-persisted images render.
    final url = R2StorageService.publicUrlFor(imageUrl);

    Widget result;
    if (url.isEmpty) {
      result = _fallback(context);
    } else {
      final cacheDims = _cacheDimensions(context);
      result = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        // Decode at display size to reduce memory usage. Only ONE dimension is
        // ever passed: giving the decoder both width AND height stretches the
        // image to that exact box and ignores its aspect ratio (squashed
        // logos / covers).
        memCacheWidth: cacheDims.$1,
        memCacheHeight: cacheDims.$2,
        // The package defaults (500ms fade-in, 1000ms fade-out) made every
        // image feel slow, with the placeholder lingering on screen.
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: Duration.zero,
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
    final mq = MediaQuery.maybeOf(context);
    final dpr = mq?.devicePixelRatio ?? 1.0;
    final screenW = mq?.size.width ?? 0.0;

    bool bounded(double? v) => v != null && v.isFinite && v > 0;
    int? screenWidthPx() => screenW > 0
        ? (screenW * dpr).clamp(200, 1200).round()
        : null;

    // Box has a fixed width AND height (thumbnails, avatars, grid tiles).
    // The image's own aspect ratio is unknown, so decode its WIDTH large
    // enough that a landscape image still covers the box height (BoxFit.cover
    // would otherwise upscale it and look blurry).
    if (bounded(width) && bounded(height)) {
      final side = (width! > height! ? width! : height!) * dpr;
      return ((side * 1.8).clamp(64, 1200).round(), null);
    }
    // Fixed width only.
    if (bounded(width)) return ((width! * dpr).clamp(64, 1600).round(), null);
    // Width fills the parent (banners / full-width covers): decode at roughly
    // the screen width, never the full original resolution.
    return (screenWidthPx(), null);
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
