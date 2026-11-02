import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_surface.dart';

/// A labelled section: a small tracked-out header followed by its content.
///
/// This is the iOS "inset grouped" pattern and it is the app's primary layout
/// unit. Sections are separated by whitespace rather than by rules, so there
/// are no full-width [Divider] lines anywhere in the app.
class GlassSection extends StatelessWidget {
  const GlassSection({
    super.key,
    required this.children,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.xl,
    ),
    this.separated = true,
  });

  /// Rows (or any widgets) that form the group.
  final List<Widget> children;

  /// Section label shown above the group.
  final String? title;

  /// Optional action aligned to the end of the header row.
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  /// Draw inset separators between rows. Set false for groups whose children
  /// are already self-contained cards.
  final bool separated;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!.toUpperCase(),
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ],
          GlassGroup(separated: separated, children: children),
        ],
      ),
    );
  }
}

/// A single glass pane holding a run of rows.
///
/// Rows are separated by a 1px **inset** line painted by the group itself, not
/// by [Divider] widgets: a full-bleed rule would cut across the pane's rim and
/// break the illusion that the group is one piece of glass.
class GlassGroup extends StatelessWidget {
  const GlassGroup({
    super.key,
    required this.children,
    this.separated = true,
    this.borderRadius,
  });

  final List<Widget> children;
  final bool separated;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (separated && i != children.length - 1) {
        rows.add(const _InsetSeparator());
      }
    }

    return GlassSurface(
      level: GlassLevel.card,
      borderRadius: borderRadius ?? AppRadius.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }
}

/// Hairline between two rows of a group, inset from the leading edge so it
/// starts after the icon column.
class _InsetSeparator extends StatelessWidget {
  const _InsetSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 56, right: AppSpacing.md),
      child: SizedBox(
        height: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: AppColors.divider),
        ),
      ),
    );
  }
}

/// A row inside a [GlassGroup]: icon bubble, title, optional subtitle, and
/// either a trailing widget or a chevron.
class GlassRow extends StatefulWidget {
  const GlassRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
    this.trailing,
    this.trailingText,
    this.onTap,
    this.showChevron,
    this.destructive = false,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  /// Replaces the icon bubble entirely (e.g. with an avatar).
  final Widget? leading;
  final Widget? trailing;

  /// Muted value shown before the chevron — the iOS "detail" text.
  final String? trailingText;
  final VoidCallback? onTap;

  /// Defaults to true when [onTap] is set and no [trailing] was supplied.
  final bool? showChevron;

  /// Renders the title and icon in error red.
  final bool destructive;
  final bool dense;

  @override
  State<GlassRow> createState() => _GlassRowState();
}

class _GlassRowState extends State<GlassRow> {
  bool _pressed = false;

  bool get _tappable => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final accent = widget.destructive
        ? AppColors.error
        : (widget.iconColor ?? AppColors.primary);
    final titleColor =
        widget.destructive ? AppColors.error : AppColors.textPrimary;
    final chevron = widget.showChevron ??
        (_tappable && widget.trailing == null);

    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: widget.dense ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Row(
        children: [
          if (widget.leading != null)
            widget.leading!
          else if (widget.icon != null)
            _RowIcon(icon: widget.icon!, color: accent),
          if (widget.leading != null || widget.icon != null)
            const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: AppTextStyles.callout.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: AppTextStyles.footnote
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailingText != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              widget.trailingText!,
              style: AppTextStyles.subheadline
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 1,
            ),
          ],
          if (widget.trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            widget.trailing!,
          ],
          if (chevron) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              AppIcons.arrow_right_3,
              size: 18,
              color: AppColors.textHint,
            ),
          ],
        ],
      ),
    );

    if (!_tappable) return row;

    // A pressed row tints rather than scales: scaling one row inside a shared
    // glass pane would visibly detach it from the group.
    return Semantics(
      button: true,
      label: widget.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _pressed
              ? AppColors.textPrimary.withOpacity(0.05)
              : Colors.transparent,
          child: row,
        ),
      ),
    );
  }
}

/// Rounded tinted square holding a row's leading icon.
class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: AppRadius.allXs,
        border: Border.all(color: color.withOpacity(0.20), width: 1),
      ),
      child: Center(child: Icon(icon, size: 17, color: color)),
    );
  }
}

/// A [GlassGroup] row whose trailing control is a toggle.
///
/// The whole row is the tap target — a 51x31 switch alone is a poor one — so
/// the switch itself is wrapped in an [IgnorePointer] and cannot double-fire.
class GlassSwitchRow extends StatelessWidget {
  const GlassSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GlassRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      showChevron: false,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: IgnorePointer(
        child: _SwitchControl(value: value, enabled: onChanged != null),
      ),
    );
  }
}

/// The toggle used by [GlassSwitchRow].
///
/// Kept local rather than reusing `GlassSwitch` so `glass_group.dart` does not
/// depend on `glass_switch.dart`, which would make the two files circular once
/// `GlassSwitchTile` starts composing `GlassRow`.
class _SwitchControl extends StatelessWidget {
  const _SwitchControl({required this.value, required this.enabled});

  final bool value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 50,
        height: 30,
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
            width: 26,
            height: 26,
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
    );
  }
}

/// Compact glass pill showing a value over a label — followers, following,
/// counts, balances.
class GlassStatPill extends StatelessWidget {
  const GlassStatPill({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.onTap,
    this.accent,
  });

  final String value;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.textPrimary;

    return GlassSurface(
      level: GlassLevel.subtle,
      borderRadius: AppRadius.allSm,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(height: 4),
          ],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.title3.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption1
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// One destination in a [GlassTileGrid].
class GlassTile {
  const GlassTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  /// Short value shown under the label — a balance, a count.
  final String? badge;
}

/// Grid of square glass tiles, each an icon over a label.
///
/// Replaces rows of outlined circular icon buttons: a tile carries a readable
/// label, gives a much larger tap target, and tiles tessellate predictably at
/// any width.
class GlassTileGrid extends StatelessWidget {
  const GlassTileGrid({
    super.key,
    required this.tiles,
    this.columns = 3,
    this.spacing = AppSpacing.md,
  });

  final List<GlassTile> tiles;
  final int columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGaps = spacing * (columns - 1);
        final tileWidth = (constraints.maxWidth - totalGaps) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: tileWidth,
                child: _Tile(tile: tile),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile});

  final GlassTile tile;

  @override
  Widget build(BuildContext context) {
    final accent = tile.color ?? AppColors.primary;

    return GlassSurface(
      level: GlassLevel.card,
      borderRadius: AppRadius.allSm,
      onTap: tile.onTap,
      semanticLabel: tile.label,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: AppRadius.allXs,
              border: Border.all(
                color: accent.withOpacity(0.22),
                width: AppGlass.borderWidth,
              ),
            ),
            child: Center(child: Icon(tile.icon, size: 20, color: accent)),
          ),
          const SizedBox(height: AppSpacing.sm),
          // FittedBox so a long label shrinks inside its tile rather than
          // wrapping and changing the tile's height.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              tile.label,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (tile.badge != null) ...[
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tile.badge!,
                maxLines: 1,
                softWrap: false,
                style: AppTextStyles.caption2
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
