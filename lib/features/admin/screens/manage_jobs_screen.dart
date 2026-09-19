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
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../jobs/providers/jobs_provider.dart';
import '../widgets/premium_card.dart';
import 'post_job_screen.dart';

class ManageJobsScreen extends ConsumerWidget {
  const ManageJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(adminJobsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Manage Jobs',
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_circle, color: AppColors.primary),
            tooltip: 'Post new job',
            onPressed: () => _openPostJob(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        tooltip: 'Post new job',
        onPressed: () => _openPostJob(context, ref),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminJobsProvider);
          await ref.read(adminJobsProvider.future);
        },
        child: jobs.when(
          data: (list) => list.isEmpty
              ? CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Iconsax.briefcase,
                        title: 'No jobs posted yet',
                        subtitle: 'Tap the + button to post your first job.',
                        cta: PremiumButton(
                          label: 'Post a Job',
                          icon: Iconsax.add,
                          expand: false,
                          onPressed: () => _openPostJob(context, ref),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _JobAdminCard(job: list[index]),
                ),
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: 5,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: ShimmerCard(height: 120),
            ),
          ),
          error: (e, _) => Center(
            child: EmptyState(
              icon: Iconsax.warning_2,
              title: 'Failed to load jobs',
              subtitle: ErrorUtils.sanitize(e),
              cta: PremiumButton(
                label: 'Retry',
                icon: Iconsax.refresh,
                variant: PremiumButtonVariant.tonal,
                expand: false,
                onPressed: () => ref.invalidate(adminJobsProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPostJob(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PostJobScreen()),
    );
    if (created == true) ref.invalidate(adminJobsProvider);
  }
}

// ─── Job Admin Card ───────────────────────────────────────────────────────────

class _JobAdminCard extends ConsumerWidget {
  final Map<String, dynamic> job;

  const _JobAdminCard({required this.job});

  static const _statusValues = ['active', 'closed', 'draft'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jobId = job['id'] as String? ?? '';
    final title = job['title'] as String? ?? 'Untitled';
    final category = job['category'] as String?;
    final paymentAmount = (job['payment_amount'] as num?)?.toDouble() ?? 0.0;
    final maxSlots = job['max_slots'] as int?;
    final status = job['status'] as String? ?? 'active';
    final deadline = job['deadline'] != null
        ? DateTime.tryParse(job['deadline'].toString())
        : null;
    final applicantCount = ref.watch(adminJobApplicantCountProvider(jobId));

    final isActive = status == 'active';
    final isHidden = status == 'draft'; // draft = hidden from users

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (category != null && category.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(status: status, isDark: isDark),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaItem(
                icon: Iconsax.money,
                label: '₹${_fmt(paymentAmount)}',
                color: AppColors.accentOrange,
              ),
              applicantCount.when(
                data: (n) => _MetaItem(
                  icon: Iconsax.people,
                  label: '$n applicant${n == 1 ? '' : 's'}',
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              if (maxSlots != null)
                _MetaItem(
                  icon: Iconsax.task_square,
                  label: '$maxSlots slots',
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              if (deadline != null)
                _MetaItem(
                  icon: Iconsax.calendar,
                  label: DateFormat('d MMM y').format(deadline),
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Action buttons: Edit | Hide/Show | Close/Open | Delete
          Row(
            children: [
              // Edit
              Expanded(
                child: _OutlineActionButton(
                  icon: Iconsax.edit,
                  label: 'Edit',
                  color: AppColors.primary,
                  onTap: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostJobScreen(existingJob: job),
                      ),
                    );
                    if (updated == true) ref.invalidate(adminJobsProvider);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Hide / Show (draft = hidden)
              Expanded(
                child: _OutlineActionButton(
                  icon: isHidden ? Iconsax.eye : Iconsax.eye_slash,
                  label: isHidden ? 'Show' : 'Hide',
                  color: AppColors.accentPurple,
                  onTap: () => _setStatus(
                    context,
                    ref,
                    jobId,
                    isHidden ? 'active' : 'draft',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Close / Reopen
              Expanded(
                child: _OutlineActionButton(
                  icon: isActive ? Iconsax.pause : Iconsax.play,
                  label: isActive ? 'Close' : 'Open',
                  color: isActive ? AppColors.warning : AppColors.success,
                  onTap: () => _setStatus(
                    context,
                    ref,
                    jobId,
                    isActive ? 'closed' : 'active',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Delete
              _OutlineActionButton(
                icon: Iconsax.trash,
                label: 'Del',
                color: AppColors.error,
                onTap: () => _confirmDelete(context, ref, jobId, title),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    String jobId,
    String newStatus,
  ) async {
    final ok = await ref
        .read(jobsActionsProvider.notifier)
        .updateJob(jobId, {'status': newStatus});
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorUtils.sanitize(
              ref.read(jobsActionsProvider).error)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String jobId,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job?'),
        content: Text(
          'This will permanently delete "$title" and all its applications. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await ref.read(jobsActionsProvider.notifier).deleteJob(jobId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      ok
          ? const SnackBar(
              content: Text('Job deleted.'),
              backgroundColor: AppColors.success,
            )
          : SnackBar(
              content: Text(
                  ErrorUtils.sanitize(ref.read(jobsActionsProvider).error)),
              backgroundColor: AppColors.error,
            ),
    );
  }

  String _fmt(double amount) =>
      amount >= 1000 ? NumberFormat('#,##0').format(amount) : amount.toStringAsFixed(0);
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  final bool isDark;

  const _StatusChip({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'active':
        bg = AppColors.success.withOpacity(0.12);
        fg = AppColors.success;
        break;
      case 'closed':
        bg = AppColors.error.withOpacity(0.12);
        fg = AppColors.error;
        break;
      case 'draft':
        bg = AppColors.accentPurple.withOpacity(0.12);
        fg = AppColors.accentPurple;
        break;
      default:
        bg = isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF3F4F6);
        fg = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    }

    final label = status == 'draft' ? 'Hidden' : status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.allSm),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaItem(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: AppRadius.allSm,
          border: Border.all(color: color.withOpacity(0.20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
