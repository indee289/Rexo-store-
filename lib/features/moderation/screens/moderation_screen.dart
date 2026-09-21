import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/moderation_provider.dart';

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      data: (profileState) {
        if (!profileState.isAdmin) {
          return _buildAccessDenied(context);
        }
        return _buildAdminContent(context, ref);
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (_, __) => _buildAccessDenied(context),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Moderation', showBack: true),
      body: const EmptyState(
        icon: Iconsax.lock,
        title: 'Access denied',
        subtitle: 'Only administrators can access moderation tools.',
      ),
    );
  }

  Widget _buildAdminContent(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PremiumAppBar(
          title: 'Moderation',
          showBack: true,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: AppColors.primary,
            labelStyle:
                AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w400),
            tabs: const [
              Tab(text: 'Queue'),
              Tab(text: 'AI Logs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildQueueTab(context, ref),
            _buildAILogsTab(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTab(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(moderationQueueProvider);

    return queueAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Iconsax.tick_circle,
            title: 'Queue is clear',
            subtitle: 'No pending moderation items',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _buildQueueItem(context, ref, items[index]),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: ShimmerLoading(height: 400),
      ),
      error: (_, __) => const EmptyState(
        icon: Iconsax.warning_2,
        title: 'Failed to load queue',
      ),
    );
  }

  Widget _buildQueueItem(
      BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    final contentType = item['content_type'] ?? 'unknown';
    final reason = item['reason'] ?? 'No reason';
    final reportedBy = item['reported_by'] ?? 'Unknown';
    final itemId = item['id'] as String;
    final createdAt = item['created_at'] != null
        ? DateFormat('MMM dd, HH:mm').format(DateTime.parse(item['created_at']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: AppRadius.allSm,
                ),
                child: Text(
                  contentType[0].toUpperCase() + contentType.substring(1).toLowerCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                createdAt,
                style: AppTextStyles.caption.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reason,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reported by: $reportedBy',
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  label: 'Reject',
                  variant: PremiumButtonVariant.outline,
                  expand: true,
                  onPressed: () {
                    ref
                        .read(moderationActionProvider.notifier)
                        .rejectItem(itemId);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PremiumButton(
                  label: 'Approve',
                  expand: true,
                  onPressed: () {
                    ref
                        .read(moderationActionProvider.notifier)
                        .approveItem(itemId);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAILogsTab(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(aiModerationLogsProvider);

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const EmptyState(
            icon: Iconsax.chart_2,
            title: 'No AI moderation logs',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: logs.length,
          itemBuilder: (context, index) =>
              _buildAILogItem(context, logs[index]),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: ShimmerLoading(height: 400),
      ),
      error: (_, __) => const EmptyState(
        icon: Iconsax.warning_2,
        title: 'Failed to load AI logs',
      ),
    );
  }

  Widget _buildAILogItem(BuildContext context, Map<String, dynamic> log) {
    final flaggedReason = log['flagged_reason'] ?? 'Unknown';
    final confidenceScore = (log['confidence_score'] as num?)?.toDouble() ?? 0.0;
    final actionTaken = log['action_taken'] ?? 'none';
    final contentType = log['content_type'] ?? 'unknown';
    final createdAt = log['created_at'] != null
        ? DateFormat('MMM dd, HH:mm').format(DateTime.parse(log['created_at']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.chart_2, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  flaggedReason,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                contentType,
                style: AppTextStyles.labelSmall.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Confidence score progress bar
          Row(
            children: [
              Text(
                'Confidence:',
                style: AppTextStyles.caption.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.allSm,
                  child: LinearProgressIndicator(
                    value: confidenceScore,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      confidenceScore > 0.8
                          ? AppColors.error
                          : confidenceScore > 0.5
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${(confidenceScore * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Row(
            children: [
              Text(
                'Action: $actionTaken',
                style: AppTextStyles.caption.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              Text(
                createdAt,
                style: AppTextStyles.caption.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
