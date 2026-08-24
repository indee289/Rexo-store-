import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// User roles a [RoleBadge] can represent.
enum UserRole {
  creator,
  brand,
  admin;

  /// Maps a raw role string (as stored on the user/profile row) to a
  /// [UserRole], defaulting to [UserRole.creator] for unknown/empty values.
  static UserRole fromString(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'brand':
        return UserRole.brand;
      case 'admin':
        return UserRole.admin;
      case 'creator':
      default:
        return UserRole.creator;
    }
  }

  /// Human-readable label.
  String get label {
    switch (this) {
      case UserRole.brand:
        return 'Brand';
      case UserRole.admin:
        return 'Admin';
      case UserRole.creator:
        return 'Creator';
    }
  }

  /// Token-driven accent color for the role (pulled out of the previously
  /// hard-coded literals in `public_profile_screen.dart`).
  Color get color {
    switch (this) {
      case UserRole.brand:
        return AppColors.roleBrand;
      case UserRole.admin:
        return AppColors.roleAdmin;
      case UserRole.creator:
        return AppColors.roleCreator;
    }
  }

  /// Leading Iconsax glyph representing the role.
  IconData get icon {
    switch (this) {
      case UserRole.brand:
        return Iconsax.shop;
      case UserRole.admin:
        return Iconsax.shield_tick;
      case UserRole.creator:
        return Iconsax.user;
    }
  }
}

/// A tonal role badge pill (Component_Library).
///
/// Renders a role's label with a subtle translucent fill and a matching hairline
/// border — an iOS-style tonal treatment rather than a hard solid fill. All
/// colors come from [AppColors] role tokens via [UserRole].
class RoleBadge extends StatelessWidget {
  /// The role to display.
  final UserRole role;

  /// Whether to show the leading Iconsax glyph.
  final bool showIcon;

  const RoleBadge({
    super.key,
    required this.role,
    this.showIcon = true,
  });

  /// Convenience constructor from a raw role string.
  RoleBadge.fromString(
    String? role, {
    Key? key,
    bool showIcon = true,
  }) : this(key: key, role: UserRole.fromString(role), showIcon: showIcon);

  @override
  Widget build(BuildContext context) {
    final color = role.color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(role.icon, size: 13, color: color),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(
            role.label,
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single stat entry for a profile stats row (Component_Library).
///
/// Instagram-style: a bold [value] stacked over a muted [label]. Optionally
/// tappable (e.g. tapping "followers" to open a list) with press-scale feedback,
/// and an optional leading Iconsax glyph.
class StatPill extends StatefulWidget {
  /// The emphasized value (e.g. "1.2k").
  final String value;

  /// The muted caption under the value (e.g. "Followers").
  final String label;

  /// Optional leading Iconsax glyph shown above the value.
  final IconData? icon;

  /// Optional tap handler; enables press-scale feedback when non-null.
  final VoidCallback? onTap;

  const StatPill({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.onTap,
  });

  @override
  State<StatPill> createState() => _StatPillState();
}

class _StatPillState extends State<StatPill> {
  bool _pressed = false;

  bool get _interactive => widget.onTap != null;

  void _setPressed(bool value) {
    if (!_interactive || value == _pressed) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          widget.value,
          style: AppTextStyles.h6.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    if (!_interactive) return content;

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
        child: content,
      ),
    );
  }
}
