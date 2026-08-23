import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// A compact, reusable verified checkmark badge.
///
/// Designed to sit inline right after a username / handle [Text] widget.
/// Typical usage inside a [Row]:
///
/// ```dart
/// Row(
///   mainAxisSize: MainAxisSize.min,
///   children: [
///     Text('@$handle'),
///     if (isVerified) const VerifiedBadge(size: 14),
///   ],
/// )
/// ```
///
/// A [SizedBox] of ~4px is baked into the widget (via [gap]) so callers can
/// simply drop it after the username without manually adding spacing.
class VerifiedBadge extends StatelessWidget {
  /// Diameter of the checkmark icon in logical pixels.
  final double size;

  /// Icon color. Defaults to the classic verified blue.
  final Color color;

  /// Leading horizontal gap placed before the badge so it visually
  /// separates from the preceding username text. Set to 0 to disable.
  final double gap;

  /// The default verified-badge blue (Twitter/X style).
  static const Color defaultColor = Color(0xFF1DA1F2);

  const VerifiedBadge({
    super.key,
    this.size = 14,
    this.color = defaultColor,
    this.gap = 4,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Iconsax.verify,
      size: size,
      color: color,
    );

    if (gap <= 0) return icon;

    return Padding(
      padding: EdgeInsets.only(left: gap),
      child: icon,
    );
  }
}
