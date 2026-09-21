import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// iOS-style section header.
///
/// Two visual patterns depending on context:
///
/// 1. **Standalone title row** — a strong title with an optional "See all >"
///    trailing action (used in Home / Explore feed sections).
/// 2. **iOS grouped list header** — a small uppercase-ish gray label above a
///    grouped list section. Achieved via [uppercase] flag.
///
/// The primary [title] is bold (17pt), subtitle uses iOS footnote gray.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  /// When true renders in iOS grouped-header style: small gray label,
  /// no action row. Used above grouped list sections.
  final bool uppercase;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Iconsax.arrow_right_3,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    this.uppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    // iOS grouped-header style — subdued gray label used above list groups.
    if (uppercase) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: AppSpacing.xs + 2,
        ),
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.footnote.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    // Standalone title row (feed section headers).
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.title3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.sm),
            action!,
          ] else if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.sm),
            _SectionAction(
              label: actionLabel!,
              onTap: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}

/// iOS-style "See All" text action — accent color, tight tracking.
class _SectionAction extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SectionAction({
    required this.label,
    required this.onTap,
  });

  @override
  State<_SectionAction> createState() => _SectionActionState();
}

class _SectionActionState extends State<_SectionAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.4 : 1.0,
        child: Text(
          widget.label,
          style: AppTextStyles.subheadline.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
