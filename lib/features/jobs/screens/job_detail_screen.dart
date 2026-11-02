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
import '../../../core/widgets/demo_asset_view.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/jobs_provider.dart';

/// Job detail — rebuilt layout.
///
/// Old layout: a `Scaffold` nested inside another `Scaffold` purely so the
/// Apply bar could see the loaded job; a fixed 200px cover carrying a
/// hand-built overlay row (back chevron, centred title, bookmark) plus a
/// second absolutely-positioned status pill; and then payment, details,
/// "what to submit" and rules each rendered as its own `Container` +
/// `BoxDecoration`, with the details rows separated by `Divider`s. The Apply
/// bar's three states and its CTA were three more hand-drawn pills. Every
/// piece threaded `isDark`, `cardColor`, `borderColor`, `textPrimary` and
/// `textSecondary` down through its constructor.
///
/// New layout: one scaffold, with the Apply bar resolved from the same async
/// value at the top level; the cover promoted to a collapsing
/// [GlassSliverAppBar], so the title and the save action survive into a
/// compact bar instead of scrolling away; the status, category and platforms
/// unified into one chip row rather than a pill on the image plus pills in the
/// body; the details rows moved into a grouped section, which removes the last
/// `Divider`s on this screen; and the Apply bar rebuilt on `GlassButton`. All
/// the colour-threading constructor parameters are gone — the components read
/// the tokens directly, and the app is light mode only.
///
/// `jobDetailProvider`, `hasAppliedToJobProvider`, `jobSlotCountProvider`,
/// `savedJobsProvider`, `jobsActionsProvider.applyToJob`, the row keys and the
/// full/closed/applied rules are unchanged.
class JobDetailScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final hasApplied = ref.watch(hasAppliedToJobProvider(jobId));
    final slotData = ref.watch(jobSlotCountProvider(jobId));

    final slotFilled = (slotData.value?['filled'] as int?) ?? 0;
    final hasAppliedVal = hasApplied.value ?? false;

    return GlassScaffold(
      padBodyForAppBar: false,
      // The cover is full-bleed media; ambient blobs would fight it.
      showBlobs: false,
      body: jobAsync.when(
        data: (job) {
          if (job == null) return const _NotFound();
          return _JobDetailScrollView(
            job: job,
            jobId: jobId,
            slotFilled: slotFilled,
          );
        },
        loading: () => const _Loading(),
        error: (e, _) => _Error(
          message: ErrorUtils.sanitize(e),
          onRetry: () => ref.invalidate(jobDetailProvider(jobId)),
        ),
      ),
      // Resolved here rather than from a second nested Scaffold.
      bottomNavigationBar: jobAsync.whenOrNull(
        data: (job) {
          if (job == null) return null;
          final maxSlots = job['max_slots'] as int?;
          final isFull = maxSlots != null && slotFilled >= maxSlots;
          final isClosed = (job['status'] as String? ?? '') == 'closed';
          return _ApplyBar(
            jobId: jobId,
            hasApplied: hasAppliedVal,
            isFull: isFull,
            isClosed: isClosed,
          );
        },
      ),
    );
  }
}

// ─── Scrollable Body ──────────────────────────────────────────────────────────

class _JobDetailScrollView extends StatelessWidget {
  final Map<String, dynamic> job;
  final String jobId;
  final int slotFilled;

  const _JobDetailScrollView({
    required this.job,
    required this.jobId,
    required this.slotFilled,
  });

