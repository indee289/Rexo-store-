import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_surface.dart';

/// The standard content pane: a frosted glass card.
///
/// Replaces every previous card treatment (opaque white `PremiumCard`,
/// Material `Card`, ad-hoc `Container` + `BoxDecoration`). Tapping one runs the
/// shared spring press animation from [GlassSurface].
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.tint,
    this.rim,
    this.shadow,
    this.gradient,
    this.level = GlassLevel.card,
    this.width,
    this.height,
    this.semanticLabel,
  });

  /// A card with no inner padding — for cards whose child is a full-bleed image
  /// or its own padded layout.
  const GlassCard.bare({
    super.key,
    required this.child,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.tint,
    this.rim,
    this.shadow,
    this.gradient,
    this.level = GlassLevel.card,
    this.width,
    this.height,
    this.semanticLabel,
  }) : padding = EdgeInsets.zero;

  /// A brand-tinted card — for highlighted / selected / promoted content.
  const GlassCard.brand({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.shadow,
    this.level = GlassLevel.card,
    this.width,
    this.height,
    this.semanticLabel,
  })  : tint = AppColors.primaryGlass,
        rim = AppColors.primaryRim,
        gradient = null;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color? tint;
  final Color? rim;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;
  final GlassLevel level;
  final double? width;
  final double? height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: level,
      borderRadius: borderRadius ?? AppRadius.allLg,
      padding: padding,
      margin: margin,
      onTap: onTap,
      onLongPress: onLongPress,
      tint: tint,
      rim: rim,
      shadow: shadow,
      gradient: gradient,
      width: width,
      height: height,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}

/// A glass card with a leading icon bubble, title, optional subtitle and an
/// optional trailing widget — the shape most list rows in the app need.
class GlassListCard extends StatelessWidget {
  const GlassListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
    this.trailing,
    this.onTap,
    this.margin,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  /// Overrides the [icon] bubble entirely (e.g. with an avatar).
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.primary;

    return GlassCard(
      margin: margin,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (icon != null)
            GlassIconBubble(icon: icon!, color: accent),
          if (leading != null || icon != null) AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headline
                      .copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.footnote
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[AppSpacing.gapSm, trailing!],
        ],
      ),
    );
  }
}

/// The small tinted glass square that holds a leading icon.
class GlassIconBubble extends StatelessWidget {
  const GlassIconBubble({
    super.key,
    required this.icon,
    this.color,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: AppRadius.allSm,
        border: Border.all(
          color: accent.withOpacity(0.22),
          width: AppGlass.borderWidth,
        ),
      ),
      child: Center(child: Icon(icon, size: iconSize, color: accent)),
    );
  }
}
