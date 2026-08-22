import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_card.dart';
import 'slots_indicator.dart';

/// Detailed campaign card for the campaigns list screen
class CampaignListCard extends StatelessWidget {
  final Map<String, dynamic> campaign;

  const CampaignListCard({
    super.key,
    required this.campaign,
  });

  @override
  Widget build(BuildContext context) {
    final title = campaign['title'] ?? 'Untitled Campaign';
    final description = campaign['description'] ?? '';
    final budget = campaign['budget'];
    final perCreatorPayout = campaign['per_creator_payout'];
    final platform = campaign['platform'] ?? '';
    final category = campaign['category'] ?? '';
    final deadline = campaign['deadline'];
    final filledSlots = campaign['filled_slots'] ?? 0;
    final totalSlots = campaign['total_slots'] ?? 0;
    final brandInfo = campaign['users'] as Map<String, dynamic>?;
    final brandName = brandInfo?['name'] ?? 'Unknown Brand';

    return PremiumCard(
      onTap: () {
        context.push('/campaigns/${campaign['id']}');
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and brand
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h6,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      brandName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildPlatformBadge(platform),
            ],
          ),
          const SizedBox(height: 10),

          // Description preview
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                description,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Budget and payout row
          Row(
            children: [
              _buildInfoChip(
                icon: Iconsax.wallet_2,
                label: budget != null
                    ? '\u20B9${NumberFormat.compact().format(budget)}'
                    : 'N/A',
                subtitle: 'Budget',
              ),
              const SizedBox(width: 16),
              _buildInfoChip(
                icon: Iconsax.money_recive,
                label: perCreatorPayout != null
                    ? '\u20B9${NumberFormat.compact().format(perCreatorPayout)}'
                    : 'N/A',
                subtitle: 'Per Creator',
              ),
              const Spacer(),
              if (category.isNotEmpty) _buildCategoryChip(category),
            ],
          ),
          const SizedBox(height: 12),

          // Deadline
          if (deadline != null) ...[
            Row(
              children: [
                Icon(
                  Iconsax.calendar_1,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Deadline: ${_formatDeadline(deadline)}',
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Slots indicator
          SlotsIndicator(
            filledSlots: filledSlots is int ? filledSlots : 0,
            totalSlots: totalSlots is int ? totalSlots : 0,
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformBadge(String platform) {
    if (platform.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        platform,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ],
    );
  }

  String _formatDeadline(String deadline) {
    try {
      final date = DateTime.parse(deadline);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return deadline;
    }
  }
}
