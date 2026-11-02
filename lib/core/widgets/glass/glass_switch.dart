import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_card.dart';

/// iOS-style glass toggle.
///
/// The track is a recessed glass well that fills with brand red when on; the
/// thumb is an opaque white disc with its own shadow so it reads as sitting
/// *on top of* the glass rather than inside it.
class GlassSwitch extends StatelessWidget {
  const GlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  static const double _width = 51;
  static const double _height = 31;
  static const double _thumb = 27;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: _width,
            height: _height,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value
                  ? AppColors.primary.withOpacity(0.92)
                  : AppGlass.recessed(false),
              borderRadius: AppRadius.pillAll,
              border: Border.all(
                color: value ? AppColors.primaryRim : AppColors.border,
                width: AppGlass.borderWidth,
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _thumb,
                height: _thumb,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A full settings row: icon bubble, title, optional subtitle, trailing switch.
///
/// Tapping anywhere on the row toggles the switch, which is a much larger
/// target than the 51x31 control alone.
class GlassSwitchTile extends StatelessWidget {
  const GlassSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.margin,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final Color? iconColor;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: margin,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            GlassIconBubble(icon: icon!, color: iconColor),
            AppSpacing.gapMd,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headline
                      .copyWith(color: AppColors.textPrimary),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.footnote
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.gapSm,
          // The row already handles the tap; the control itself is decorative
          // here so it cannot double-fire.
          IgnorePointer(
            child: GlassSwitch(
              value: value,
              onChanged: onChanged,
              semanticLabel: title,
            ),
          ),
        ],
      ),
    );
  }
}
