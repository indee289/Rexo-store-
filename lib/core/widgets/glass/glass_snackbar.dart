import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_surface.dart';

/// Tone of a glass snackbar, which picks its icon and accent colour.
enum GlassToastTone { neutral, success, error, warning }

/// Floating frosted toast.
///
/// Shown via `ScaffoldMessenger` so it respects route changes and the existing
/// snackbar queue, but rendered as a pill-shaped glass pane instead of a
/// Material bar: transparent background, no elevation, and our own blur.
void showGlassSnackBar(
  BuildContext context, {
  required String message,
  GlassToastTone tone = GlassToastTone.neutral,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: _GlassToast(
        message: message,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
      duration: duration,
      // The toast paints its own glass pane, so the SnackBar chrome must be
      // completely invisible.
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      dismissDirection: DismissDirection.horizontal,
    ),
  );
}

class _GlassToast extends StatelessWidget {
  const _GlassToast({
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final GlassToastTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  (IconData, Color) get _toneStyle {
    switch (tone) {
      case GlassToastTone.success:
        return (Iconsax.tick_circle, AppColors.success);
      case GlassToastTone.error:
        return (Iconsax.close_circle, AppColors.error);
      case GlassToastTone.warning:
        return (Iconsax.warning_2, AppColors.warning);
      case GlassToastTone.neutral:
        return (Iconsax.info_circle, AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, accent) = _toneStyle;

    return ClipRRect(
      borderRadius: AppRadius.pillAll,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: AppGlass.blurSigmaModal,
          sigmaY: AppGlass.blurSigmaModal,
        ),
        child: GlassBlurScope(
          child: DecoratedBox(
            decoration: BoxDecoration(
              // A touch more opaque than a standard pane: a toast must stay
              // readable over whatever happens to be behind it.
              color: Colors.white.withOpacity(0.86),
              borderRadius: AppRadius.pillAll,
              border: Border.all(
                color: AppColors.border,
                width: AppGlass.borderWidth,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: accent),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Text(
                      message,
                      style: AppTextStyles.subheadline.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                    ),
                  ),
                  if (actionLabel != null) ...[
                    AppSpacing.gapSm,
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        ScaffoldMessenger.maybeOf(context)
                            ?.hideCurrentSnackBar();
                        onAction?.call();
                      },
                      child: Text(
                        actionLabel!,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
