import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../jobs/providers/jobs_provider.dart';

/// Admin review of job submissions — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over admin-local `PremiumCard`s in which the
/// payment pill, the job-title pill, the notes block and the link-proof box
/// were each a separate hand-decorated `Container`, and rejecting opened an
/// `AlertDialog` whose body stacked a `Text` over a `PremiumTextField`.
///
/// New layout: a collapsing large title; the submitter, job and payout read as
/// one header row with the payout as a chip; the proof and the notes share the
/// card surface; and rejecting opens a glass sheet. States come from the
/// shared glass set.
///
/// `adminJobSubmissionsProvider`, `approveJobSubmission`,
/// `rejectJobSubmission(rejectionReason:)`, the `users`/`jobs` join keys, the
/// proof type switch and the external-application link launch are unchanged.
class ReviewJobSubmissionsScreen extends ConsumerWidget {
  const ReviewJobSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissions = ref.watch(adminJobSubmissionsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminJobSubmissionsProvider);
          await ref.read(adminJobSubmissionsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GlassLargeTitleHeader(
              title: 'Job submissions',
              subtitle: 'Approve to credit, reject to notify',
              showBack: true,
            ),
            submissions.when(
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.tick_circle,
                      title: 'All caught up',
                      message: 'No job submissions are pending review.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => AppSpacing.gapMd,
                    itemBuilder: (context, index) => RepaintBoundary(
                      child: _SubmissionCard(submission: list[index]),
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: GlassListSkeleton(itemCount: 4),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: GlassErrorState(
                  title: 'Failed to load submissions',
                  message: ErrorUtils.sanitize(e),
                  onRetry: () => ref.invalidate(adminJobSubmissionsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Submission Card ──────────────────────────────────────────────────────────

class _SubmissionCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> submission;

  const _SubmissionCard({required this.submission});

  @override
  ConsumerState<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends ConsumerState<_SubmissionCard> {
  bool _approving = false;
  bool _rejecting = false;

  @override
  Widget build(BuildContext context) {
    final sub = widget.submission;

    final applicationId = sub['id'] as String? ?? '';
    final user = sub['users'] as Map<String, dynamic>? ?? {};
    final job = sub['jobs'] as Map<String, dynamic>? ?? {};

    final userName = user['name'] as String? ?? 'Unknown User';
    final userHandle = user['username'] as String?; // live: username
    final userAvatar = user['profileImage'] as String?; // live: profileImage
    final jobTitle = job['title'] as String? ?? 'Untitled Job';
    final paymentAmount = (job['payment_amount'] as num?)?.toDouble() ?? 0.0;

    final submissionType = sub['submission_type'] as String? ?? 'link';
    final submissionUrl = sub['submission_url'] as String? ?? '';
    final submissionNote = sub['submission_note'] as String?;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Who submitted, and what it pays.
          Row(
            children: [
              AvatarWidget(url: userAvatar, name: userName, size: 40),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userName,
                      style: AppTextStyles.callout.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (userHandle != null && userHandle.isNotEmpty)
                      Text(
                        '@$userHandle',
                        style: AppTextStyles.caption1
                            .copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              AppSpacing.gapSm,
              GlassChip.status(
                label: '\u20B9${paymentAmount.toStringAsFixed(0)}',
                color: AppColors.accentOrange,
              ),
            ],
          ),

          AppSpacing.gapSm,
          GlassChip(
            label: jobTitle,
            icon: AppIcons.briefcase,
            dense: true,
          ),

          AppSpacing.gapMd,
          _sublabel('Submission'),
          _SubmissionProof(type: submissionType, url: submissionUrl),

          if (submissionNote != null && submissionNote.trim().isNotEmpty) ...[
            AppSpacing.gapSm,
            GlassCard(
              level: GlassLevel.subtle,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTES',
                    style: AppTextStyles.caption2.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    submissionNote,
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],

          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Approve',
                  icon: AppIcons.tick_circle,
                  size: GlassButtonSize.small,
                  loading: _approving,
                  onPressed: _rejecting ? null : _approve,
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: GlassButton.outline(
                  label: 'Reject',
                  icon: AppIcons.close_circle,
                  size: GlassButtonSize.small,
                  loading: _rejecting,
                  onPressed: _approving
                      ? null
                      : () => _showRejectSheet(applicationId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sublabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.caption2.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Future<void> _approve() async {
    setState(() => _approving = true);
    final applicationId = widget.submission['id'] as String? ?? '';
    final ok = await ref
        .read(jobsActionsProvider.notifier)
        .approveJobSubmission(applicationId);
    if (!mounted) return;
    setState(() => _approving = false);

    if (!ok) {
      final err = ref.read(jobsActionsProvider);
      showGlassSnackBar(
        context,
        message: err.hasError
            ? ErrorUtils.sanitize(err.error)
            : 'Approval failed.',
        tone: GlassToastTone.error,
      );
    } else {
      showGlassSnackBar(
        context,
        message: 'Submission approved & wallet credited.',
        tone: GlassToastTone.success,
      );
    }
  }

  /// Reject flow.
  ///
  /// The reason stays optional, exactly as before. The controller is disposed
  /// in a `finally` — the old version disposed it only on the happy path, so
  /// it leaked whenever the dialog was cancelled or the widget unmounted.
  Future<void> _showRejectSheet(String applicationId) async {
    final reasonCtrl = TextEditingController();
    try {
      final confirmed = await showGlassSheet<bool>(
        context: context,
        title: 'Reject submission',
        subtitle: 'The reason is optional, and the user will see it',
        child: Builder(
          builder: (sheetContext) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassTextField.multiline(
                controller: reasonCtrl,
                label: 'Reason (optional)',
                hint: 'e.g. The submitted link was not accessible…',
                minLines: 2,
                maxLines: 5,
              ),
              AppSpacing.gapLg,
              GlassButton.destructive(
                label: 'Reject submission',
                icon: AppIcons.close_circle,
                size: GlassButtonSize.large,
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
            ],
          ),
        ),
      );

      if (confirmed != true || !mounted) return;

      setState(() => _rejecting = true);
      final reason = reasonCtrl.text.trim();
      final ok =
          await ref.read(jobsActionsProvider.notifier).rejectJobSubmission(
                applicationId,
                rejectionReason: reason.isEmpty ? null : reason,
              );
      if (!mounted) return;
      setState(() => _rejecting = false);

      showGlassSnackBar(
        context,
        message: ok
            ? 'Submission rejected & user notified.'
            : ErrorUtils.sanitize(ref.read(jobsActionsProvider).error),
        tone: ok ? GlassToastTone.warning : GlassToastTone.error,
      );
    } finally {
      reasonCtrl.dispose();
    }
  }
}

// ─── Submission Proof Widget ──────────────────────────────────────────────────

class _SubmissionProof extends StatelessWidget {
  final String type;
  final String url;

  const _SubmissionProof({required this.type, required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Text(
        'No URL provided',
        style: AppTextStyles.footnote.copyWith(color: AppColors.textHint),
      );
    }

    switch (type) {
      case 'photo':
        return _PhotoProof(url: url);
      case 'video':
      case 'pdf':
      case 'link':
      default:
        return _LinkProof(url: url, type: type);
    }
  }
}

class _PhotoProof extends StatelessWidget {
  final String url;

  const _PhotoProof({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.allMd,
      child: Image.network(
        url,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _LinkProof(url: url, type: 'photo'),
      ),
    );
  }
}

class _LinkProof extends StatelessWidget {
  final String url;
  final String type;

  const _LinkProof({required this.url, required this.type});

  IconData get _icon {
    switch (type) {
      case 'video':
        return AppIcons.video;
      case 'pdf':
        return AppIcons.document;
      case 'photo':
        return AppIcons.gallery;
      default:
        return AppIcons.link;
    }
  }

  String get _typeLabel {
    switch (type) {
      case 'video':
        return 'Video submission';
      case 'pdf':
        return 'PDF submission';
      case 'photo':
        return 'Photo (link)';
      default:
        return 'Link submission';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      level: GlassLevel.subtle,
      rim: AppColors.primaryRim,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        children: [
          Icon(_icon, size: 20, color: AppColors.primary),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _typeLabel,
                  style: AppTextStyles.caption2
                      .copyWith(color: AppColors.textHint),
                ),
                Text(
                  url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          const Icon(AppIcons.export_1, size: 16, color: AppColors.textHint),
        ],
      ),
    );
  }
}
