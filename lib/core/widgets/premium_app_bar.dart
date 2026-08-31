import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Premium frosted-glass AppBar for the Rexo app.
///
/// Features:
/// * Frosted glass (BackdropFilter + translucent fill) in glass mode
/// * Bold centered title with Poppins typography
/// * Premium Iconsax back button with animated press scale
/// * Optional gradient title accent
/// * Smooth fade-in entrance animation
/// * Configurable: solid surface, frosted glass, or transparent
enum PremiumAppBarStyle {
  /// Clean solid surface background (default, matches AppBarTheme)
  solid,

  /// Frosted glass — translucent blur shows content scrolling behind
  glass,

  /// Fully transparent — for use over hero images/gradients
  transparent,
}

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text.
  final String title;

  /// Optional trailing action widgets.
  final List<Widget>? actions;

  /// Explicit leading widget. Ignored when [showBack] is true.
  final Widget? leading;

  /// Whether to show a premium Iconsax back button.
  final bool showBack;

  /// Tap handler for the back button.
  final VoidCallback? onBack;

  /// Forwarded to AppBar.automaticallyImplyLeading.
  final bool automaticallyImplyLeading;

  /// Optional bottom widget (e.g. a TabBar).
  final PreferredSizeWidget? bottom;

  /// Visual style of the bar.
  final PremiumAppBarStyle style;

  /// When true, the title uses a gradient accent color.
  final bool gradientTitle;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.style = PremiumAppBarStyle.solid,
    this.gradientTitle = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    // Resolve leading widget
    Widget? resolvedLeading = leading;
    final bool showAutoBack = leading == null &&
        automaticallyImplyLeading &&
        Navigator.of(context).canPop();

    if (showBack || showAutoBack) {
      resolvedLeading = _PremiumBackButton(
        color: onSurface,
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    // Build title widget
    Widget titleWidget = gradientTitle
        ? ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              title,
              style: AppTextStyles.h5.copyWith(color: Colors.white),
            ),
          )
        : Text(
            title,
            style: AppTextStyles.h5.copyWith(color: onSurface),
          );

    titleWidget = titleWidget
        .animate()
        .fadeIn(duration: AppMotion.base, curve: AppMotion.standard);

    // Determine background
    Color? backgroundColor;
    switch (style) {
      case PremiumAppBarStyle.solid:
        backgroundColor = theme.appBarTheme.backgroundColor;
        break;
      case PremiumAppBarStyle.glass:
        backgroundColor = Colors.transparent;
        break;
      case PremiumAppBarStyle.transparent:
        backgroundColor = Colors.transparent;
        break;
    }

    Widget appBar = AppBar(
      title: titleWidget,
      leading: resolvedLeading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: 4),
      ],
      bottom: bottom,
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation:
          style == PremiumAppBarStyle.glass ? 0 : 0.5,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    );

    // Wrap with frosted glass effect for glass style
    if (style == PremiumAppBarStyle.glass) {
      return ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: AppGlass.blurSigma,
            sigmaY: AppGlass.blurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppGlass.dock(isDark),
              border: Border(
                bottom: BorderSide(
                  color: AppGlass.border(isDark),
                  width: 0.5,
                ),
              ),
            ),
            child: appBar,
          ),
        ),
      );
    }

    // Solid style: add a subtle bottom border
    if (style == PremiumAppBarStyle.solid) {
      return Container(
        decoration: BoxDecoration(
          color: theme.appBarTheme.backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor,
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              offset: const Offset(0, 1),
              blurRadius: 8,
            ),
          ],
        ),
        child: appBar,
      );
    }

    return appBar;
  }
}

/// Premium animated back button with Iconsax glyph and press-scale feedback.
class _PremiumBackButton extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;

  const _PremiumBackButton({required this.color, required this.onTap});

  @override
  State<_PremiumBackButton> createState() => _PremiumBackButtonState();
}

class _PremiumBackButtonState extends State<_PremiumBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScale : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.08),
            borderRadius: AppRadius.allMd,
          ),
          child: Icon(
            Iconsax.arrow_left,
            color: widget.color,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Sliver version of the premium app bar for CustomScrollView integration.
class PremiumSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? flexibleSpace;
  final double expandedHeight;
  final bool pinned;
  final bool floating;

  const PremiumSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.onBack,
    this.flexibleSpace,
    this.expandedHeight = 200,
    this.pinned = true,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    Widget? leading;
    final bool showAutoBack = Navigator.of(context).canPop();
    if (showBack || showAutoBack) {
      leading = _PremiumBackButton(
        color: onSurface,
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    return SliverAppBar(
      title: Text(
        title,
        style: AppTextStyles.h5.copyWith(color: onSurface),
      ),
      leading: leading,
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: 4),
      ],
      backgroundColor: theme.appBarTheme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      expandedHeight: flexibleSpace != null ? expandedHeight : null,
      pinned: pinned,
      floating: floating,
      flexibleSpace: flexibleSpace,
    );
  }
}
