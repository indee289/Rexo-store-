import 'package:flutter/material.dart';

import 'glass/glass.dart';

/// **Migration shim.** Use [GlassChip] directly.
///
/// Forwards to [GlassChip]. The old treatment (black filled pill when
/// selected, opaque white with a grey hairline when not) is gone; chips are now
/// frosted pills that fill with brand-red glass when selected.
///
/// Scheduled for deletion once every call-site is migrated.
class PremiumChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;

  /// Appended to the label in parentheses, matching the previous behaviour.
  final int? count;
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
    return GlassChip(
      label: count == null ? label : '$label ($count)',
      selected: selected,
      icon: icon,
      onTap: onTap,
      dense: true,
    );
  }
}
