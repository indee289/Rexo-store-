import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/campaign_cover_header.dart';
import '../../../core/widgets/overlay_badge.dart';
import '../../../core/widgets/premium_card.dart';

/// A premium campaign card widget for featured carousel display.
///
/// Shares its container ([PremiumCard]), cover header
/// ([CampaignCoverHeader]) and badges ([OverlayBadge]) with the campaigns list
/// card so identical data looks identical on Home and the Campaigns screen, in
/// both light and dark themes.
class CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback? onTap;
  final bool isCompact;

  const CampaignCard({
    super.key,
    required this.campaign,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = campaign['title'] ?? 'Untitled Campaign';
    final budget = campaign['budget'] ?? 0;
    final platform = campaign['platform'] ?? '';
    final category = campaign['category'] ?? '';
    final totalSlots = campaign['total_slots'] ?? 0;
    final filledSlots = campaign['filled_slots'] ?? 0;
    final deadline = campaign['deadline'];
    final coverImageUrl = (campaign['cover_image_url'] ?? '').toString();

    return Container(
      width: isCompact ? double.infinity : 280,
      margin: isCompact
          ? const EdgeInsets.only(bottom: 12)
          : const EdgeInsets.only(right: 16),
      child: PremiumCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shared cover header: real image + scrim, gradient fallback.
            CampaignCoverHeader(
              coverImageUrl: coverImageUrl,
              height: isCompact ? 120 : 140,
              overlay: [
                // Platform badge (on-media variant).
                if (platform.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: OverlayBadge.onMedia(
                      icon: _getPlatformIcon(platform),
                      label: platform,
                    ),
                  ),
                // Category badge (on-media variant).
                if (category.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: OverlayBadge.onMedia(label: category),
                  ),
                // Budget centered over the header.
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\u20B9${_formatBudget(budget)}',
                        style: AppTextStyles.h2.copyWith(
                          fontSize: isCompact ? 22 : 28,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Budget',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Content section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Deadline
                  if (deadline != null)
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar_1,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDeadline(deadline),
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Slots progress
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalSlots > 0
                                ? filledSlots / totalSlots
                                : 0,
                            backgroundColor: theme.dividerColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$filledSlots/$totalSlots slots',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.02, end: 0);
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Iconsax.camera;
      case 'youtube':
        return Iconsax.video;
      case 'tiktok':
        return Iconsax.music;
      default:
        return Iconsax.global;
    }
  }

  String _formatBudget(dynamic budget) {
    final value = double.tryParse(budget.toString()) ?? 0;
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatDeadline(dynamic deadline) {
    try {
      final date = DateTime.parse(deadline.toString());
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return deadline.toString();
    }
  }
}
