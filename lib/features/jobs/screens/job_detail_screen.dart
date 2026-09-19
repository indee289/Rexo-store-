import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_button.dart';
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
            bottomNavigationBar:
                (!hasAppliedVal && !isFull && !isClosed)
                    ? _ApplyBar(jobId: jobId, job: job)
                    : null,
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

    final isClosed = jobStatus == 'closed';
    final isFull = maxSlots != null && slotFilled >= maxSlots;

    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return CustomScrollView(
      slivers: [
        // App bar with optional cover image
        SliverAppBar(
          expandedHeight:
              (coverUrl != null && coverUrl.isNotEmpty) ? 220 : 0,
          pinned: true,
          backgroundColor: bgColor,
          surfaceTintColor: Colors.transparent,
          foregroundColor: textPrimary,
          leading: IconButton(
            icon: Icon(Icons.chevron_left, size: 28, color: textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: (coverUrl != null && coverUrl.isNotEmpty)
              ? FlexibleSpaceBar(
                  background: Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: bgColor),
                  ),
                )
              : null,
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + category
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.h5.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (category != null && category.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _CategoryBadge(category: category),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Payment — hero number
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withOpacity(0.10),
                    borderRadius: AppRadius.allMd,
                    border: Border.all(
                        color: AppColors.accentOrange.withOpacity(0.20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.money,
                          size: 22, color: AppColors.accentOrange),
                      const SizedBox(width: 8),
                      Text(
                        '₹${_formatAmount(paymentAmount)}',
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.accentOrange,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'payment',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.accentOrange.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Meta info cards row
                if (deadline != null || maxSlots != null)
                  Row(
                    children: [
                      if (deadline != null)
                        Expanded(
                          child: _MetaCard(
                            icon: Iconsax.calendar,
                            label: 'Deadline',
                            value: DateFormat('d MMM y').format(deadline),
                            isDark: isDark,
                            cardColor: cardColor,
                            borderColor: borderColor,
                          ),
                        ),
                      if (deadline != null && maxSlots != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (maxSlots != null)
                        Expanded(
                          child: _MetaCard(
                            icon: Iconsax.people,
                            label: 'Slots',
                            value: isFull
                                ? 'Full'
                                : '${maxSlots - slotFilled} of $maxSlots left',
                            isDark: isDark,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            valueColor:
                                isFull ? AppColors.error : null,
                          ),
                        ),
                    ],
                  ),

                if (deadline != null || maxSlots != null)
                  const SizedBox(height: AppSpacing.md),

                // Closed banner
                if (isClosed) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: AppRadius.allMd,
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.slash,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: Text(
                            'This job is no longer accepting applications.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Already applied banner
                if (hasApplied) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.10),
                      borderRadius: AppRadius.allMd,
                      border: Border.all(
                          color: AppColors.success.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.tick_circle,
                            size: 20, color: AppColors.success),
                        const SizedBox(width: AppSpacing.sm),
                        const Text(
                          'Already Applied',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Slots full banner
                if (isFull && !hasApplied) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: AppRadius.allMd,
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.20)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.slash, size: 20, color: AppColors.error),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Slots Full',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Description
                Text(
                  'Description & Instructions',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textSecondary,
                    height: 1.6,
                  ),
                ),

                // Extra bottom padding so content clears the Apply bar
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) return NumberFormat('#,##0').format(amount);
    return amount.toStringAsFixed(
        amount.truncateToDouble() == amount ? 0 : 2);
  }
}

// ─── Floating Apply Bar ───────────────────────────────────────────────────────

class _ApplyBar extends ConsumerStatefulWidget {
  final String jobId;
  final Map<String, dynamic> job;

  const _ApplyBar({required this.jobId, required this.job});

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
      child: PremiumButton(
        label: 'Apply Now',
        icon: Iconsax.briefcase,
        loading: _applying,
        onPressed: _apply,
      ),
    );
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

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: AppRadius.allSm,
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color? valueColor;

  const _MetaCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final hint =
        isDark ? AppColors.darkTextHint : AppColors.textHint;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: hint,
                        fontWeight: FontWeight.w500)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? fg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
