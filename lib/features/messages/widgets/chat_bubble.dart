import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/message_view.dart';

/// Premium iOS-style chat bubble (Layer 3 composite).
///
/// Renders one of three states derived from the typed [MessageView]:
/// - **unsent** (`message.isUnsent`): an italic, greyed "message unsent"
///   placeholder that exposes **no** long-press actions.
/// - **edited** (`message.isEdited`): the content plus a small "edited" label.
/// - **normal**: the content only.
///
/// For the current user's own bubbles ([isMine]) a read tick is shown next to
/// the timestamp. Bubble color, radius, and spacing are fully token-driven.
///
/// The bubble uses a "grouped-tail" radius: when [showTail] is `true` (the last
/// message in a run from the same sender) the corner nearest the sender is
/// tightened to form a tail; otherwise all corners stay uniformly rounded so
/// stacked bubbles read as a single group.
///
/// See design "Components > ChatBubble" (Requirements 4.3, 5.2, 6.5, 13.4).
class ChatBubble extends StatelessWidget {
  final MessageView message;
  final bool isMine;

  /// Whether this bubble is the last in a same-sender group (renders a tail).
  final bool showTail;

  /// Opens the message actions sheet. Only wired for the current user's own,
  /// non-unsent messages; `null` (e.g. for unsent bubbles) disables long-press.
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showTail = true,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Unsent bubbles never expose actions, regardless of the passed callback.
    final effectiveLongPress = message.isUnsent ? null : onLongPress;

    final bubbleColor = isMine
        ? AppColors.primary
        : (theme.brightness == Brightness.dark
            ? AppColors.darkSurfaceAlt
            : AppColors.surfaceAlt);

    final onBubbleColor =
        isMine ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: effectiveLongPress,
        child: Container(
          margin: EdgeInsets.only(
            bottom: showTail ? AppSpacing.sm : AppSpacing.xs,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: _bubbleRadius(),
          ),
          child: message.isUnsent
              ? _UnsentContent(onBubbleColor: onBubbleColor)
              : _NormalContent(
                  message: message,
                  isMine: isMine,
                  onBubbleColor: onBubbleColor,
                ),
        ),
      ),
    );
  }

  /// Grouped-tail radius: the corner nearest the sender is tightened to a
  /// small tail radius only on the last bubble in a same-sender group.
  ///
  /// Uses an airy ~18px base rounding (a hair above [AppRadius.lg]) so bubbles
  /// read as the soft, iOS-style pills in the reference, with a gently softened
  /// [AppRadius.sm] tail corner rather than a sharp point.
  BorderRadius _bubbleRadius() {
    const double r = (AppRadius.lg + AppRadius.xl) / 2 - 2; // ~18
    const double tail = AppRadius.sm; // softened tail corner
    final double tailRadius = showTail ? tail : r;
    return BorderRadius.only(
      topLeft: const Radius.circular(r),
      topRight: const Radius.circular(r),
      bottomLeft: Radius.circular(isMine ? r : tailRadius),
      bottomRight: Radius.circular(isMine ? tailRadius : r),
    );
  }
}

/// Body for a normal / edited message: content, optional "edited" label,
/// timestamp, and (for mine) a read tick.
class _NormalContent extends StatelessWidget {
  final MessageView message;
  final bool isMine;
  final Color onBubbleColor;

  const _NormalContent({
    required this.message,
    required this.isMine,
    required this.onBubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(message.createdAt);
    final metaColor = onBubbleColor.withOpacity(isMine ? 0.75 : 0.5);

    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.displayContent,
          style: AppTextStyles.bodyMedium.copyWith(color: onBubbleColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.isEdited) ...[
              Text(
                'edited',
                style: AppTextStyles.caption.copyWith(
                  color: metaColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              timeStr,
              style: AppTextStyles.caption.copyWith(color: metaColor),
            ),
            if (isMine) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Iconsax.tick_circle,
                size: 12,
                color: message.isRead ? Colors.white : metaColor,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Body for an unsent message: a greyed, italic "message unsent" placeholder.
class _UnsentContent extends StatelessWidget {
  final Color onBubbleColor;

  const _UnsentContent({required this.onBubbleColor});

  @override
  Widget build(BuildContext context) {
    final placeholderColor = onBubbleColor.withOpacity(0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Iconsax.slash, size: 14, color: placeholderColor),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'message unsent',
          style: AppTextStyles.bodyMedium.copyWith(
            color: placeholderColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
