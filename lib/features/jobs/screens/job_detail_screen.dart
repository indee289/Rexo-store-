import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/demo_asset_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/jobs_provider.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final hasApplied = ref.watch(hasAppliedToJobProvider(jobId));
    final slotData = ref.watch(jobSlotCountProvider(jobId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return const Center(child: Text('Job not found'));
          }
          final slotFilled = (slotData.value?['filled'] as int?) ?? 0;
          final hasAppliedVal = hasApplied.value ?? false;
          final maxSlots = job['max_slots'] as int?;
          final isFull = maxSlots != null && slotFilled >= maxSlots;
          final isClosed = (job['status'] as String? ?? '') == 'closed';

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            bottomNavigationBar: _ApplyBar(
              jobId: jobId,
              job: job,
              hasApplied: hasAppliedVal,
              isFull: isFull,
              isClosed: isClosed,
            ),
            body: _JobDetailScrollView(
              job: job,
              jobId: jobId,
              hasApplied: hasAppliedVal,
              slotFilled: slotFilled,
            ),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Iconsax.warning_2,
            title: 'Failed to load job',
            subtitle: ErrorUtils.sanitize(e),
            cta: PremiumButton(
              label: 'Retry',
              icon: Iconsax.refresh,
              variant: PremiumButtonVariant.tonal,
              expand: false,
              onPressed: () => ref.invalidate(jobDetailProvider(jobId)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Scrollable Body ──────────────────────────────────────────────────────────

class _JobDetailScrollView extends StatelessWidget {
  final Map<String, dynamic> job;
  final String jobId;
  final bool hasApplied;
  final int slotFilled;

  const _JobDetailScrollView({
    required this.job,
    required this.jobId,
    required this.hasApplied,
    required this.slotFilled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = job['title'] as String? ?? 'Untitled Job';
    final description = job['description'] as String? ?? '';
    final category = job['category'] as String?;
    final paymentAmount = (job['payment_amount'] as num?)?.toDouble() ?? 0.0;
    final maxSlots = job['max_slots'] as int?;
    final deadline = job['deadline'] != null
        ? DateTime.tryParse(job['deadline'].toString())
        : null;
    final coverUrl = job['cover_image_url'] as String?;
    final jobStatus = job['status'] as String? ?? 'active';
    final createdAt = job['created_at'] != null
        ? DateTime.tryParse(job['created_at'].toString())
        : null;

    // New optional fields: read straight off the SELECT * job map by key.
    // The stored platform value is a comma-joined string; split into pills.
    final platforms = (job['platform'] ?? '')
        .toString()
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final rules = (job['rules'] ?? '').toString();
    final demoType = (job['demo_asset_type'] ?? '').toString();
    final demoUrl = (job['demo_asset_url'] ?? '').toString();

    final isActive = jobStatus == 'active';
    final isFull = maxSlots != null && slotFilled >= maxSlots;

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    // Slots value string.
    late final String slotsValue;
    Color? slotsColor;
    if (maxSlots == null) {
      slotsValue = 'Unlimited';
    } else if (isFull) {
      slotsValue = 'Slots Full';
      slotsColor = AppColors.error;
    } else {
      slotsValue = '${maxSlots - slotFilled} of $maxSlots slots left';
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover header with overlaid app bar + status pill.
                _CoverHeader(
                  coverUrl: coverUrl,
                  isActive: isActive,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: AppTextStyles.h4.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 23,
                        ),
                      ),

                      // Category + platform pills
                      if ((category != null && category.isNotEmpty) ||
                          platforms.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            if (category != null && category.isNotEmpty)
                              _CategoryPill(
                                category: category,
                                isDark: isDark,
                                textSecondary: textSecondary,
                              ),
                            for (final p in platforms)
                              _PlatformPill(
                                platform: p,
                                isDark: isDark,
                                textSecondary: textSecondary,
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      // Payment card
                      _PaymentCard(
                        amount: paymentAmount,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Details card
                      _DetailsCard(
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        rows: [
                          if (deadline != null)
                            _DetailRowData(
                              icon: Iconsax.calendar,
                              label: 'Deadline',
                              value: DateFormat('d MMM y').format(deadline),
                            ),
                          _DetailRowData(
                            icon: Iconsax.people,
                            label: 'Slots',
                            value: slotsValue,
                            valueColor: slotsColor,
                          ),
                          if (createdAt != null)
                            _DetailRowData(
                              icon: Iconsax.clock,
                              label: 'Posted',
                              value: _relativeTime(createdAt),
                            ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Description & Instructions
                      Text(
                        'Description & Instructions',
                        style: AppTextStyles.h6.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ExpandableText(
                        text: description.isEmpty
                            ? 'No description provided.'
                            : description,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // What to submit
                      _WhatToSubmitCard(
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      ),

                      // Rules — new optional field. Render only when present.
                      if (rules.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Rules',
                          style: AppTextStyles.h6.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: AppRadius.allLg,
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            rules,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      // Demo Asset — new optional field. Render only when both
                      // the type and the value are present.
                      if (demoType.isNotEmpty && demoUrl.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Demo Asset',
                          style: AppTextStyles.h6.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DemoAssetView(type: demoType, value: demoUrl),
                      ],

                      // Bottom padding so content clears the sticky Apply bar.
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Relative-time helper for the 'Posted' row.
  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return '$w ${w == 1 ? 'week' : 'weeks'} ago';
    }
    final months = (diff.inDays / 30).floor();
    return '$months ${months == 1 ? 'month' : 'months'} ago';
  }
}

// ─── Cover Header ─────────────────────────────────────────────────────────────

class _CoverHeader extends StatelessWidget {
  final String? coverUrl;
  final bool isActive;

  const _CoverHeader({required this.coverUrl, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;

    return Stack(
      children: [
        // Cover image / gradient placeholder.
        Container(
          height: 200 + topPad,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.lg),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasCover
              ? Image.network(
                  coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                )
              : const Center(
                  child: Icon(
                    Iconsax.briefcase,
                    size: 56,
                    color: Colors.white70,
                  ),
                ),
        ),

        // Top overlay row: back, title, bookmark.
        Positioned(
          top: topPad + AppSpacing.sm,
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PremiumIconButton(
                icon: Iconsax.arrow_left,
                background: true,
                color: Colors.white,
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(
                'Job Details',
                style: AppTextStyles.h6.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              PremiumIconButton(
                icon: Iconsax.save_2,
                background: true,
                color: Colors.white,
                tooltip: 'Save',
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Status pill (top-right, below the app bar row).
        Positioned(
          top: topPad + 64,
          right: AppSpacing.lg,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.neutral,
              borderRadius: AppRadius.pillAll,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              isActive ? 'Active' : 'Closed',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Category Pill ────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final String category;
  final bool isDark;
  final Color textSecondary;

  const _CategoryPill({
    required this.category,
    required this.isDark,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.category, size: 14, color: textSecondary),
          const SizedBox(width: 6),
          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Platform Pill ────────────────────────────────────────────────────────────

class _PlatformPill extends StatelessWidget {
  final String platform;
  final bool isDark;
  final Color textSecondary;

  const _PlatformPill({
    required this.platform,
    required this.isDark,
    required this.textSecondary,
  });

  IconData get _icon {
    final p = platform.toLowerCase();
    if (p.contains('insta')) return Iconsax.instagram;
    if (p.contains('face')) return Iconsax.facebook;
    if (p.contains('you')) return Iconsax.youtube;
    return Iconsax.global;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: textSecondary),
          const SizedBox(width: 6),
          Text(
            platform,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment Card ─────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final double amount;
  final Color cardColor;
  final Color borderColor;
  final Color textSecondary;

  const _PaymentCard({
    required this.amount,
    required this.cardColor,
    required this.borderColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: AppRadius.allMd,
            ),
            child: const Icon(
              Iconsax.wallet,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${_formatAmount(amount)}',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Per approved submission',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) return NumberFormat('#,##0').format(amount);
    return amount.toStringAsFixed(
        amount.truncateToDouble() == amount ? 0 : 2);
  }
}

// ─── Details Card ─────────────────────────────────────────────────────────────

class _DetailRowData {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class _DetailsCard extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final List<_DetailRowData> rows;

  const _DetailsCard({
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(rows[i].icon, size: 18, color: textSecondary),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Text(
                      rows[i].label,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: rows[i].valueColor ?? textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Expandable Description ───────────────────────────────────────────────────

class _ExpandableText extends StatefulWidget {
  final String text;
  final Color textSecondary;

  const _ExpandableText({required this.text, required this.textSecondary});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  static const int _collapsedLines = 4;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: widget.textSecondary,
      height: 1.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final tp = TextPainter(
              text: TextSpan(text: widget.text, style: style),
              maxLines: _collapsedLines,
              textDirection: Directionality.of(context),
            )..layout(maxWidth: constraints.maxWidth);
            final overflows = tp.didExceedMaxLines;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.text,
                  style: style,
                  maxLines: _expanded ? null : _collapsedLines,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
                if (overflows) ...[
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded ? 'Read less' : 'Read more',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── What To Submit Card ──────────────────────────────────────────────────────

class _WhatToSubmitCard extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _WhatToSubmitCard({
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What to submit',
            style: AppTextStyles.h6.copyWith(
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Submit your work in any of the following formats:',
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _SubmitChip(icon: Iconsax.link, label: 'Link'),
              _SubmitChip(icon: Iconsax.gallery, label: 'Photo'),
              _SubmitChip(icon: Iconsax.document, label: 'PDF'),
              _SubmitChip(icon: Iconsax.video, label: 'Video'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmitChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SubmitChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sticky Apply Bar ─────────────────────────────────────────────────────────

class _ApplyBar extends ConsumerStatefulWidget {
  final String jobId;
  final Map<String, dynamic> job;
  final bool hasApplied;
  final bool isFull;
  final bool isClosed;

  const _ApplyBar({
    required this.jobId,
    required this.job,
    required this.hasApplied,
    required this.isFull,
    required this.isClosed,
  });

  @override
  ConsumerState<_ApplyBar> createState() => _ApplyBarState();
}

class _ApplyBarState extends ConsumerState<_ApplyBar> {
  bool _applying = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    // Already applied — disabled green state.
    if (widget.hasApplied) {
      return _StatusButton(
        label: 'Already Applied',
        icon: Iconsax.tick_circle,
        color: AppColors.success,
      );
    }
    // Slots full — disabled red state.
    if (widget.isFull) {
      return _StatusButton(
        label: 'Slots Full',
        icon: Iconsax.slash,
        color: AppColors.error,
      );
    }
    // Closed — disabled neutral state.
    if (widget.isClosed) {
      return _StatusButton(
        label: 'Closed',
        icon: Iconsax.slash,
        color: AppColors.neutral,
      );
    }
    // Active — orange Apply Now CTA.
    return _ApplyNowButton(loading: _applying, onPressed: _apply);
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    final ok = await ref
        .read(jobsActionsProvider.notifier)
        .applyToJob(widget.jobId);
    if (!mounted) return;
    setState(() => _applying = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final error = ref.read(jobsActionsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.hasError
              ? ErrorUtils.sanitize(error.error)
              : 'Could not apply. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// Instagram-blue "Apply Now" CTA — flat, tight, 48px tall (bounded so it
/// cannot expand to fill the full sticky bar area).
class _ApplyNowButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _ApplyNowButton({required this.loading, required this.onPressed});

  @override
  State<_ApplyNowButton> createState() => _ApplyNowButtonState();
}

class _ApplyNowButtonState extends State<_ApplyNowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.loading ? null : widget.onPressed,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.7 : 1.0,
        child: Container(
          // Fixed height (was minHeight — that could expand in Column with
          // unbounded height, causing the button to fill the screen).
          height: 48,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.allMd,
          ),
          child: widget.loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.send_1, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Apply Now',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A disabled, tinted status button (Already Applied / Slots Full / Closed).
class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
