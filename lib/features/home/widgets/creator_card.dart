import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_card.dart';

/// A compact card for displaying a trending creator.
///
/// Token-driven and built from the shared [PremiumCard] + [PremiumAvatar]
/// primitives so it matches the premium look in both light and dark themes
/// (no inline `GoogleFonts` or raw color literals). Fills the width of its
/// parent so the Home grid controls sizing.
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
    final theme = Theme.of(context);
    final userData = creator['users'] as Map<String, dynamic>?;
    final name = (userData?['name'] ?? 'Creator').toString();
    final avatarUrl = (userData?['avatar_url'] ?? '').toString();
    final isVerified = (userData?['is_verified'] == true);
    final category = (creator['category'] ?? '').toString();
    final followers = creator['followers'] ?? 0;
    final rating = creator['rating'] ?? 0.0;

    return PremiumCard(
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            name,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              category,
              style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.people,
                size: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _formatFollowers(followers),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Iconsax.star_1,
                size: 12,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                double.tryParse(rating.toString())?.toStringAsFixed(1) ?? '0.0',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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
