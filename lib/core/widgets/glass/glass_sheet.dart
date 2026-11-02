import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_icon_button.dart';
import 'glass_surface.dart';

/// Shows a frosted-glass modal bottom sheet.
///
/// Presentation:
///   * One heavy [BackdropFilter] over the whole sheet, clipped to
///     [AppRadius.topXxl], with a specular sheen and a top rim light.
///   * A grab handle, a title row and a trailing close button.
///   * Height capped at 92% of the screen; tall content scrolls inside while
///     short content sizes to its own height.
///   * Keyboard-aware: the sheet lifts above the on-screen keyboard.
///   * Drag-to-dismiss and tap-outside-to-dismiss both enabled.
///
/// Returns the value the sheet is popped with, or `null` when dismissed.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  String? subtitle,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showCloseButton = true,
  EdgeInsetsGeometry? padding,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    // We paint our own frosted pane, so the framework surface must be fully
    // transparent or an opaque Material sheet would cover the blur.
    backgroundColor: Colors.transparent,
    elevation: 0,
    // This primitive draws its own handle; suppress the themed one.
    showDragHandle: false,
    clipBehavior: Clip.none,
    barrierColor: AppGlass.scrim(false),
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (_) => GlassSheet(
      title: title,
      subtitle: subtitle,
      showCloseButton: showCloseButton,
      padding: padding,
      child: child,
    ),
  );
}

/// The frosted sheet pane itself. Normally created by [showGlassSheet], but
/// exposed for use as a `Scaffold.bottomSheet` or inside a custom route.
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.showCloseButton = true,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showCloseButton;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      // Lift above the on-screen keyboard when a field inside is focused.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: AppRadius.topXxl,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: AppGlass.blurSigmaModal,
            sigmaY: AppGlass.blurSigmaModal,
          ),
          child: GlassBlurScope(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppGlass.surface(false),
                borderRadius: AppRadius.topXxl,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.topXxl,
                          gradient: AppGlass.sheen,
                        ),
                      ),
                    ),
                  ),
                  // Top rim light.
                  Positioned(
                    top: 0,
                    left: AppRadius.xxl,
                    right: AppRadius.xxl,
                    height: AppGlass.borderWidth,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: AppGlass.rimHighlight,
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: media.size.height * 0.92),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _GrabHandle(),
                          _TitleRow(
                            title: title,
                            subtitle: subtitle,
                            showCloseButton: showCloseButton,
                          ),
                          Flexible(
                            child: Padding(
                              padding: padding ??
                                  const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.xs,
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                  ),
                              child: child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withOpacity(0.18),
        borderRadius: AppRadius.pillAll,
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.subtitle,
    required this.showCloseButton,
  });

  final String title;
  final String? subtitle;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.title2
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
          if (showCloseButton) ...[
            AppSpacing.gapSm,
            GlassIconButton(
              icon: Iconsax.close_circle,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onTap: () => Navigator.of(context).maybePop(),
              size: 34,
              iconSize: 19,
            ),
          ],
        ],
      ),
    );
  }
}
