import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Instagram-style empty state.
///
/// Minimal, content-first — a thin-stroke circular outline containing a
/// single line-drawn icon, followed by a big black title, a gray subtitle,
/// and a blue text CTA (Instagram-style link button). No colored tiles,
/// no gradients, no shadows.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final IconData? ctaIcon;
  final Widget? cta;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.ctaIcon,
    this.cta,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.xxl,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final Widget? ctaWidget = cta ??
        ((ctaLabel != null && onCta != null)
            ? _InstagramLinkCta(
                label: ctaLabel!,
                onPressed: onCta!,
              )
            : null);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // IG-style thin-stroke circle with icon inside
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textPrimary,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 44,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Big bold black title (IG "Share your first Reel" style)
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),

            // Gray subtitle
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            // Instagram-style blue text CTA
            if (ctaWidget != null) ...[
              const SizedBox(height: 20),
              ctaWidget,
            ],
          ],
        ),
      ),
    );
  }
}

/// Instagram-style blue text-link CTA — bold blue text, no fill, subtle
/// press feedback.
class _InstagramLinkCta extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _InstagramLinkCta({required this.label, required this.onPressed});

  @override
  State<_InstagramLinkCta> createState() => _InstagramLinkCtaState();
}

class _InstagramLinkCtaState extends State<_InstagramLinkCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            widget.label,
            style: AppTextStyles.headline.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
