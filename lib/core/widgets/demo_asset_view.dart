import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Read-only renderer for a campaign / job demo asset.
///
/// It mirrors the persisted `demo_asset_type` string keys
/// (`image` | `video` | `pdf` | `link` | `text`) written by [DemoAssetField].
/// The [value] semantics match what was stored:
///   * image / video / pdf -> a public (R2) URL,
///   * link -> the pasted external URL,
///   * text -> the raw text body.
///
/// Nothing is rendered when [type] or [value] is empty; callers must still
/// guard the surrounding section, but this widget is defensive too.
///
/// The same widget is used by both the campaign and job detail screens so the
/// two stay pixel-identical and never drift.
class DemoAssetView extends StatelessWidget {
  final String type;
  final String value;

  const DemoAssetView({
    super.key,
    required this.type,
    required this.value,
  });

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = type.trim().toLowerCase();
    final v = value.trim();
    if (t.isEmpty || v.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (t) {
      case 'image':
        return _ImageView(url: v, isDark: isDark);
      case 'video':
        return _LinkCard(
          icon: Iconsax.video,
          label: 'Watch Video',
          subtitle: 'Opens in an external player',
          isDark: isDark,
          onTap: () => _launch(v),
        );
      case 'pdf':
        return _LinkCard(
          icon: Iconsax.document,
          label: 'View PDF',
          subtitle: 'Opens in your browser',
          isDark: isDark,
          onTap: () => _launch(v),
        );
      case 'link':
        return _LinkCard(
          icon: Iconsax.link,
          label: 'Open Link',
          subtitle: v,
          isDark: isDark,
          onTap: () => _launch(v),
        );
      case 'text':
        return _TextView(text: v, isDark: isDark);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Image ────────────────────────────────────────────────────────────────────

class _ImageView extends StatelessWidget {
  final String url;
  final bool isDark;

  const _ImageView({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final hint = isDark ? AppColors.darkTextHint : AppColors.textHint;

    return ClipRRect(
      borderRadius: AppRadius.allLg,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: border),
        ),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 160,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.gallery, size: 32, color: hint),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Image unavailable',
                  style: TextStyle(fontSize: 12, color: hint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tappable link/video/pdf card ───────────────────────────────────────────────

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _LinkCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.12),
                borderRadius: AppRadius.allMd,
              ),
              child: Icon(icon, size: 22, color: AppColors.accentOrange),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Iconsax.arrow_right_3, size: 18, color: textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Inline text ────────────────────────────────────────────────────────────────

class _TextView extends StatelessWidget {
  final String text;
  final bool isDark;

  const _TextView({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}
