import 'package:flutter/material.dart';

/// A reusable premium card container used across the app.
///
/// It renders a theme-aware surface with rounded corners, a subtle 1px border
/// (`theme.dividerColor`) and a mode-aware shadow so the card visually
/// separates from the background in BOTH light and dark themes. All three
/// campaign/product cards (Home, Campaigns, Shop) route their outer container
/// through this widget so identical data looks identical everywhere.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardContent = Container(
      padding: padding,
      // Clip the child (e.g. cover images) to the rounded corners so headers
      // never bleed past the border radius.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            // Stronger shadow in dark mode so the card lifts off the near-black
            // background; soft shadow in light mode.
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
            offset: const Offset(0, 2),
            blurRadius: isDark ? 8 : 6,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
