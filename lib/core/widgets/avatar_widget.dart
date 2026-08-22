import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A circular avatar widget with CachedNetworkImage, placeholder, and optional border.
class AvatarWidget extends StatelessWidget {
  final String? url;
  final double size;
  final String? name;
  final bool showBorder;
  final Color borderColor;

  const AvatarWidget({
    super.key,
    this.url,
    this.size = 48,
    this.name,
    this.showBorder = false,
    this.borderColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: borderColor, width: 2)
            : null,
      ),
      child: ClipOval(
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    if (name != null && name!.isNotEmpty) {
      final initials = _getInitials(name!);
      return Container(
        width: size,
        height: size,
        color: AppColors.primary.withOpacity(0.1),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      color: AppColors.border,
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: AppColors.textHint,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
