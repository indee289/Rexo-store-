import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_colors.dart';

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
  static const LinearGradient gradient = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final hasCover = coverImageUrl.isNotEmpty;

    final fallback = Container(
      decoration: const BoxDecoration(gradient: gradient),
      child: const Center(
        child: Icon(Iconsax.gallery, color: Colors.white54, size: 32),
      ),
    );

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
