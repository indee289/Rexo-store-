import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/cached_image.dart';

/// View model for a discover-style campaign card.
class FeaturedCampaignData {
  final String id;
  final String title;
  final String category; // e.g. "Clipping"
  final String imageUrl;
  final bool private;
  final List<String> platforms; // e.g. ["instagram","tiktok"]
  final int paidOutPercent; // 0..100
  final String budgetText; // e.g. "₹10,000"
  final String rateText; // e.g. "₹2,500 / 1M"

  const FeaturedCampaignData({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.private,
    required this.platforms,
    required this.paidOutPercent,
    required this.budgetText,
    required this.rateText,
  });
}

/// Discover-style campaign card (new reference): a square thumbnail with a
/// category label, the title + platform icons, a "Paid out" vs "Rate" row and
/// a paid-out progress bar, plus a bookmark toggle. Compact + theme-aware.
class FeaturedCampaignCard extends StatelessWidget {
  final FeaturedCampaignData data;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  const FeaturedCampaignCard({
    super.key,
    required this.data,
    required this.saved,
    required this.onTap,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final track = isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
              spreadRadius: -3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _thumbnail(),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _platformRow(cs),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onToggleSave,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                    color: saved ? AppColors.primary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metric(cs, 'Paid out',
                    value: '${data.paidOutPercent}%',
                    suffix: ' / ${data.budgetText}'),
                const Spacer(),
                _metric(cs, 'Rate',
                    value: data.rateText, alignEnd: true),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: AppRadius.pillAll,
              child: LinearProgressIndicator(
                value: (data.paidOutPercent.clamp(0, 100)) / 100.0,
                minHeight: 6,
                backgroundColor: track,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 62,
        height: 62,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedImage(
              imageUrl: data.imageUrl.isEmpty ? null : data.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_) => _thumbPlaceholder(),
              placeholderBuilder: (_) => _thumbPlaceholder(),
            ),
            // Category label at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
                alignment: Alignment.bottomLeft,
                child: Text(
                  data.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF6B81),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE7FF), Color(0xFFF6F2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Iconsax.gallery, size: 20, color: AppColors.primaryLight),
        ),
      );

  Widget _platformRow(ColorScheme cs) {
    final icons = <Widget>[];
    if (data.private) {
      icons.add(const Icon(Iconsax.lock_1, size: 15, color: AppColors.error));
      icons.add(const SizedBox(width: 6));
    }
    for (final p in data.platforms) {
      icons.add(Icon(_platformIcon(p), size: 15, color: cs.onSurfaceVariant));
      icons.add(const SizedBox(width: 6));
    }
    if (icons.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }

  IconData _platformIcon(String p) {
    switch (p.toLowerCase()) {
      case 'instagram':
        return Iconsax.instagram;
      case 'tiktok':
        return Iconsax.music;
      case 'youtube':
        return Iconsax.video_play;
      case 'x':
      case 'twitter':
        return Iconsax.global;
      case 'facebook':
        return Iconsax.global;
      default:
        return Iconsax.global;
    }
  }

  Widget _metric(ColorScheme cs, String label,
      {required String value, String? suffix, bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
