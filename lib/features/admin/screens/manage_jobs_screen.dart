import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../jobs/providers/jobs_provider.dart';
import 'post_job_screen.dart';

/// Admin manage jobs — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` with a "post job" `IconButton` *and* a
/// `FloatingActionButton` doing the identical thing; admin-local
/// `PremiumCard`s whose footer squeezed four `_OutlineActionButton`s into one
/// row, the last of which had to be labelled "Del" to fit; and the old
/// `EmptyState` / `ShimmerCard` widgets.
///
/// New layout: the collapsing large title with one pinned create pill instead
/// of two competing create affordances; each card keeps Edit as a direct
/// action and moves hide/show, close/open and delete into a "Manage" sheet
/// where they are full-width rows with real labels; the status badge becomes a
/// `GlassChip.status`; and the states come from the shared glass set.
///
/// `adminJobsProvider`, `adminJobApplicantCountProvider`,
/// `jobsActionsProvider.updateJob`/`deleteJob`, the status strings
/// ('active' / 'closed' / 'draft', where draft means hidden from users), the
/// `PostJobScreen(existingJob:)` route and its boolean result are unchanged.
class ManageJobsScreen extends ConsumerWidget {
  const ManageJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(adminJobsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(adminJobsProvider);
              await ref.read(adminJobsProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const GlassLargeTitleHeader(
                  title: 'Manage jobs',
                  subtitle: 'Post, edit and close listings',
                  showBack: true,
                ),
                jobs.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: GlassEmptyState(
                          icon: AppIcons.briefcase,
                          title: 'No jobs posted yet',
                          message: 'Post your first job to get started.',
                          actionLabel: 'Post a job',
                          onAction: () => _openPostJob(context, ref),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        130,
                      ),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => AppSpacing.gapMd,
                        itemBuilder: (context, index) => RepaintBoundary(
                          child: _JobAdminCard(job: list[index]),
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: GlassListSkeleton(itemCount: 5),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassErrorState(
                      title: 'Failed to load jobs',
                      message: ErrorUtils.sanitize(e),
                      onRetry: () => ref.invalidate(adminJobsProvider),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: GlassButton(
              label: 'Post a job',
              icon: AppIcons.add,
              size: GlassButtonSize.large,
              onPressed: () => _openPostJob(context, ref),
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headline
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    if (category != null && category.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: AppTextStyles.caption1
                            .copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapSm,
              GlassChip.status(
                label: _statusLabel(status),
                color: _statusColor(status),
              ),
            ],
          ),

          AppSpacing.gapSm,

          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaItem(
                icon: AppIcons.money,
                label: '\u20B9${_fmt(paymentAmount)}',
                color: AppColors.accentOrange,
              ),
              applicantCount.when(
                data: (n) => _MetaItem(
                  icon: AppIcons.people,
                  label: '$n applicant${n == 1 ? '' : 's'}',
                  color: AppColors.textSecondary,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              if (maxSlots != null)
                _MetaItem(
                  icon: AppIcons.task_square,
                  label: '$maxSlots slots',
                  color: AppColors.textSecondary,
                ),
              if (deadline != null)
                _MetaItem(
                  icon: AppIcons.calendar,
                  label: DateFormat('d MMM y').format(deadline),
                  color: AppColors.textSecondary,
                ),
            ],
          ),

          AppSpacing.gapMd,

          Row(
            children: [
              Expanded(
                child: GlassButton.outline(
                  label: 'Edit',
                  icon: AppIcons.edit,
                  size: GlassButtonSize.small,
                  onPressed: () => _edit(context, ref),
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: GlassButton.glass(
                  label: 'Manage',
                  icon: AppIcons.setting_2,
                  size: GlassButtonSize.small,
                  onPressed: () =>
                      _showManageSheet(context, ref, jobId, title, status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PostJobScreen(existingJob: job),
      ),
    );
    if (updated == true) ref.invalidate(adminJobsProvider);
  }

  /// Visibility, open/close and delete — previously three cramped buttons in
  /// the card footer, the last of which read "Del".
  void _showManageSheet(
    BuildContext context,
    WidgetRef ref,
    String jobId,
    String title,
    String status,
  ) {
    final isActive = status == 'active';
    final isHidden = status == 'draft'; // draft = hidden from users

    showGlassSheet<void>(
      context: context,
      title: 'Manage job',
      subtitle: title,
      child: Builder(
        builder: (sheetContext) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassGroup(
              children: [
                GlassRow(
                  icon: isHidden ? AppIcons.eye : AppIcons.eye_slash,
                  iconColor: AppColors.accentPurple,
                  title: isHidden ? 'Show to users' : 'Hide from users',
                  subtitle: isHidden
                      ? 'Publish this job again'
                      : 'Keep it as a hidden draft',
                  showChevron: false,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _setStatus(context, ref, jobId, isHidden ? 'active' : 'draft');
                  },
                ),
                GlassRow(
                  icon: isActive ? AppIcons.pause : AppIcons.play,
                  iconColor:
                      isActive ? AppColors.warning : AppColors.success,
                  title: isActive ? 'Close applications' : 'Reopen job',
                  subtitle: isActive
                      ? 'Stop accepting new applicants'
                      : 'Start accepting applicants again',
                  showChevron: false,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _setStatus(
                        context, ref, jobId, isActive ? 'closed' : 'active');
                  },
                ),
              ],
            ),
            AppSpacing.gapLg,
            GlassButton.destructive(
              label: 'Delete job',
              icon: AppIcons.trash,
              onPressed: () {
                Navigator.pop(sheetContext);
                _confirmDelete(context, ref, jobId, title);
              },
            ),
          ],
        ),
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
      showGlassSnackBar(
        context,
        message: ErrorUtils.sanitize(ref.read(jobsActionsProvider).error),
        tone: GlassToastTone.error,
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String jobId,
    String title,
  ) async {
    final confirmed = await showGlassConfirm(
      context: context,
      title: 'Delete job?',
      message: 'This permanently deletes "$title" and all its applications. '
          'This cannot be undone.',
      icon: AppIcons.trash,
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref.read(jobsActionsProvider.notifier).deleteJob(jobId);
    if (!context.mounted) return;

    showGlassSnackBar(
      context,
      message: ok
          ? 'Job deleted.'
          : ErrorUtils.sanitize(ref.read(jobsActionsProvider).error),
      tone: ok ? GlassToastTone.success : GlassToastTone.error,
    );
  }

  String _fmt(double amount) => amount >= 1000
      ? NumberFormat('#,##0').format(amount)
      : amount.toStringAsFixed(0);
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

String _statusLabel(String status) {
  if (status == 'draft') return 'Hidden';
  if (status.isEmpty) return status;
  return status[0].toUpperCase() + status.substring(1);
}

Color _statusColor(String status) {
  switch (status) {
    case 'active':
      return AppColors.success;
    case 'closed':
      return AppColors.error;
    case 'draft':
      return AppColors.accentPurple;
    default:
      return AppColors.textSecondary;
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.footnote.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
