import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A premium, iOS-style filter / selection chip (Layer-2 primitive).
///
/// Replaces `Chip` and the ad-hoc filter chips scattered across feature
/// screens. It renders a frosted, translucent pill (consistent with the
/// [AppGlass] tokens) so the UI reads as clean and glassy in both light and
/// dark themes:
///
///   * **Unselected** – a subtle frosted-glass fill with a hairline rim.
///   * **Selected** – a primary-tinted translucent fill with a primary rim and
///     primary-colored label/icon.
///
/// Optional affordances:
///   * a leading Iconsax [icon],
///   * a trailing [count] badge (e.g. the number of items in a filter).
///
/// The chip is fully token-driven (no raw color literals, no inline fonts).
class PremiumChip extends StatelessWidget {
  /// The chip label.
  final String label;

  /// Whether the chip is in its selected state.
  final bool selected;

  /// Optional leading icon. Prefer an `Iconsax.*` glyph.
  final IconData? icon;

  /// Optional trailing count badge. When null, no badge is rendered.
  final int? count;

  /// Tap handler. When null the chip renders but does not react to taps.
  final VoidCallback? onTap;

  const PremiumChip({
    super.key,
    required this.label,
    this.selected = false,
    this.icon,
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    // Frosted fill + rim derived from the glass tokens. When selected we tint
    // the frosted surface with the brand primary so it reads as "active"
    // without becoming a flat, opaque Material chip.
    final Color fill = selected
        ? primary.withOpacity(isDark ? 0.24 : 0.14)
        : AppGlass.button(isDark);
    final Color rim =
        selected ? primary.withOpacity(0.60) : AppGlass.border(isDark);
    final Color foreground =
        selected ? primary : theme.colorScheme.onSurface.withOpacity(0.75);

    final chip = ClipRRect(
      borderRadius: AppRadius.pillAll,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: AppGlass.blurSigmaSubtle,
          sigmaY: AppGlass.blurSigmaSubtle,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.pillAll,
            border: Border.all(color: rim, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _CountBadge(count: count!, selected: selected),
              ],
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return chip;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: chip,
    );
  }
}

/// Small trailing count badge used inside [PremiumChip].
class _CountBadge extends StatelessWidget {
  final int count;
  final bool selected;

  const _CountBadge({required this.count, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final Color bg =
        selected ? primary : theme.colorScheme.onSurface.withOpacity(0.10);
    final Color fg = selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillAll,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: AppTextStyles.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
