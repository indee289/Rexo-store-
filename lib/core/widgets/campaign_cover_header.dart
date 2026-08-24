import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Shared cover header for campaign cards.
///
/// Renders the campaign's `cover_image_url` via [CachedNetworkImage] when
/// present, or the brand gradient as a fallback. A consistent dark scrim is
/// laid over real cover images so overlaid badges stay legible. Both
/// [CampaignCard] (Home) and [CampaignListCard] (Campaigns) use this widget so
/// an identical campaign looks identical everywhere — same gradient opacity,
/// same scrim, same height.
class CampaignCoverHeader extends StatelessWidget {
  final String coverImageUrl;
  final double height;

  /// Widgets stacked on top of the header (badges, centered budget, etc.).
  final List<Widget> overlay;

  const CampaignCoverHeader({
    super.key,
    required this.coverImageUrl,
    this.height = 140,
    this.overlay = const [],
  });

  /// Unified brand gradient used for the fallback (and behind transparent PNGs).
  ///
  /// Sourced from the shared [AppColors.primaryGradient] token so the fallback
  /// matches every other brand-gradient surface (send button, follow button,
  /// CTA fills) instead of drifting with a locally-declared gradient.
  static const LinearGradient gradient = AppColors.primaryGradient;

  @override
  Widget build(BuildContext context) {
    final hasCover = coverImageUrl.isNotEmpty;

    final fallback = Container(
      decoration: const BoxDecoration(gradient: gradient),
      child: const Center(
        child: Icon(Iconsax.gallery, color: Colors.white54, size: 32),
      ),
    );

    // Decode the cover at its on-screen size to cut decode memory: the header
    // is full-bleed (screen width) and a known [height]. Cache dimensions are
    // in raw device pixels, so scale by the device pixel ratio.
    final media = MediaQuery.of(context);
    final dpr = media.devicePixelRatio;
    final memCacheHeight = (height * dpr).round();
    final memCacheWidth = (media.size.width * dpr).round();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image or gradient fallback.
          if (hasCover)
            CachedNetworkImage(
              imageUrl: coverImageUrl,
              fit: BoxFit.cover,
              // Decode at display size (performance / memory).
              memCacheHeight: memCacheHeight,
              memCacheWidth: memCacheWidth,
              // Subtle fade-in when the image resolves; quick placeholder fade.
              fadeInDuration: AppMotion.base,
              fadeOutDuration: AppMotion.fast,
              placeholderFadeInDuration: AppMotion.fast,
              placeholder: (context, url) => fallback,
              errorWidget: (context, url, error) => fallback,
            )
          else
            fallback,

          // Consistent dark scrim over real cover images for badge legibility.
          if (hasCover)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x40000000), Color(0x0D000000)],
                ),
              ),
            ),

          ...overlay,
        ],
      ),
    );
  }
}
