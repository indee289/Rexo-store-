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
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/jobs_provider.dart';
import 'job_detail_screen.dart';
import 'submit_task_screen.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Jobs',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _SegmentedTabBar(
            controller: _tabController,
            isDark: isDark,
          ),
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

// ─── Segmented Tab Bar ────────────────────────────────────────────────────────

class _SegmentedTabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;

  const _SegmentedTabBar({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        borderRadius: AppRadius.allMd,
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppRadius.allSm,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(3),
        tabs: const [
          Tab(text: 'Available Jobs'),
          Tab(text: 'My Jobs'),
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
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: PremiumTextField.search(
                controller: widget.searchController,
                hint: 'Search jobs…',
                onChanged: (val) =>
                    ref.read(jobSearchProvider.notifier).state = val,
              ),
            ),
          ),

          // Category filter chips
          SliverToBoxAdapter(
            child: categories.when(
              data: (cats) => _CategoryChips(
                categories: cats,
                selected: selectedCategory,
                onSelect: (cat) =>
                    ref.read(jobCategoryFilterProvider.notifier).state = cat,
              ),
              loading: () => const SizedBox(height: 36),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Jobs list
          jobs.when(
            data: (list) => list.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Iconsax.briefcase,
                      title: 'No jobs available',
                      subtitle: 'Check back soon — new jobs get posted regularly.',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _JobCard(
                            job: list[index],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailScreen(
                                    jobId: list[index]['id'] as String),
                              ),
                            ),
                          ),
                        ),
                        childCount: list.length,
                      ),
                    ),
                  ),
            loading: () => SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: ShimmerCard(height: 140),
                  ),
                  childCount: 5,
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Iconsax.warning_2,
                title: 'Something went wrong',
                subtitle: ErrorUtils.sanitize(e),
                cta: PremiumButton(
                  label: 'Retry',
                  icon: Iconsax.refresh,
                  variant: PremiumButtonVariant.tonal,
                  expand: false,
                  onPressed: () => ref.invalidate(availableJobsProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Filter Chips ────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected
                    ? null
                    : (isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt),
                borderRadius: AppRadius.allMd,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
              ),
            ),
          );
        },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    return PremiumCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image (optional)
          if (coverUrl != null && coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
              child: Image.network(
                coverUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + category badge row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (category != null && category.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _CategoryBadge(category: category),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Payment — most prominent number
                Row(
                  children: [
                    Icon(Iconsax.money,
                        size: 16, color: AppColors.accentOrange),
                    const SizedBox(width: 4),
                    Text(
                      '₹${_formatAmount(paymentAmount)}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentOrange,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Description preview
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                // Deadline + slots row
                if (deadline != null || hasSlotCap) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (deadline != null)
                        _MetaChip(
                          icon: Iconsax.calendar,
                          label:
                              'Due ${DateFormat('d MMM y').format(deadline)}',
                          isDark: isDark,
                        ),
                      if (hasSlotCap)
                        _MetaChip(
                          icon: Iconsax.people,
                          label: '$maxSlots slots',
                          isDark: isDark,
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

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: AppRadius.allSm,
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _MetaChip(
      {required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(myJobApplicationsProvider);
        await ref.read(myJobApplicationsProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Status filter bar
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                children: _statuses.map((s) {
                  final isActive = s.$1 == selected;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      onTap: () => ref
                          .read(myJobsStatusFilterProvider.notifier)
                          .state = s.$1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          gradient: isActive ? AppColors.primaryGradient : null,
                          color: isActive
                              ? null
                              : (isDark
                                  ? AppColors.darkSurfaceAlt
                                  : AppColors.surfaceAlt),
                          borderRadius: AppRadius.allSm,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          s.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

          apps.when(
            data: (list) => list.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Iconsax.briefcase,
                      title: 'No jobs here yet',
                      subtitle: selected == 'all'
                          ? 'Apply to a job from Available Jobs to get started.'
                          : 'You have no ${selected} jobs yet.',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _MyJobCard(application: list[index]),
                        ),
                        childCount: list.length,
                      ),
                    ),
                  ),
            loading: () => SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: ShimmerCard(height: 120),
                  ),
                  childCount: 4,
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Iconsax.warning_2,
                title: 'Something went wrong',
                subtitle: ErrorUtils.sanitize(e),
                cta: PremiumButton(
                  label: 'Retry',
                  icon: Iconsax.refresh,
                  variant: PremiumButtonVariant.tonal,
                  expand: false,
                  onPressed: () => ref.invalidate(myJobApplicationsProvider),
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final job = application['jobs'] as Map<String, dynamic>? ?? {};
    final title = job['title'] as String? ?? 'Untitled Job';
    final category = job['category'] as String?;
    final paymentAmount = (job['payment_amount'] as num?)?.toDouble() ?? 0.0;
    final status = application['status'] as String? ?? 'applied';
    final rejectionReason = application['rejection_reason'] as String?;
    final applicationId = application['id'] as String? ?? '';

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: AppRadius.allSm,
                ),
                child: const Icon(Iconsax.briefcase,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
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
                          fontSize: 11,
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
              _StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Payment
          Text(
            '₹${_formatAmount(paymentAmount)}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.accentOrange,
            ),
          ),

          // Rejection reason
          if (status == 'rejected' &&
              rejectionReason != null &&
              rejectionReason.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: AppRadius.allSm,
                border: Border.all(
                    color: AppColors.error.withOpacity(0.20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.info_circle,
                      size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rejectionReason,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Submit Task button for applied status
          if (status == 'applied') ...[
            const SizedBox(height: AppSpacing.md),
            PremiumButton(
              label: 'Submit Task',
              icon: Iconsax.document_upload,
              variant: PremiumButtonVariant.tonal,
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

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _configFor(status, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: AppRadius.allSm,
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: config.fg,
        ),
      ),
    );
  }

  _BadgeConfig _configFor(String status, bool isDark) {
    switch (status) {
      case 'applied':
        return _BadgeConfig(
          label: 'Applied',
          bg: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
          fg: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        );
      case 'submitted':
        return _BadgeConfig(
          label: 'Submitted',
          bg: AppColors.accentOrange.withOpacity(0.12),
          fg: AppColors.accentOrange,
        );
      case 'approved':
        return _BadgeConfig(
          label: 'Approved',
          bg: AppColors.success.withOpacity(0.12),
          fg: AppColors.success,
        );
      case 'rejected':
        return _BadgeConfig(
          label: 'Rejected',
          bg: AppColors.error.withOpacity(0.12),
          fg: AppColors.error,
        );
      default:
        return _BadgeConfig(
          label: status,
          bg: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
          fg: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color bg;
  final Color fg;
  const _BadgeConfig({required this.label, required this.bg, required this.fg});
}
