import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../services/r2_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Circle avatar with image or initials fallback (teal bg, white text),
/// optional ring, size variants.
class PremiumAvatar extends StatefulWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showRing;
  final Gradient? ringGradient;
  final Color? ringColor;
  final double ringWidth;
  final bool isVerified;
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
    Widget avatar = _buildRingedAvatar();
    if (widget.isVerified) avatar = _withVerifiedBadge(avatar);
    if (!_interactive) return avatar;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: avatar,
      ),
    );
  }

  Widget _buildRingedAvatar() {
    final image = _buildImage();
    if (!widget.showRing) return image;

    return Container(
      padding: EdgeInsets.all(widget.ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: widget.ringColor == null
            ? (widget.ringGradient ?? AppColors.primaryGradient)
            : null,
        color: widget.ringColor,
      ),
      child: Container(
        padding: EdgeInsets.all(widget.ringWidth),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: image,
      ),
    );
  }

  Widget _buildImage() {
    final size = widget.size;
    final url = R2StorageService.publicUrlFor(widget.imageUrl);
    final dimension = size.round();

    final Widget content = url.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            memCacheWidth: dimension,
            memCacheHeight: dimension,
            placeholder: (context, _) => _buildPlaceholder(),
            errorWidget: (context, _, __) => _buildPlaceholder(),
          )
        : _buildPlaceholder();

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: content),
    );
  }

  Widget _buildPlaceholder() {
    final size = widget.size;
    final name = widget.name;

    if (name != null && name.trim().isNotEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: AppColors.primary,
        child: Text(
          _initials(name),
          style: AppTextStyles.labelLarge.copyWith(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.primaryBg,
      child: Icon(
        Iconsax.user,
        size: size * 0.5,
        color: AppColors.primary,
      ),
    );
  }

  Widget _withVerifiedBadge(Widget avatar) {
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
              color: AppColors.primary,
              border: Border.all(color: Colors.white, width: 2),
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
