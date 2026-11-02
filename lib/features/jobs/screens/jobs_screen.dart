import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/jobs_provider.dart';
import 'job_detail_screen.dart';
import 'submit_task_screen.dart';

/// Jobs — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` whose `bottom` held a hand-built Material
/// `TabBar` with its own gradient indicator; two tabs of `PremiumCard`s; two
/// separate hand-rolled horizontal chip strips (one for categories, one for
/// statuses), each with its own selected/unselected gradient and shadow
/// logic; a bespoke `_StatusBadge` with a `_BadgeConfig` lookup table; and the
/// old `EmptyState` / `ShimmerCard` widgets. Every piece carried an `isDark`
/// branch.
///
/// New layout: both chip strips replaced by the shared `GlassChipRow`, the tab
/// bar by the shared segmented control, the status badge by
/// `GlassChip.status`, and the cards rebuilt so the payout — the number people
/// actually scan for — leads each row instead of being buried mid-card. The
/// `isDark` branches are gone: the app is light mode only.
///
/// One deliberate departure from the usual screen pattern: this screen keeps a
/// fixed [GlassAppBar] rather than the collapsing large title. The two tabs
/// own independently scrolling, lazily built lists with their own
/// pull-to-refresh, which a single shared [CustomScrollView] cannot host. The
/// alternative — an `IndexedStack` of non-scrolling tabs, as on the coupons
/// screen — would build every job card eagerly, and these lists are unbounded.
///
/// `availableJobsProvider`, `jobCategoriesProvider`, `jobCategoryFilterProvider`,
/// `jobSearchProvider`, `myJobsStatusFilterProvider`, `myJobApplicationsProvider`,
/// the row keys and both navigation targets are unchanged.
class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: 'Jobs',
        bottom: GlassTabBar(
          controller: _tabController,
          labels: const ['Available', 'My jobs'],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AvailableJobsTab(searchController: _searchController),
          const _MyJobsTab(),
        ],
      ),
    );
  }
}

// ─── Available Jobs Tab ───────────────────────────────────────────────────────

class _AvailableJobsTab extends ConsumerStatefulWidget {
  final TextEditingController searchController;

  const _AvailableJobsTab({required this.searchController});

  @override
  ConsumerState<_AvailableJobsTab> createState() => _AvailableJobsTabState();
}

class _AvailableJobsTabState extends ConsumerState<_AvailableJobsTab> {
  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(availableJobsProvider);
    final categories = ref.watch(jobCategoriesProvider);
    final selectedCategory = ref.watch(jobCategoryFilterProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(availableJobsProvider);
        ref.invalidate(jobCategoriesProvider);
        await ref.read(availableJobsProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: GlassTextField.search(
                controller: widget.searchController,
                hint: 'Search jobs…',
                onChanged: (val) =>
                    ref.read(jobSearchProvider.notifier).state = val,
              ),
            ),
          ),

