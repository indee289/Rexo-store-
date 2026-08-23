import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Visual placement of an [OverlayBadge].
enum OverlayBadgeVariant {
  /// Sits ON an image / gradient header. Semi-transparent dark pill with white
  /// text + icon so it stays legible over any cover art.
  onMedia,

  /// Sits on the card body (theme surface). Neutral tint derived from
  /// `onSurface` so it works in both light and dark themes.
  onSurface,
}

/// A small pill badge shared by the campaign & product cards so the category
/// and platform badges look identical everywhere (Home, Campaigns, Shop).
///
/// Use [OverlayBadge.onMedia] when the badge is overlaid on the cover
/// image/gradient header, and [OverlayBadge.onSurface] when it sits on the
/// card's content area.
class OverlayBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final OverlayBadgeVariant variant;

  const OverlayBadge._({
    super.key,
    required this.label,
    required this.variant,
    this.icon,
  });

  /// Badge overlaid on an image / gradient header (white text on dark scrim).
  const OverlayBadge.onMedia({
    Key? key,
    required String label,
    IconData? icon,
  }) : this._(
          key: key,
          label: label,
          icon: icon,
          variant: OverlayBadgeVariant.onMedia,
        );

  /// Badge sitting on the card body (neutral theme-aware tint).
  const OverlayBadge.onSurface({
    Key? key,
    required String label,
    IconData? icon,
  }) : this._(
          key: key,
          label: label,
          icon: icon,
          variant: OverlayBadgeVariant.onSurface,
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool onMedia = variant == OverlayBadgeVariant.onMedia;

    final Color background = onMedia
        ? Colors.black.withOpacity(0.45)
        : theme.colorScheme.onSurface.withOpacity(0.08);
    final Color foreground =
        onMedia ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.75);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
