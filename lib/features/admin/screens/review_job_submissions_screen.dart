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
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../jobs/providers/jobs_provider.dart';
import '../widgets/premium_card.dart';

class ReviewJobSubmissionsScreen extends ConsumerWidget {
  const ReviewJobSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissions = ref.watch(adminJobSubmissionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const PremiumAppBar(title: 'Review Job Submissions'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminJobSubmissionsProvider);
          await ref.read(adminJobSubmissionsProvider.future);
        },
        child: submissions.when(
          data: (list) => list.isEmpty
              ? CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Iconsax.tick_circle,
                        title: 'All caught up!',
                        subtitle: 'No job submissions are pending review.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) =>
                      _SubmissionCard(submission: list[index]),
                ),
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: 4,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: ShimmerCard(height: 200),
            ),
          ),
          error: (e, _) => Center(
            child: EmptyState(
              icon: Iconsax.warning_2,
              title: 'Failed to load submissions',
              subtitle: ErrorUtils.sanitize(e),
              cta: PremiumButton(
                label: 'Retry',
                icon: Iconsax.refresh,
                variant: PremiumButtonVariant.tonal,
                expand: false,
                onPressed: () => ref.invalidate(adminJobSubmissionsProvider),
              ),
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = widget.submission;

    final applicationId = sub['id'] as String? ?? '';
    final user = sub['users'] as Map<String, dynamic>? ?? {};
    final job = sub['jobs'] as Map<String, dynamic>? ?? {};

    final userName = user['name'] as String? ?? 'Unknown User';
    final userHandle = user['handle'] as String?;
    final userAvatar = user['avatar_url'] as String?;
    final jobTitle = job['title'] as String? ?? 'Untitled Job';
    final paymentAmount = (job['payment_amount'] as num?)?.toDouble() ?? 0.0;

    final submissionType = sub['submission_type'] as String? ?? 'link';
    final submissionUrl = sub['submission_url'] as String? ?? '';
    final submissionNote = sub['submission_note'] as String?;

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User + Job info ────────────────────────────────────────────
          Row(
            children: [
              AvatarWidget(
                url: userAvatar,
                name: userName,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    if (userHandle != null && userHandle.isNotEmpty)
                      Text(
                        '@$userHandle',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                  ],
                ),
              ),
              // Payment pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withOpacity(0.12),
                  borderRadius: AppRadius.allSm,
                ),
                child: Text(
                  '₹${paymentAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentOrange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Job title
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: AppRadius.allSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.briefcase,
                    size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Submission proof ───────────────────────────────────────────
          Text(
            'Submission',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          _SubmissionProof(
            type: submissionType,
            url: submissionUrl,
            isDark: isDark,
          ),

          // Optional notes
          if (submissionNote != null && submissionNote.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceAlt
                    : AppColors.surfaceAlt,
                borderRadius: AppRadius.allSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    submissionNote,
                    style: TextStyle(fontSize: 13, color: textPrimary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // ── Approve / Reject buttons ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  label: 'Approve',
                  icon: Iconsax.tick_circle,
                  loading: _approving,
                  onPressed: _rejecting ? null : _approve,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PremiumButton(
                  label: 'Reject',
                  icon: Iconsax.close_circle,
                  variant: PremiumButtonVariant.outline,
                  loading: _rejecting,
                  onPressed: _approving ? null : () => _showRejectDialog(context, applicationId),
                ),
              ),
            ],
          ),
        ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.hasError
              ? ErrorUtils.sanitize(err.error)
              : 'Approval failed.'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submission approved & wallet credited.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _showRejectDialog(
      BuildContext context, String applicationId) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provide an optional reason — the user will see this.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            PremiumTextField.multiline(
              controller: reasonCtrl,
              hint: 'e.g. The submitted link was not accessible…',
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _rejecting = true);
    final ok = await ref
        .read(jobsActionsProvider.notifier)
        .rejectJobSubmission(
          applicationId,
          rejectionReason: reasonCtrl.text.trim().isEmpty
              ? null
              : reasonCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _rejecting = false);
    reasonCtrl.dispose();

    ScaffoldMessenger.of(context).showSnackBar(
      ok
          ? const SnackBar(
              content: Text('Submission rejected & user notified.'),
              backgroundColor: AppColors.warning,
            )
          : SnackBar(
              content: Text(ErrorUtils.sanitize(
                  ref.read(jobsActionsProvider).error)),
              backgroundColor: AppColors.error,
            ),
    );
  }
}

// ─── Submission Proof Widget ──────────────────────────────────────────────────

class _SubmissionProof extends StatelessWidget {
  final String type;
  final String url;
  final bool isDark;

  const _SubmissionProof({
    required this.type,
    required this.url,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Text(
        'No URL provided',
        style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextHint : AppColors.textHint),
      );
    }

    switch (type) {
      case 'photo':
        return _PhotoProof(url: url, isDark: isDark);
      case 'video':
      case 'pdf':
      case 'link':
      default:
        return _LinkProof(url: url, type: type, isDark: isDark);
    }
  }
}

class _PhotoProof extends StatelessWidget {
  final String url;
  final bool isDark;

  const _PhotoProof({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.allMd,
      child: Image.network(
        url,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _LinkProof(
          url: url,
          type: 'photo',
          isDark: isDark,
        ),
      ),
    );
  }
}

class _LinkProof extends StatelessWidget {
  final String url;
  final String type;
  final bool isDark;

  const _LinkProof(
      {required this.url, required this.type, required this.isDark});

  IconData get _icon {
    switch (type) {
      case 'video':
        return Iconsax.video;
      case 'pdf':
        return Iconsax.document;
      case 'photo':
        return Iconsax.gallery;
      default:
        return Iconsax.link;
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
    final bg = isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.textHint;

    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.allSm,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.20),
          ),
        ),
        child: Row(
          children: [
            Icon(_icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: textHint,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Iconsax.export_1, size: 16, color: textHint),
          ],
        ),
      ),
    );
  }
}
