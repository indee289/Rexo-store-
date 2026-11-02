import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'glass_button.dart';
import 'glass_card.dart';
import 'glass_surface.dart';

/// Empty state — a glass pane with an icon bubble, message and optional action.
///
/// Every list in the app funnels through this, so "nothing here yet" looks
/// deliberate instead of blank.
class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.action,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A fully custom action widget. Takes precedence over
  /// [actionLabel] / [onAction] when supplied.
  final Widget? action;

  /// Tighter spacing, for an empty state inside a card or a short section.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
        child: GlassCard(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: compact ? AppSpacing.xl : AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassIconBubble(
                icon: icon ?? Iconsax.box,
                size: compact ? 52 : 68,
                iconSize: compact ? 26 : 34,
              ),
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.title3.copyWith(color: AppColors.textPrimary),
              ),
              if (message != null) ...[
                AppSpacing.gapSm,
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subheadline.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              if (action != null) ...[
                AppSpacing.gapLg,
                action!,
              ] else if (actionLabel != null && onAction != null) ...[
                AppSpacing.gapLg,
                GlassButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  size: GlassButtonSize.small,
                  expand: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state — same shape as the empty state, tinted red, with a retry.
class GlassErrorState extends StatelessWidget {
  const GlassErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.compact = false,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
        child: GlassCard(
          rim: AppColors.error.withOpacity(0.28),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: compact ? AppSpacing.xl : AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassIconBubble(
                icon: Iconsax.warning_2,
                color: AppColors.error,
                size: compact ? 52 : 68,
                iconSize: compact ? 26 : 34,
              ),
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.title3.copyWith(color: AppColors.textPrimary),
              ),
              if (message != null) ...[
                AppSpacing.gapSm,
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subheadline.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              if (onRetry != null) ...[
                AppSpacing.gapLg,
                GlassButton(
                  label: retryLabel,
                  onPressed: onRetry,
                  size: GlassButtonSize.small,
                  expand: false,
                  icon: Iconsax.refresh,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Centred brand-red spinner on the glass backdrop.
class GlassLoader extends StatelessWidget {
  const GlassLoader({super.key, this.message, this.size = 30});

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            AppSpacing.gapMd,
            Text(
              message!,
              style: AppTextStyles.footnote
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single shimmering glass placeholder block.
///
/// Used to build skeletons that match the glass aesthetic: a frosted pane with
/// a sheen sweeping across it, rather than the old opaque grey bars.
class GlassSkeleton extends StatefulWidget {
  const GlassSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<GlassSkeleton> createState() => _GlassSkeletonState();
}

class _GlassSkeletonState extends State<GlassSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadius.allXs;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppGlass.recessed(false),
            borderRadius: radius,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // Sweep a soft highlight from left to right.
              final t = _controller.value;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + t * 2.4 - 0.6, 0),
                    end: Alignment(-1.0 + t * 2.4 + 0.6, 0),
                    colors: const [
                      Color(0x00FFFFFF),
                      Color(0x80FFFFFF),
                      Color(0x00FFFFFF),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Skeleton shaped like a [GlassListCard] — for list loading states.
class GlassListSkeleton extends StatelessWidget {
  const GlassListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => AppSpacing.gapMd,
      itemBuilder: (_, __) => RepaintBoundary(
        child: GlassSurface(
          level: GlassLevel.card,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const GlassSkeleton(
                width: 44,
                height: 44,
                borderRadius: AppRadius.allSm,
              ),
              AppSpacing.gapMd,
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassSkeleton(height: 14),
                    SizedBox(height: 8),
                    GlassSkeleton(width: 140, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
