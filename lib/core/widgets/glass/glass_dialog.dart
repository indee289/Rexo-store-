import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_button.dart';
import 'glass_card.dart';
import 'glass_surface.dart';

/// Frosted modal dialog.
///
/// Replaces `AlertDialog` everywhere. Actions stack vertically — a glass pill
/// pair side-by-side gets cramped on narrow phones and the primary action
/// deserves full width.
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.iconColor,
    this.confirmLabel,
    this.onConfirm,
    this.cancelLabel,
    this.onCancel,
    this.destructive = false,
    this.loading = false,
  });

  final String title;

  /// Simple body text. Ignored when [content] is supplied.
  final String? message;

  /// Custom body, for dialogs that need fields or a list.
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final String? confirmLabel;
  final VoidCallback? onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;

  /// Renders the confirm action in error red.
  final bool destructive;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final accent =
        iconColor ?? (destructive ? AppColors.error : AppColors.primary);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClipRRect(
            borderRadius: AppRadius.allXl,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: AppGlass.blurSigmaModal,
                sigmaY: AppGlass.blurSigmaModal,
              ),
              child: GlassBlurScope(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppGlass.surface(false),
                    borderRadius: AppRadius.allXl,
                    border: Border.all(
                      color: AppGlass.border(false),
                      width: AppGlass.borderWidth,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.allXl,
                              gradient: AppGlass.sheen,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (icon != null) ...[
                              Center(
                                child: GlassIconBubble(
                                  icon: icon!,
                                  color: accent,
                                  size: 56,
                                  iconSize: 28,
                                ),
                              ),
                              AppSpacing.gapLg,
                            ],
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.title2
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                            if (content != null) ...[
                              AppSpacing.gapMd,
                              content!,
                            ] else if (message != null) ...[
                              AppSpacing.gapSm,
                              Text(
                                message!,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                            if (confirmLabel != null ||
                                cancelLabel != null) ...[
                              AppSpacing.gapXl,
                              if (confirmLabel != null)
                                GlassButton(
                                  label: confirmLabel!,
                                  loading: loading,
                                  variant: destructive
                                      ? GlassButtonVariant.destructive
                                      : GlassButtonVariant.filled,
                                  onPressed: onConfirm ??
                                      () => Navigator.of(context)
                                          .maybePop(true),
                                ),
                              if (confirmLabel != null && cancelLabel != null)
                                AppSpacing.gapSm,
                              if (cancelLabel != null)
                                GlassButton.glass(
                                  label: cancelLabel!,
                                  onPressed: loading
                                      ? null
                                      : (onCancel ??
                                          () => Navigator.of(context)
                                              .maybePop(false)),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a [GlassDialog] over a blurred, dimmed barrier.
///
/// Returns `true` when confirmed, `false` when cancelled, `null` when
/// dismissed by tapping the barrier.
Future<bool?> showGlassDialog({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  IconData? icon,
  Color? iconColor,
  String? confirmLabel,
  VoidCallback? onConfirm,
  String? cancelLabel,
  VoidCallback? onCancel,
  bool destructive = false,
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: AppGlass.scrim(false),
    builder: (_) => GlassDialog(
      title: title,
      message: message,
      content: content,
      icon: icon,
      iconColor: iconColor,
      confirmLabel: confirmLabel,
      onConfirm: onConfirm,
      cancelLabel: cancelLabel,
      onCancel: onCancel,
      destructive: destructive,
    ),
  );
}

/// Convenience wrapper for a yes/no confirmation. Resolves to `true` only when
/// the user explicitly confirms.
Future<bool> showGlassConfirm({
  required BuildContext context,
  required String title,
  String? message,
  IconData? icon,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showGlassDialog(
    context: context,
    title: title,
    message: message,
    icon: icon,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    destructive: destructive,
  );
  return result ?? false;
}
