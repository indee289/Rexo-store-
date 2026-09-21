import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Instagram-style section header.
///
/// Two visual patterns:
/// 1. **Standalone title row** — bold black title with an optional blue
///    "See all" trailing text-link (Instagram feed section style).
/// 2. **Uppercase gray label** — small gray label above list groups
///    (like IG settings sections).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final Widget? action;
  final EdgeInsetsGeometry padding;
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
            letterSpacing: 0.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

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
                  style: AppTextStyles.title2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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
            _SeeAllLink(
              label: actionLabel!,
              onTap: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}

class _SeeAllLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SeeAllLink({required this.label, required this.onTap});

  @override
  State<_SeeAllLink> createState() => _SeeAllLinkState();
}

class _SeeAllLinkState extends State<_SeeAllLink> {
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
        opacity: _pressed ? 0.5 : 1.0,
        child: Text(
          widget.label,
          style: AppTextStyles.subheadline.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
