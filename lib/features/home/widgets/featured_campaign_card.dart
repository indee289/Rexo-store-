import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/glass/glass.dart';

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

/// Campaign card — liquid glass.
///
/// Was an opaque white `Container` with a 0.8px grey border, a flat drop
/// shadow and hardcoded `TextStyle`s. Now a [GlassCard] with the shared spring
/// press, tokenised type, a glass progress track filled with the brand
/// gradient, and the bookmark as a real 44pt tap target instead of a bare
/// 20px icon.
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
    return GlassCard(
      onTap: onTap,
      borderRadius: AppRadius.allLg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(imageUrl: data.imageUrl, category: data.category),
              AppSpacing.gapMd,
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
                        style: AppTextStyles.headline.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _PlatformRow(
                        platforms: data.platforms,
                        private: data.private,
                      ),
                    ],
                  ),
                ),
              ),
              GlassIconButton.bare(
                icon: Iconsax.bookmark,
                onTap: onToggleSave,
                size: 36,
                iconSize: 20,
                color: saved ? AppColors.primary : AppColors.textSecondary,
                tooltip: saved ? 'Remove from saved' : 'Save campaign',
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: _Metric(
                  label: 'Paid out',
                  value: '${data.paidOutPercent}%',
                  suffix: ' / ${data.budgetText}',
                ),
              ),
              AppSpacing.gapMd,
              Flexible(
                child: _Metric(
                  label: 'Rate',
                  value: data.rateText,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          _ProgressTrack(percent: data.paidOutPercent),
        ],
      ),
    );
  }
}

/// Square thumbnail with the category on a bottom scrim.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageUrl, required this.category});

  final String imageUrl;
  final String category;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.allSm,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedImage(
              imageUrl: imageUrl.isEmpty ? null : imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_) => const _ThumbPlaceholder(),
              placeholderBuilder: (_) => const _ThumbPlaceholder(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.74),
                      Colors.transparent,
                    ],
                  ),
                ),
                alignment: Alignment.bottomLeft,
                // White on a dark scrim stays readable over any artwork.
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
      ),
      child: const Center(
        child: Icon(Iconsax.gallery, size: 20, color: AppColors.primaryLight),
      ),
    );
  }
}

/// Lock badge plus one icon per platform.
class _PlatformRow extends StatelessWidget {
  const _PlatformRow({required this.platforms, required this.private});

  final List<String> platforms;
  final bool private;

  static IconData _platformIcon(String p) {
    switch (p.toLowerCase()) {
      case 'instagram':
        return Iconsax.instagram;
      case 'tiktok':
        return Iconsax.music;
      case 'youtube':
        return Iconsax.video_play;
      case 'x':
      case 'twitter':
      case 'facebook':
        return Iconsax.global;
      default:
        return Iconsax.global;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icons = <Widget>[];
    if (private) {
      icons.add(const Icon(Iconsax.lock_1, size: 15, color: AppColors.error));
      icons.add(const SizedBox(width: 6));
    }
    for (final p in platforms) {
      icons.add(
        Icon(_platformIcon(p), size: 15, color: AppColors.textSecondary),
      );
      icons.add(const SizedBox(width: 6));
    }
    if (icons.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }
}

/// Recessed glass track filled with the brand gradient.
class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final value = percent.clamp(0, 100) / 100.0;

    return ClipRRect(
      borderRadius: AppRadius.pillAll,
      child: Container(
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withOpacity(0.08),
          borderRadius: AppRadius.pillAll,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value == 0 ? 0.0 : value,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.pillAll,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label above a value, with an optional muted suffix.
class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.suffix,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final String? suffix;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption1.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