  @override
  Widget build(BuildContext context) {
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

    // Slots value string.
    late final String slotsValue;
    Color? slotsColor;
    if (maxSlots == null) {
      slotsValue = 'Unlimited';
    } else if (isFull) {
      slotsValue = 'Slots full';
      slotsColor = AppColors.error;
    } else {
      slotsValue = '${maxSlots - slotFilled} of $maxSlots left';
    }

    return CustomScrollView(
      slivers: [
        GlassSliverAppBar(
          title: 'Job details',
          showBack: true,
          expandedHeight: 240,
          actions: [_SaveButton(jobId: jobId)],
          flexibleSpace: FlexibleSpaceBar(
            background: _CoverBackground(coverUrl: coverUrl),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.title1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                // Status, category and platforms in one row, instead of a pill
                // on the cover plus a separate strip in the body.
                AppSpacing.gapMd,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    GlassChip.status(
                      label: isActive ? 'Active' : 'Closed',
                      color: isActive ? AppColors.success : AppColors.neutral,
                    ),
                    if (category != null && category.isNotEmpty)
                      GlassChip(
                        label: category,
                        icon: AppIcons.category,
                        dense: true,
                      ),
                    for (final p in platforms)
                      GlassChip(
                        label: p,
                        icon: _platformIcon(p),
                        dense: true,
                      ),
                  ],
                ),

                AppSpacing.gapLg,
                _PaymentCard(amount: paymentAmount),
              ],
            ),
          ),
        ),

        // Details, grouped — this is what removed the Dividers.
        SliverToBoxAdapter(
          child: GlassSection(
            title: 'Details',
            children: [
              if (deadline != null)
                GlassRow(
                  icon: AppIcons.calendar,
                  title: 'Deadline',
                  trailingText: DateFormat('d MMM y').format(deadline),
                  showChevron: false,
                ),
              GlassRow(
                icon: AppIcons.people,
                title: 'Slots',
                iconColor: slotsColor,
                trailingText: slotsValue,
                showChevron: false,
              ),
              if (createdAt != null)
                GlassRow(
                  icon: AppIcons.clock,
                  title: 'Posted',
                  trailingText: _relativeTime(createdAt),
                  showChevron: false,
                ),
            ],
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel('Description & instructions'),
                GlassCard(
                  child: _ExpandableText(
                    text: description.isEmpty
                        ? 'No description provided.'
                        : description,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: _WhatToSubmitCard()),

        if (rules.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('Rules'),
                  GlassCard(
                    child: Text(
                      rules,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (demoType.isNotEmpty && demoUrl.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('Demo asset'),
                  DemoAssetView(type: demoType, value: demoUrl),
                ],
              ),
            ),
          ),

        // Clearance so content never hides under the sticky Apply bar.
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
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

IconData _platformIcon(String platform) {
  final p = platform.toLowerCase();
  if (p.contains('insta')) return AppIcons.instagram;
  if (p.contains('face')) return AppIcons.facebook;
  if (p.contains('you')) return AppIcons.youtube;
  return AppIcons.global;
}

/// Group heading matching the tracked-caps header used by `GlassSection`.
Widget _sectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.xs,
      AppSpacing.md,
    ),
    child: Text(
      text.toUpperCase(),
      style: AppTextStyles.caption1.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}

// ─── Cover ────────────────────────────────────────────────────────────────────

/// Cover artwork behind the collapsing bar, or a branded placeholder.
class _CoverBackground extends StatelessWidget {
  final String? coverUrl;

  const _CoverBackground({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasCover)
            CachedImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_) => const SizedBox.shrink(),
            )
          else
            const Center(
              child: Icon(
                AppIcons.briefcase,
                size: 56,
                color: Colors.white70,
              ),
            ),
          // Scrim so the bar's controls stay legible over any artwork.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bookmark toggle for the collapsing bar.
class _SaveButton extends ConsumerWidget {
  final String jobId;

  const _SaveButton({required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedJobsProvider);
    final isSaved = saved.contains(jobId);

    return GlassIconButton(
      icon: isSaved ? AppIcons.bookmark : AppIcons.save_2,
      tooltip: isSaved ? 'Saved' : 'Save',
      color: isSaved ? AppColors.primary : null,
      size: 36,
      iconSize: 19,
      onTap: () {
        ref.read(savedJobsProvider.notifier).update((s) {
          final next = Set<String>.from(s);
          if (isSaved) {
            next.remove(jobId);
          } else {
            next.add(jobId);
          }
          return next;
        });
      },
    );
  }
}

// ─── Payment Card ─────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final double amount;

  const _PaymentCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return GlassCard.brand(
      child: Row(
        children: [
          const GlassIconBubble(
            icon: AppIcons.wallet,
            size: 48,
            iconSize: 24,
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Payment',
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  '\u20B9${_formatAmount(amount)}',
                  style: AppTextStyles.title1.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Per approved submission',
                  style: AppTextStyles.caption1
                      .copyWith(color: AppColors.textSecondary),
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
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }
}

// ─── Expandable Description ───────────────────────────────────────────────────

class _ExpandableText extends StatefulWidget {
  final String text;

  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  static const int _collapsedLines = 4;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body.copyWith(
      color: AppColors.textSecondary,
      height: 1.6,
    );

    return LayoutBuilder(
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
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (overflows) ...[
              AppSpacing.gapSm,
              GlassButton.ghost(
                label: _expanded ? 'Read less' : 'Read more',
                size: GlassButtonSize.small,
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── What To Submit Card ──────────────────────────────────────────────────────

class _WhatToSubmitCard extends StatelessWidget {
  const _WhatToSubmitCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('What to submit'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit your work in any of these formats:',
                  style: AppTextStyles.footnote
                      .copyWith(color: AppColors.textSecondary),
                ),
                AppSpacing.gapMd,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: const [
                    GlassChip(
                      label: 'Link',
                      icon: AppIcons.link,
                      dense: true,
                    ),
                    GlassChip(
                      label: 'Photo',
                      icon: AppIcons.gallery,
                      dense: true,
                    ),
                    GlassChip(
                      label: 'PDF',
                      icon: AppIcons.document,
                      dense: true,
                    ),
                    GlassChip(
                      label: 'Video',
                      icon: AppIcons.video,
                      dense: true,
                    ),
                  ],
                ),
              ],
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
  final bool hasApplied;
  final bool isFull;
  final bool isClosed;

  const _ApplyBar({
    required this.jobId,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md + MediaQuery.of(context).padding.bottom,
        ),
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    // Already applied — settled green state.
    if (widget.hasApplied) {
      return const _StatusButton(
        label: 'Already applied',
        icon: AppIcons.tick_circle,
        color: AppColors.success,
      );
    }
    // Slots full — blocked red state.
    if (widget.isFull) {
      return const _StatusButton(
        label: 'Slots full',
        icon: AppIcons.slash,
        color: AppColors.error,
      );
    }
    // Closed — blocked neutral state.
    if (widget.isClosed) {
      return const _StatusButton(
        label: 'Closed',
        icon: AppIcons.slash,
        color: AppColors.neutral,
      );
    }
    // Active — show the Apply action.
    return GlassButton(
      label: 'Apply now',
      icon: AppIcons.send_1,
      size: GlassButtonSize.large,
      loading: _applying,
      onPressed: _applying ? null : _apply,
    );
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    final ok =
        await ref.read(jobsActionsProvider.notifier).applyToJob(widget.jobId);
    if (!mounted) return;
    setState(() => _applying = false);

    if (ok) {
      showGlassSnackBar(
        context,
        message: 'Application submitted successfully!',
        tone: GlassToastTone.success,
      );
      Navigator.of(context).pop();
    } else {
      final error = ref.read(jobsActionsProvider);
      showGlassSnackBar(
        context,
        message: error.hasError
            ? ErrorUtils.sanitize(error.error)
            : 'Could not apply. Please try again.',
        tone: GlassToastTone.error,
      );
    }
  }
}

/// Non-actionable state in the Apply slot — applied, full or closed.
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
      height: 52,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          AppSpacing.gapSm,
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading / Error / Not found ──────────────────────────────────────────────

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassSkeleton(height: 200, borderRadius: AppRadius.allLg),
            SizedBox(height: AppSpacing.lg),
            GlassSkeleton(width: 220, height: 24),
            SizedBox(height: AppSpacing.md),
            GlassSkeleton(height: 15),
            SizedBox(height: AppSpacing.sm),
            GlassSkeleton(width: 160, height: 15),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _Error({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: GlassErrorState(
              title: 'Failed to load job',
              message: message,
              onRetry: onRetry,
            ),
          ),
          const Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: _BackButton(),
          ),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Stack(
        children: [
          Center(
            child: GlassEmptyState(
              icon: AppIcons.briefcase,
              title: 'Job not found',
              message: 'This job may have been removed.',
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: _BackButton(),
          ),
        ],
      ),
    );
  }
}

/// Back affordance for the states that render without the sliver app bar.
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      icon: AppIcons.arrow_left,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      size: 36,
      iconSize: 19,
      onTap: () => Navigator.of(context).maybePop(),
    );
  }
}
