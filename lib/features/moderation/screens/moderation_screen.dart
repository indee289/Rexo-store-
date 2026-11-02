import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/moderation_provider.dart';

/// Moderation — rebuilt layout.
///
/// Old layout: `DefaultTabController` + a Material `TabBar` in the app bar's
/// bottom slot driving a `TabBarView`; both tabs rendered `ListView`s of
/// hand-built `Container` cards with inline type badges.
///
/// New layout: collapsing large title with a segmented control in its pinned
/// slot; queue items as cards whose two actions are a proper destructive /
/// confirm pair; and AI logs as cards where the confidence bar is the primary
/// visual, since that is what a moderator scans for.
///
/// The admin gate, `moderationQueueProvider`, `aiModerationLogsProvider` and
/// `moderationActionProvider.approveItem` / `rejectItem` are unchanged.
class ModerationScreen extends ConsumerStatefulWidget {
  const ModerationScreen({super.key});

  @override
  ConsumerState<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends ConsumerState<ModerationScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      data: (profileState) =>
          profileState.isAdmin ? _admin() : _accessDenied(),
      loading: () => const GlassScaffold(body: GlassLoader()),
      error: (_, __) => _accessDenied(),
    );
  }

  Widget _accessDenied() {
    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: const [
          GlassLargeTitleHeader(title: 'Moderation', showBack: true),
          SliverFillRemaining(
            hasScrollBody: false,
            child: GlassEmptyState(
              icon: AppIcons.lock,
              title: 'Access denied',
              message: 'Only administrators can access moderation tools.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _admin() {
    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(
            title: 'Moderation',
            showBack: true,
            bottomHeight: 62,
            bottom: GlassTabBar(
              labels: const ['Queue', 'AI logs'],
              selectedIndex: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
          ),
          SliverToBoxAdapter(
            child: IndexedStack(
              index: _tab,
              sizing: StackFit.loose,
              children: const [_QueueTab(), _AiLogsTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueTab extends ConsumerWidget {
  const _QueueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(moderationQueueProvider);

    return queueAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const GlassEmptyState(
            icon: AppIcons.tick_circle,
            title: 'Queue is clear',
            message: 'No pending moderation items.',
            compact: true,
          );
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
          ),
          child: Column(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: RepaintBoundary(child: _QueueCard(item: item)),
                ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: GlassLoader(),
      ),
      error: (_, __) => GlassErrorState(
        compact: true,
        title: 'Failed to load queue',
        onRetry: () => ref.invalidate(moderationQueueProvider),
      ),
    );
  }
}

class _QueueCard extends ConsumerWidget {
  const _QueueCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentType = (item['content_type'] ?? 'unknown').toString();
    final reason = (item['reason'] ?? 'No reason').toString();
    final reportedBy = (item['reported_by'] ?? 'Unknown').toString();
    final itemId = item['id'] as String;
    final createdAt = item['created_at'] != null
        ? DateFormat('MMM dd, HH:mm').format(DateTime.parse(item['created_at']))
        : '';

    return GlassCard(
      borderRadius: AppRadius.allLg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlassChip.status(
                label: contentType[0].toUpperCase() +
                    contentType.substring(1).toLowerCase(),
                color: AppColors.primary,
              ),
              const Spacer(),
              if (createdAt.isNotEmpty)
                Text(
                  createdAt,
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textHint),
                ),
            ],
          ),
          AppSpacing.gapMd,
          Text(
            reason,
            style: AppTextStyles.callout.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reported by $reportedBy',
            style: AppTextStyles.footnote
                .copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: GlassButton.outline(
                  label: 'Reject',
                  size: GlassButtonSize.small,
                  onPressed: () => ref
                      .read(moderationActionProvider.notifier)
                      .rejectItem(itemId),
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: GlassButton(
                  label: 'Approve',
                  size: GlassButtonSize.small,
                  onPressed: () => ref
                      .read(moderationActionProvider.notifier)
                      .approveItem(itemId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiLogsTab extends ConsumerWidget {
  const _AiLogsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(aiModerationLogsProvider);

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const GlassEmptyState(
            icon: AppIcons.chart_2,
            title: 'No AI moderation logs',
            message: 'Automated decisions will be listed here.',
            compact: true,
          );
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
          ),
          child: Column(
            children: [
              for (final log in logs)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: RepaintBoundary(child: _AiLogCard(log: log)),
                ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: GlassLoader(),
      ),
      error: (_, __) => GlassErrorState(
        compact: true,
        title: 'Failed to load AI logs',
        onRetry: () => ref.invalidate(aiModerationLogsProvider),
      ),
    );
  }
}

class _AiLogCard extends StatelessWidget {
  const _AiLogCard({required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    final flaggedReason = (log['flagged_reason'] ?? 'Unknown').toString();
    final confidence = (log['confidence_score'] as num?)?.toDouble() ?? 0.0;
    final actionTaken = (log['action_taken'] ?? 'none').toString();
    final contentType = (log['content_type'] ?? 'unknown').toString();
    final createdAt = log['created_at'] != null
        ? DateFormat('MMM dd, HH:mm').format(DateTime.parse(log['created_at']))
        : '';

    final color = confidence > 0.8
        ? AppColors.error
        : confidence > 0.5
            ? AppColors.warning
            : AppColors.success;

    return GlassCard(
      borderRadius: AppRadius.allLg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  flaggedReason,
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppSpacing.gapSm,
              GlassChip.status(label: contentType, color: color),
            ],
          ),
          AppSpacing.gapMd,
          // Confidence is what a moderator scans for, so it gets a full-width
          // bar with the value beside it rather than a cramped inline row.
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.pillAll,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: AppRadius.pillAll,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: confidence.clamp(0.0, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: AppRadius.pillAll,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.gapSm,
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Row(
            children: [
              Text(
                'Action: $actionTaken',
                style: AppTextStyles.footnote
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (createdAt.isNotEmpty)
                Text(
                  createdAt,
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textHint),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
