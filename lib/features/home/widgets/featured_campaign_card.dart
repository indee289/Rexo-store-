import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/cached_image.dart';

/// Plain view model for a featured campaign card. Fed either from real
/// `campaigns` rows (mapped in HomeScreen) or from sample data for testing.
class FeaturedCampaignData {
  final String id;
  final String title;
  final String brand;
  final bool verified;
  final String description;
  final String imageUrl;
  final String reward; // formatted, e.g. "₹8,000"
  final String platform; // e.g. "Instagram Post"
  final int applied;
  final int total;
  final int daysLeft;

  const FeaturedCampaignData({
    required this.id,
    required this.title,
    required this.brand,
    required this.verified,
    required this.description,
    required this.imageUrl,
    required this.reward,
    required this.platform,
    required this.applied,
    required this.total,
    required this.daysLeft,
  });
}

/// Premium featured-campaign card matching the Home reference: a rounded white
/// card with a left cover image and, on the right, a "Featured" badge + save
/// icon, name, verified brand, description, applications, a green reward pill,
/// a violet platform chip and a red "days left" label. Theme-aware.
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

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover image (left)
              SizedBox(
                width: 104,
                child: CachedImage(
                  imageUrl: data.imageUrl.isEmpty ? null : data.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              // Content (right)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _pill(
                            'Featured',
                            AppColors.primary,
                            isDark ? 0.20 : 0.12,
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: onToggleSave,
                            behavior: HitTestBehavior.opaque,
                            child: Icon(
                              saved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 20,
                              color: saved
                                  ? AppColors.primary
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              data.brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (data.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(Iconsax.verify,
                                size: 14, color: AppColors.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Description + applications
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              data.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Applications',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${data.applied}/${data.total}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Reward + platform + days left
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _pill(
                                  data.reward,
                                  AppColors.success,
                                  isDark ? 0.20 : 0.12,
                                  bold: true,
                                ),
                                _pill(
                                  data.platform,
                                  AppColors.primary,
                                  isDark ? 0.18 : 0.10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${data.daysLeft} days left',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color, double opacity, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
