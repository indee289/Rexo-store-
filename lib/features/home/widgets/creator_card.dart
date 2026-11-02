import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';

/// A compact card for displaying a trending creator.
///
/// Now a [GlassCard] with tokenised colours. Previously it read every colour
/// off `theme.colorScheme.onSurface` with ad-hoc opacities, which produced a
/// different grey in each place; the stats row now uses the single
/// `textSecondary` token.
class CreatorCard extends StatelessWidget {
  final Map<String, dynamic> creator;
  final VoidCallback? onTap;

  const CreatorCard({
    super.key,
    required this.creator,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userData = creator['users'] as Map<String, dynamic>?;
    final name = (userData?['name'] ?? 'Creator').toString();
    final avatarUrl =
        (userData?['profileImage'] ?? '').toString(); // live: profileImage
    final isVerified = (userData?['isVerified'] == true);
    final category = (creator['category'] ?? '').toString();
    final followers = creator['followers'] ?? 0;
    final rating = creator['rating'] ?? 0.0;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PremiumAvatar(
            imageUrl: avatarUrl.isEmpty ? null : avatarUrl,
            name: name,
            size: PremiumAvatar.sizeLg,
            isVerified: isVerified,
          ),
          AppSpacing.gapSm,
          Text(
            name,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              category,
              style: AppTextStyles.caption1
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          AppSpacing.gapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                AppIcons.people,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _formatFollowers(followers),
                style: AppTextStyles.caption1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(AppIcons.star_1, size: 13, color: AppColors.warning),
              const SizedBox(width: AppSpacing.xs),
              Text(
                double.tryParse(rating.toString())?.toStringAsFixed(1) ?? '0.0',
                style: AppTextStyles.caption1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFollowers(dynamic followers) {
    final count = int.tryParse(followers.toString()) ?? 0;
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
