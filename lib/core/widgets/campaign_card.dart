import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'campaign_cover_header.dart';
import 'overlay_badge.dart';
import 'premium_card.dart';

/// Layout variants for the shared [CampaignCard].
///
/// - [horizontal]: fixed-width (240px) card for the Home carousel; taller
///   104px cover.
/// - [compact]: full-width list card for the Campaigns tab and Home vertical
///   list; short 84px cover and a compact total footprint of ~150-165px.
enum CampaignCardLayout { horizontal, compact }

/// The single shared, compact campaign card used by both the Home screen and
/// the Campaigns tab (Requirement 1.5).
///
/// This replaces the two divergent, oversized cards (the home `CampaignCard`
/// and the campaigns `CampaignListCard`). It renders the campaign title,
/// brand, a compact budget value pill, and a thin slot-progress bar over a
/// [CampaignCoverHeader] cover — in a deliberately small footprint.
///
/// Sizing (see design "Compact campaign card sizing spec"):
/// - [CampaignCardLayout.horizontal]: width 240, cover height 104.
/// - [CampaignCardLayout.compact]: full width, cover height 84, total ~150-165px.
///
/// The giant centered budget number from the old cards is removed; budget is
/// shown inline as a compact value pill so price emphasis is preserved without
/// a huge hero number.
class CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback? onTap;
  final CampaignCardLayout layout;

  /// Optional application-status label ("pending" / "approved" / "rejected").
  /// When non-null a small status chip is overlaid on the top-left of the
  /// cover — used by the applied Campaigns tab.
  final String? applicationStatus;

  const CampaignCard({
    super.key,
    required this.campaign,
    this.onTap,
    this.layout = CampaignCardLayout.compact,
    this.applicationStatus,
  });

  bool get _isHorizontal => layout == CampaignCardLayout.horizontal;

  double get _coverHeight => _isHorizontal ? 104 : 84;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = (campaign['title'] ?? 'Untitled Campaign').toString();
    final budget = campaign['budget'];
    final platform = (campaign['platform'] ?? '').toString();
    final coverImageUrl = (campaign['cover_image_url'] ?? '').toString();
    final brandName = _resolveBrandName();

    final filled = _asInt(campaign['filled_slots']);
    final total = _asInt(campaign['total_slots']);

    final card = PremiumCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cover header (cover render site #1 home / #2 list). Height is
          // passed so the caching image loader decodes at display size.
          CampaignCoverHeader(
            coverImageUrl: coverImageUrl,
            height: _coverHeight,
            overlay: [
              if (platform.isNotEmpty)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: OverlayBadge.onMedia(
                    icon: _platformIcon(platform),
                    label: platform,
                  ),
                ),
              if (applicationStatus != null)
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: _StatusChip(status: applicationStatus!),
                ),
            ],
          ),
          // Compact content row.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title (single line to keep the card short).
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (brandName.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  // Brand name shown subtly.
                  Text(
                    brandName,
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                // Budget value pill + compact slot progress.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ValuePill(
                      icon: Iconsax.wallet_2,
                      value: _formatBudget(budget),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Spacer(),
                    _SlotsMini(filled: filled, total: total),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (_isHorizontal) {
      return SizedBox(width: 240, child: card);
    }
    return card;
  }

  String _resolveBrandName() {
    final brandInfo = campaign['users'];
    if (brandInfo is Map && brandInfo['name'] != null) {
      return brandInfo['name'].toString();
    }
    final brandName = campaign['brand_name'];
    if (brandName != null && brandName.toString().isNotEmpty) {
      return brandName.toString();
    }
    return '';
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  IconData _platformIcon(String platform) {
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
    final value = double.tryParse(budget?.toString() ?? '') ?? 0;
    String amount;
    if (value >= 100000) {
      amount = '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      amount = '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      amount = value.toStringAsFixed(0);
    }
    return '\u20B9$amount';
  }
}

/// Compact budget/value pill: an Iconsax wallet glyph + the formatted value in
/// the brand primary colour so price emphasis matches the rest of the app.
class _ValuePill extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ValuePill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: AppRadius.allSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin (4px) slot progress bar + "filled/total" caption, kept to a fixed
/// width so it sits neatly at the end of the content row.
class _SlotsMini extends StatelessWidget {
  final int filled;
  final int total;

  const _SlotsMini({required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress =
        total > 0 ? (filled / total).clamp(0.0, 1.0).toDouble() : 0.0;

    return SizedBox(
      width: 76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.dividerColor,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '$filled/$total slots',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small overlay chip showing the application status on the applied tab.
/// Maps the status label to a semantic token colour.
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  String get _label {
    if (status.isEmpty) return status;
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: AppRadius.allSm,
      ),
      child: Text(
        _label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
