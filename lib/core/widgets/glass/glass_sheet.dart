import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_icon_button.dart';

/// Shows a modal bottom sheet.
///
/// Presentation:
///   * An opaque surface clipped to [AppRadius.topXxl], lifted by the modal
///     shadow. The previous version ran a heavy `BackdropFilter` plus a sheen
///     and a rim light over the whole sheet; a sheet covers most of the screen,
///     so that was the most expensive blur in the app.
///   * A grab handle, a title row and a trailing close button.
///   * Height capped at 92% of the screen; tall content scrolls inside while
///     short content sizes to itself.
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
    // The sheet paints its own surface, so the framework's must be invisible.
    backgroundColor: Colors.transparent,
    elevation: 0,
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

/// The sheet surface itself. Normally created by [showGlassSheet], but exposed
/// for use as a `Scaffold.bottomSheet` or inside a custom route.
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.topXxl,
          boxShadow: AppElevation.modal(false),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.topXxl,
          child: ColoredBox(
            color: AppColors.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
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
      width: 40,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.systemGray4,
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
              icon: AppIcons.close_circle,
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
