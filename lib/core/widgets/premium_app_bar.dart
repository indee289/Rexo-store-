import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_text_styles.dart';

/// A consistent premium, iOS-style app bar (Component_Library).
///
/// Wraps [AppBar] so every screen renders the same premium treatment defined by
/// the shared `AppBarTheme` (surface background, `elevation: 0`,
/// `scrolledUnderElevation: 0.5`, tint-free flat surface, centered
/// [AppTextStyles.h5] title). This removes the need for screens to re-declare
/// those values inline (and the ad-hoc `GoogleFonts.poppins(...)` titles that
/// drifted from the token system).
///
/// * [title] renders with [AppTextStyles.h5] inheriting the theme foreground.
/// * When [showBack] is true (or [onBack] is provided), a premium Iconsax back
///   control is shown as the leading widget. Otherwise [leading] is used, or
///   the platform's automatic leading when [automaticallyImplyLeading] is true.
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text rendered with the standard [AppTextStyles.h5] style.
  final String title;

  /// Trailing action widgets.
  final List<Widget>? actions;

  /// Explicit leading widget. Ignored when [showBack] is true.
  final Widget? leading;

  /// When true, shows a premium Iconsax back control that invokes [onBack]
  /// (defaulting to `Navigator.maybePop`).
  final bool showBack;

  /// Tap handler for the back control. Only used when [showBack] is true.
  final VoidCallback? onBack;

  /// Forwarded to [AppBar.automaticallyImplyLeading].
  final bool automaticallyImplyLeading;

  /// Optional bottom widget (e.g. a `TabBar`).
  final PreferredSizeWidget? bottom;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    Widget? resolvedLeading = leading;
    // Render a premium Iconsax back control when explicitly requested, or when
    // no leading is supplied and the route can actually be popped. This keeps
    // the back glyph consistent (Iconsax, not the default Material arrow) while
    // preserving the "only show back when poppable" behaviour.
    final bool showAutoBack = leading == null &&
        automaticallyImplyLeading &&
        Navigator.of(context).canPop();
    if (showBack || showAutoBack) {
      resolvedLeading = IconButton(
        icon: const Icon(Iconsax.arrow_left),
        color: onSurface,
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.h5.copyWith(color: onSurface),
      ),
      leading: resolvedLeading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      bottom: bottom,
    );
  }
}
