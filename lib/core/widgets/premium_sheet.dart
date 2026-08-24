import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_glass.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Premium modal bottom-sheet primitive (Component_Library).
///
/// Standardizes every modal bottom sheet in the app so they share one modern,
/// premium, iOS-style frosted-glass treatment instead of ad-hoc
/// `showModalBottomSheet` bodies.
///
/// Presentation (token-driven only):
///   * Frosted glass: a [BackdropFilter] with [AppGlass.blurSigma] behind a
///     translucent [AppGlass.surface] tint, clipped with [AppRadius.topXl] top
///     corners so it reads as an iOS frosted sheet.
///   * A centered grab handle and a hairline top rim ([AppGlass.border]).
///   * A title row with a close button on the trailing edge.
///   * Bottom safe-area padding and keyboard-aware inset handling.
///   * Scroll-controlled height that caps the sheet at 90% of the screen and
///     lets tall content scroll inside; drag-to-dismiss is enabled.
///
/// Requirements: 11.6 (modal bottom sheets via the Component_Library sheet
/// primitive with a grab handle, a title row, and safe-area padding).
///
/// Returns the value the sheet is popped with, or `null` when dismissed.
Future<T?> showPremiumSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    // We paint our own frosted background, so the framework surface must be
    // fully transparent (otherwise a solid Material sheet covers the blur).
    backgroundColor: Colors.transparent,
    elevation: 0,
    // Keep the framework from clipping/rounding on top of our custom clip.
    clipBehavior: Clip.none,
    barrierColor: Colors.black.withOpacity(0.4),
    // Drag-to-dismiss + tap-outside-to-dismiss.
    isDismissible: true,
    enableDrag: true,
    builder: (sheetContext) => _PremiumSheet(title: title, child: child),
  );
}

class _PremiumSheet extends StatelessWidget {
  const _PremiumSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    return Padding(
      // Lift the sheet above the on-screen keyboard when a field is focused.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: AppRadius.topXl,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: AppGlass.blurSigma,
            sigmaY: AppGlass.blurSigma,
          ),
          child: Container(
            // Scroll-controlled height: cap the sheet and let tall content
            // scroll inside the flexible body below.
            constraints: BoxConstraints(
              maxHeight: media.size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: AppGlass.surface(isDark),
              borderRadius: AppRadius.topXl,
              border: Border(
                top: BorderSide(color: AppGlass.border(isDark), width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GrabHandle(isDark: isDark),
                  _TitleRow(title: title),
                  // Tall content scrolls; short content sizes to its intrinsic
                  // height thanks to the min-size column.
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
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
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.20),
        borderRadius: AppRadius.pillAll,
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h5,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.gapSm,
          // NOTE: Once `PremiumIconButton` (task 2.3) lands, swap this fallback
          // for `PremiumIconButton(icon: Iconsax.close_circle, onTap: ...)`.
          // Kept as a plain Iconsax close button so this primitive compiles
          // independently of task 2.3.
          _CloseButton(
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Close',
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          // 44x44 tap target, matching the PremiumIconButton spec.
          width: 44,
          height: 44,
          child: Icon(
            Iconsax.close_circle,
            size: 24,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