          // Category filter.
          SliverToBoxAdapter(
            child: categories.when(
              data: (cats) {
                if (cats.isEmpty) return const SizedBox.shrink();
                final index = cats.indexOf(selectedCategory);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: GlassChipRow(
                    labels: cats,
                    selectedIndex: index < 0 ? 0 : index,
                    onSelected: (i) => ref
                        .read(jobCategoryFilterProvider.notifier)
                        .state = cats[i],
                  ),
                );
              },
              loading: () => const SizedBox(height: 36),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          jobs.when(
            data: (list) => list.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.briefcase,
                      title: 'No jobs available',
                      message:
                          'Check back soon — new jobs get posted regularly.',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => AppSpacing.gapMd,
                      itemBuilder: (context, index) => RepaintBoundary(
                        child: _JobCard(
                          job: list[index],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(
                                jobId: list[index]['id'] as String,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
              child: _JobSkeletonList(count: 5),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: GlassErrorState(
                message: ErrorUtils.sanitize(e),
                onRetry: () => ref.invalidate(availableJobsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Job Card ─────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = job['title'] as String? ?? 'Untitled Job';
    final category = job['category'] as String?;
    final description = job['description'] as String? ?? '';
    final paymentAmount = (job['payment_amount'] as num?)?.toDouble() ?? 0.0;
    final maxSlots = job['max_slots'] as int?;
    final deadline = job['deadline'] != null
        ? DateTime.tryParse(job['deadline'].toString())
        : null;
    final coverUrl = job['cover_image_url'] as String?;

    // Slot display: we show approximate data from the job row only.
    // Exact slot count is loaded on the detail screen.
    final bool hasSlotCap = maxSlots != null;

    return GlassCard.bare(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
              child: CachedImage(
                imageUrl: coverUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The payout leads: it is what people scan a job list for.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '\u20B9${_formatAmount(paymentAmount)}',
                        style: AppTextStyles.title1.copyWith(
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (category != null && category.isNotEmpty)
                      GlassChip.status(
                        label: category,
                        color: AppColors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline
                      .copyWith(color: AppColors.textPrimary),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                if (deadline != null || hasSlotCap) ...[
                  AppSpacing.gapMd,
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (deadline != null)
                        _MetaItem(
                          icon: AppIcons.calendar,
                          label:
                              'Due ${DateFormat('d MMM y').format(deadline)}',
                        ),
                      if (hasSlotCap)
                        _MetaItem(
                          icon: AppIcons.people,
                          label: '$maxSlots slots',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return NumberFormat('#,##0').format(amount);
    }
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
}

/// Small icon-plus-label metadata pair used on the job cards.
class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption1.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── My Jobs Tab ──────────────────────────────────────────────────────────────

class _MyJobsTab extends ConsumerWidget {
  const _MyJobsTab();

  static const _statuses = [
    ('all', 'All'),
    ('applied', 'Applied'),
    ('submitted', 'Submitted'),
    ('approved', 'Approved'),
    ('rejected', 'Rejected'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(myJobsStatusFilterProvider);
    final apps = ref.watch(myJobApplicationsProvider);

    final selectedIndex = _statuses.indexWhere((s) => s.$1 == selected);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(myJobApplicationsProvider);
        await ref.read(myJobApplicationsProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                AppSpacing.md,
                0,
                AppSpacing.md,
              ),
              child: GlassChipRow(
                labels: _statuses.map((s) => s.$2).toList(growable: false),
                selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                onSelected: (i) => ref
                    .read(myJobsStatusFilterProvider.notifier)
                    .state = _statuses[i].$1,
              ),
            ),
          ),

          apps.when(
            data: (list) => list.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.briefcase,
                      title: 'No jobs here yet',
                      message: selected == 'all'
                          ? 'Apply to a job from Available to get started.'
                          : 'You have no $selected jobs yet.',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => AppSpacing.gapMd,
                      itemBuilder: (context, index) => RepaintBoundary(
                        child: _MyJobCard(application: list[index]),
                      ),
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
              child: _JobSkeletonList(count: 4),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: GlassErrorState(
                message: ErrorUtils.sanitize(e),
                onRetry: () => ref.invalidate(myJobApplicationsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My Job Card ──────────────────────────────────────────────────────────────

class _MyJobCard extends StatelessWidget {
  final Map<String, dynamic> application;

  const _MyJobCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final job = application['jobs'] as Map<String, dynamic>? ?? {};
    final title = job['title'] as String? ?? 'Untitled Job';
    final category = job['category'] as String?;
    final paymentAmount = (job['payment_amount'] as num?)?.toDouble() ?? 0.0;
    final status = application['status'] as String? ?? 'applied';
    final rejectionReason = application['rejection_reason'] as String?;
    final applicationId = application['id'] as String? ?? '';

    final showReason = status == 'rejected' &&
        rejectionReason != null &&
        rejectionReason.trim().isNotEmpty;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GlassIconBubble(icon: AppIcons.briefcase),
              AppSpacing.gapMd,
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
                    const SizedBox(height: 2),
                    Text(
                      '\u20B9${_formatAmount(paymentAmount)}'
                      '${category != null && category.isNotEmpty ? ' · $category' : ''}',
                      style: AppTextStyles.subheadline.copyWith(
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

          if (showReason) ...[
            AppSpacing.gapMd,
            GlassCard(
              level: GlassLevel.subtle,
              rim: AppColors.error.withOpacity(0.25),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    AppIcons.info_circle,
                    size: 15,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rejectionReason,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.error,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (status == 'applied') ...[
            AppSpacing.gapMd,
            GlassButton.glass(
              label: 'Submit task',
              icon: AppIcons.document_upload,
              size: GlassButtonSize.small,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubmitTaskScreen(
                    applicationId: applicationId,
                    jobTitle: title,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return NumberFormat('#,##0').format(amount);
    }
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
}

/// Status label / colour pairing, replacing the old `_BadgeConfig` table.
String _statusLabel(String status) {
  switch (status) {
    case 'applied':
      return 'Applied';
    case 'submitted':
      return 'Submitted';
    case 'approved':
      return 'Approved';
    case 'rejected':
      return 'Rejected';
    default:
      return status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'submitted':
      return AppColors.accentOrange;
    case 'approved':
      return AppColors.success;
    case 'rejected':
      return AppColors.error;
    case 'applied':
    default:
      return AppColors.textSecondary;
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _JobSkeletonList extends StatelessWidget {
  final int count;

  const _JobSkeletonList({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          for (int i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    GlassSkeleton(width: 110, height: 24),
                    SizedBox(height: 10),
                    GlassSkeleton(height: 15),
                    SizedBox(height: 8),
                    GlassSkeleton(width: 180, height: 12),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
