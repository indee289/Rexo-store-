import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../services/r2_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text_styles.dart';

/// Premium consolidated avatar primitive (Component_Library).
///
/// Replaces ad-hoc `CircleAvatar` usages and supersedes `AvatarWidget` as the
/// single avatar renderer for the redesign. It renders a circular avatar via
/// [CachedNetworkImage] (caching + placeholder + error fallback) with:
///   * initials / glyph fallback when no image is available,
///   * an optional gradient/solid **ring** (Instagram-story style) with a thin
///     surface gap between the ring and the image,
///   * an optional **verified** overlay badge in the bottom-right corner,
///   * a subtle press-scale when [onTap] is provided.
///
/// It is token-driven (colors, radii, motion, text styles) and decodes the
/// network image at display resolution to keep memory usage low.
class PremiumAvatar extends StatefulWidget {
  /// Remote image URL. When null/empty the [name] initials (or a glyph) show.
  final String? imageUrl;

  /// Display name used to derive initials for the placeholder.
  final String? name;

  /// Avatar diameter in logical pixels. Use one of the [sizeSm]/[sizeMd]/
  /// [sizeLg]/[sizeXl] presets or a custom value.
  final double size;

  /// Draws a ring around the avatar (with a small surface gap).
  final bool showRing;

  /// Gradient used for the ring. Defaults to [AppColors.primaryGradient].
  /// Ignored when [ringColor] is provided.
  final Gradient? ringGradient;

  /// Solid ring color. When set it overrides [ringGradient].
  final Color? ringColor;

  /// Ring thickness.
  final double ringWidth;

  /// Shows a verified checkmark badge overlay in the bottom-right corner.
  final bool isVerified;

  /// Optional tap handler; enables press-scale feedback when non-null.
  final VoidCallback? onTap;

  const PremiumAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = sizeMd,
    this.showRing = false,
    this.ringGradient,
    this.ringColor,
    this.ringWidth = 2.5,
    this.isVerified = false,
    this.onTap,
  });

  /// Size presets.
  static const double sizeSm = 32;
  static const double sizeMd = 48;
  static const double sizeLg = 72;
  static const double sizeXl = 96;

  @override
  State<PremiumAvatar> createState() => _PremiumAvatarState();
}

class _PremiumAvatarState extends State<PremiumAvatar> {
  bool _pressed = false;

  bool get _interactive => widget.onTap != null;

  void _setPressed(bool value) {
    if (!_interactive || value == _pressed) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = _buildRingedAvatar(context);

    if (widget.isVerified) {
      avatar = _withVerifiedBadge(context, avatar);
    }

    if (!_interactive) return avatar;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: avatar,
      ),
    );
  }

  Widget _buildRingedAvatar(BuildContext context) {
    final image = _buildImage(context);
    if (!widget.showRing) return image;

    final surface = Theme.of(context).colorScheme.surface;
    final gap = widget.ringWidth; // surface gap between ring and image
    final ringColor = widget.ringColor;

    return Container(
      padding: EdgeInsets.all(widget.ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ringColor == null
            ? (widget.ringGradient ?? AppColors.primaryGradient)
            : null,
        color: ringColor,
      ),
      child: Container(
        padding: EdgeInsets.all(gap),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: surface,
        ),
        child: image,
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final size = widget.size;
    // Normalize stored URLs (private R2 S3 endpoint -> public URL) so both new
    // and previously-persisted avatars render.
    final url = R2StorageService.publicUrlFor(widget.imageUrl);
    final dimension = size.round();

    final Widget content = url.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            // Decode at display size to reduce memory usage.
            memCacheWidth: dimension,
            memCacheHeight: dimension,
            placeholder: (context, _) => _buildPlaceholder(context),
            errorWidget: (context, _, __) => _buildPlaceholder(context),
          )
        : _buildPlaceholder(context);

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: content),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final size = widget.size;
    final name = widget.name;

    if (name != null && name.trim().isNotEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: AppColors.primary.withOpacity(0.12),
        child: Text(
          _initials(name),
          style: AppTextStyles.labelLarge.copyWith(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      );
    }

    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: onSurface.withOpacity(0.08),
      child: Icon(
        Iconsax.user,
        size: size * 0.5,
        color: onSurface.withOpacity(0.4),
      ),
    );
  }

  Widget _withVerifiedBadge(BuildContext context, Widget avatar) {
    final surface = Theme.of(context).colorScheme.surface;
    // Badge scales with the avatar but stays within sensible bounds.
    final badgeSize = (widget.size * 0.34).clamp(16.0, 28.0);
    final iconSize = badgeSize * 0.7;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.verified,
              border: Border.all(color: surface, width: 2),
            ),
            child: Icon(
              Iconsax.verify,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
