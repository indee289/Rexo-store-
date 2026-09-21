import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A consistent "section title + optional action" row (Component_Library).
///
/// Replaces the many ad-hoc inline title rows (e.g. "Top Creators — See all")
/// with one token-driven primitive. The title uses [AppTextStyles.h6], an
/// optional [subtitle] uses [AppTextStyles.caption], and the trailing action is
/// a compact text button with an Iconsax chevron.
///
/// Provide either [actionLabel] + [onAction] for the standard text action, or a
/// fully custom [action] widget (which takes precedence).
class SectionHeader extends StatelessWidget {
  /// Section title.
  final String title;

  /// Optional supporting line under the title.
  final String? subtitle;

  /// Label for the trailing text action (e.g. "See all").
  final String? actionLabel;

  /// Tap handler for the trailing text action.
  final VoidCallback? onAction;

  /// Trailing Iconsax glyph shown after [actionLabel]. Defaults to a chevron.
  final IconData actionIcon;

  /// Fully custom trailing widget. Overrides [actionLabel]/[onAction].
  final Widget? action;

  /// Outer padding around the header row.
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Iconsax.arrow_right_3,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  style: AppTextStyles.h6.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
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
              icon: actionIcon,
              onTap: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact tappable text action ("See all >") with press-scale feedback.
class _SectionAction extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SectionAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SectionAction> createState() => _SectionActionState();
}

class _SectionActionState extends State<_SectionAction> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (value == _pressed) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              widget.icon,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
