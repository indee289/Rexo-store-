import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// The premium, transparent/frosted-glass floating bottom navigation dock.
///
/// The dock reads as a translucent, blurred iOS-style bar so the content
/// scrolling behind it shows through the frost (the host [Scaffold] must set
/// `extendBody: true` — see `AppShell`). The frosted treatment is built from
/// the [AppGlass] tokens:
///   * a [ClipRRect] + [BackdropFilter] blur of [AppGlass.blurSigma] over the
///     translucent [AppGlass.dock] fill,
///   * a subtle light top rim via [AppGlass.border],
///   * a soft raised shadow so the dock floats above the content.
///
/// The active destination is tinted with [AppColors.primary], gets a soft
/// tonal pill indicator, an animated label, and a subtle press-scale. Branch
/// state preservation (indexed stack) is unchanged — this widget only reports
/// taps via [onTap].
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavDestination> _destinations = [
    _NavDestination(icon: Iconsax.home_2, label: 'Home'),
    _NavDestination(icon: Iconsax.briefcase, label: 'Campaigns'),
    _NavDestination(icon: Iconsax.shop, label: 'Shop'),
    _NavDestination(icon: Iconsax.messages_2, label: 'Inbox'),
    _NavDestination(icon: Iconsax.user, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: DecoratedBox(
          // Raised shadow lives outside the clip so it isn't blurred away.
          decoration: BoxDecoration(
            borderRadius: AppRadius.allXl,
            boxShadow: AppElevation.raised(isDark),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.allXl,
            child: BackdropFilter(
              // Frosted glass: blur whatever content sits behind the dock.
              filter: ui.ImageFilter.blur(
                sigmaX: AppGlass.blurSigma,
                sigmaY: AppGlass.blurSigma,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppGlass.dock(isDark),
                  borderRadius: AppRadius.allXl,
                  // Subtle light top rim for the glass edge.
                  border: Border.all(
                    color: AppGlass.border(isDark),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < _destinations.length; i++)
                      _NavItem(
                        icon: _destinations[i].icon,
                        label: _destinations[i].label,
                        isActive: currentIndex == i,
                        onTap: () => onTap(i),
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

/// Immutable description of a single dock destination.
class _NavDestination {
  final IconData icon;
  final String label;

  const _NavDestination({required this.icon, required this.label});
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color inactive = theme.colorScheme.onSurface.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.standard,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? AppSpacing.lg : AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          // Soft tonal pill indicator behind the active destination.
          color: isActive
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: AppRadius.allLg,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: AppMotion.base,
              curve: AppMotion.standard,
              child: Icon(
                icon,
                color: isActive ? AppColors.primary : inactive,
                size: 22,
              ),
            ),
            // Animated label only for the active item (keeps the dock compact).
            AnimatedSize(
              duration: AppMotion.base,
              curve: AppMotion.standard,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Text(
                        label,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
