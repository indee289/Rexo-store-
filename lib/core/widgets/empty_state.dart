import 'package:flutter/material.dart';

import 'glass/glass.dart';

/// **Migration shim.** Use [GlassEmptyState] directly.
///
/// Forwards to [GlassEmptyState]. The old treatment (a 96px circle outlined in
/// 2px black, a 22pt black title and a blue Instagram-style text link) is gone;
/// empty states are now a frosted pane with a tinted icon bubble and a glass
/// pill action.
///
/// Scheduled for deletion once every call-site is migrated.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  /// Ignored. [GlassEmptyState] renders the action as a glass pill, which
  /// carries its own iconography.
  final IconData? ctaIcon;

  /// A fully custom action widget, forwarded as-is.
  final Widget? cta;

  /// Ignored. [GlassEmptyState] owns its spacing so every empty state in the
  /// app lines up.
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.ctaIcon,
    this.cta,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return GlassEmptyState(
      icon: icon,
      title: title,
      message: (subtitle != null && subtitle!.isNotEmpty) ? subtitle : null,
      actionLabel: ctaLabel,
      onAction: onCta,
      action: cta,
    );
  }
}
