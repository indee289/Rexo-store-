import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/campaign_cover_header.dart';
import '../../../core/widgets/demo_asset_view.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../reports/providers/report_provider.dart';
import '../providers/campaigns_provider.dart';

/// Campaign detail — rebuilt layout.
///
/// Old layout: a flat `ListView` under a fixed 200px cover, in which the stat
/// tiles, tag chips, info banners and every prose section were each a bespoke
/// `Container` + `BoxDecoration`, the four prose blocks repeated the same
/// heading-plus-boxed-text shape by hand, and the sticky Apply bar was built
/// from a `GestureDetector` wrapping a manually drawn pill.
///
/// New layout: the cover becomes a collapsing [GlassSliverAppBar], so the
/// title and status travel into a compact bar as you scroll instead of the
/// image simply sliding away; the three numbers become a row of stat pills;
/// the loose targeting facts (deadline, audience, page category, minimum
/// followers) collect into one grouped "Details" section instead of being
/// scattered between banners and inline rows; the prose sections share one
/// card treatment; and the Apply bar is rebuilt on `GlassButton`.
///
/// `campaignDetailProvider`, `hasAppliedProvider`, every camelCase/snake_case
/// field fallback, the apply and report routes and the closed/full rules are
/// unchanged.
class CampaignDetailScreen extends ConsumerWidget {
  final String campaignId;
  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignDetailProvider(campaignId));
    final hasApplied = ref.watch(hasAppliedProvider(campaignId));

    return GlassScaffold(
      padBodyForAppBar: false,
      // The cover is full-bleed media; ambient blobs would fight it.
      showBlobs: false,
      body: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) return _NotFound(onBack: () => context.pop());
          return _DetailBody(campaign: campaign, hasApplied: hasApplied);
        },
        loading: () => const _Loading(),
        error: (e, _) => _Error(
          message: ErrorUtils.sanitize(e),
          onRetry: () => ref.invalidate(campaignDetailProvider(campaignId)),
        ),
      ),
      // Sticky Apply bar at the very bottom — never scrolls.
      bottomNavigationBar: campaignAsync.whenOrNull(
        data: (campaign) {
          if (campaign == null) return null;
          final status = _str(campaign, 'status').toLowerCase();
          final isClosed = status == 'closed' || status == 'inactive';
          final filled = _int(campaign, 'filled_slots') ?? 0;
          final total = _int(campaign, 'slots');
          final isFull = total != null && total > 0 && filled >= total;
          return CampaignDetailBottomBar(
            campaignId: campaignId,
            isClosed: isClosed,
            isFull: isFull,
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DETAIL BODY — the main scrollable content
// ═══════════════════════════════════════════════════════════════════════════════

class _DetailBody extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final AsyncValue<bool> hasApplied;

  const _DetailBody({required this.campaign, required this.hasApplied});

  @override
  Widget build(BuildContext context) {
    // ── Extract ALL fields with camelCase + snake_case fallbacks ──
    final title = _str(campaign, 'title', fallback: 'Untitled Campaign');
    final coverImage = _str(campaign, 'cover_image',
        fallback: _str(campaign, 'coverImage',
            fallback: _str(campaign, 'bannerUrl')));
    final description = _str(campaign, 'description');
    final status = _str(campaign, 'status');
    final category = _str(campaign, 'category');
    final platform = _str(campaign, 'platform');
    final brandName = _str(campaign, 'brandName',
        fallback: _str(campaign, 'companyName',
            fallback: _str(campaign, 'company_name',
                fallback:
                    (campaign['users'] as Map?)?['name']?.toString() ?? '')));
    final brandAvatar = (campaign['users'] as Map?)?['profileImage'] as String?;
    final budget =
        campaign['budget'] ?? campaign['totalBudget'] ?? campaign['total_budget'];
    final perCreator =
        campaign['payout_per_creator'] ?? campaign['payoutPerCreator'];
    final slots = _int(campaign, 'slots');
    final filledSlots = _int(campaign, 'filled_slots') ?? 0;
    final deadline = _str(campaign, 'deadline');
    final requirements = _str(campaign, 'requirements');
    final deliverables = _str(campaign, 'deliverables');
    final rules = _str(campaign, 'rules');
    final demoType = _str(campaign, 'demo_asset_type');
    final demoUrl = _str(campaign, 'demo_asset_url');
    final gender = _str(campaign, 'gender',
        fallback: _str(campaign, 'targetGender',
            fallback: _str(campaign, 'target_gender')));
    final minFollowers = _int(campaign, 'min_followers');
    final pageCategory = _str(campaign, 'pageProfileCategory',
        fallback: _str(campaign, 'page_profile_category'));
    final createdAt = DateTime.tryParse(
        _str(campaign, 'createdAt', fallback: _str(campaign, 'created_at')));
    final deadlineDate =
        deadline.isNotEmpty ? DateTime.tryParse(deadline) : null;

    // Platforms split
    final platforms = platform.isNotEmpty
        ? platform
            .split(',')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList()
        : <String>[];

    // The loose targeting facts, gathered into one grouped section.
    final detailRows = <Widget>[
      if (deadlineDate != null)
        GlassRow(
          icon: AppIcons.calendar,
          title: 'Deadline',
          trailingText: DateFormat('d MMM yyyy').format(deadlineDate),
          showChevron: false,
        ),
      if (deadlineDate == null && createdAt != null)
        GlassRow(
          icon: AppIcons.calendar,
          title: 'Started',
          trailingText: DateFormat('d MMM').format(createdAt),
          showChevron: false,
        ),
      if (gender.isNotEmpty)
        GlassRow(
          icon: AppIcons.user,
          title: 'Audience',
          trailingText: gender,
          showChevron: false,
        ),
      if (pageCategory.isNotEmpty)
        GlassRow(
          icon: AppIcons.tag,
          title: 'Page category',
          trailingText: pageCategory,
          showChevron: false,
        ),
      if (minFollowers != null && minFollowers > 0)
        GlassRow(
          icon: AppIcons.people,
          title: 'Minimum followers',
          iconColor: AppColors.warning,
          trailingText: NumberFormat.compact().format(minFollowers),
          showChevron: false,
        ),
    ];

    return CustomScrollView(
      slivers: [
        GlassSliverAppBar(
          title: title,
          showBack: true,
          onBack: () => context.pop(),
          expandedHeight: 240,
          actions: [
            if (status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: GlassChip.status(
                  label: _statusLabel(status),
                  color: _statusColor(status),
                ),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: CampaignCoverHeader(
              coverImageUrl: coverImage,
              height: 240,
              overlay: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Already-applied notice, first because it changes what you can do.
        if (hasApplied.valueOrNull == true)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: _Banner(
                icon: AppIcons.tick_circle,
                text: 'You have already applied to this campaign',
                color: AppColors.success,
              ),
            ),
          ),

        // Title, brand, numbers and tags.
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
                if (brandName.isNotEmpty) ...[
                  AppSpacing.gapMd,
                  Row(
                    children: [
                      PremiumAvatar(
                        imageUrl: brandAvatar,
                        name: brandName,
                        size: 36,
                      ),
                      AppSpacing.gapSm,
                      Expanded(
                        child: Text(
                          brandName,
                          style: AppTextStyles.headline
                              .copyWith(color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // The money and the slots, as pills.
                if (perCreator != null || slots != null || budget != null) ...[
                  AppSpacing.gapLg,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (perCreator != null)
                        Expanded(
                          child: GlassStatPill(
                            value: '\u20B9${_fmtNum(perCreator)}',
                            label: 'Per creator',
                            icon: AppIcons.wallet,
                            accent: AppColors.primary,
                          ),
                        ),
                      if (perCreator != null && slots != null)
                        AppSpacing.gapSm,
                      if (slots != null)
                        Expanded(
                          child: GlassStatPill(
                            value: '$filledSlots / $slots',
                            label: 'Slots',
                            icon: AppIcons.people,
                          ),
                        ),
                      if (budget != null &&
                          (perCreator != null || slots != null))
                        AppSpacing.gapSm,
                      if (budget != null)
                        Expanded(
                          child: GlassStatPill(
                            value: '\u20B9${_fmtNum(budget)}',
                            label: 'Total budget',
                            icon: AppIcons.chart_2,
                            accent: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ],

                if (platforms.isNotEmpty || category.isNotEmpty) ...[
                  AppSpacing.gapLg,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final p in platforms)
                        GlassChip(label: p, dense: true),
                      if (category.isNotEmpty)
                        GlassChip(label: category, dense: true),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Grouped targeting facts.
        if (detailRows.isNotEmpty)
          SliverToBoxAdapter(
            child: GlassSection(title: 'Details', children: detailRows),
          ),

        // Prose sections, all sharing one treatment.
        if (description.isNotEmpty)
          SliverToBoxAdapter(
            child: _ProseSection(
              title: 'About this campaign',
              body: description,
            ),
          ),
        if (requirements.isNotEmpty)
          SliverToBoxAdapter(
            child: _ProseSection(title: 'Requirements', body: requirements),
          ),
        if (deliverables.isNotEmpty)
          SliverToBoxAdapter(
            child: _ProseSection(title: 'Deliverables', body: deliverables),
          ),
        if (rules.isNotEmpty)
          SliverToBoxAdapter(
            child: _ProseSection(title: 'Rules', body: rules),
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

        SliverToBoxAdapter(
          child: Center(
            child: GlassButton.ghost(
              label: 'Report this campaign',
              icon: AppIcons.flag,
              size: GlassButtonSize.small,
              onPressed: () => context.push('/report', extra: {
                'targetType': ReportTargetType.campaign,
                'targetId': (campaign['id'] ?? '').toString(),
                'targetLabel': title,
              }),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
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

Color _statusColor(String s) {
  final lower = s.toLowerCase();
  if (lower == 'active' || lower == 'open') return AppColors.success;
  if (lower == 'closed' || lower == 'inactive') return AppColors.neutral;
  return AppColors.primary;
}

String _statusLabel(String s) {
  if (s.isEmpty) return '';
  return s[0].toUpperCase() + s.substring(1);
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROSE SECTION — heading over a body card
// ═══════════════════════════════════════════════════════════════════════════════

class _ProseSection extends StatelessWidget {
  final String title;
  final String body;

  const _ProseSection({required this.title, required this.body});

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
          _sectionLabel(title),
          GlassCard(
            child: Text(
              body,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BANNER — tinted notice with an icon
// ═══════════════════════════════════════════════════════════════════════════════

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      rim: color.withOpacity(0.30),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          AppSpacing.gapMd,
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.subheadline.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM BAR — sticky Apply Now
// ═══════════════════════════════════════════════════════════════════════════════

class CampaignDetailBottomBar extends ConsumerWidget {
  final String campaignId;
  final bool isClosed;
  final bool isFull;

  const CampaignDetailBottomBar({
    super.key,
    required this.campaignId,
    this.isClosed = false,
    this.isFull = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasApplied = ref.watch(hasAppliedProvider(campaignId));

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
        child: _buildButton(context, hasApplied),
      ),
    );
  }

  Widget _buildButton(BuildContext context, AsyncValue<bool> hasApplied) {
    if (isClosed) {
      return const _StatusBtn(label: 'Closed', color: AppColors.neutral);
    }
    if (isFull) {
      return const _StatusBtn(label: 'Slots full', color: AppColors.error);
    }
    return hasApplied.when(
      data: (applied) {
        if (applied) {
          return const _StatusBtn(
            label: 'Already applied',
            color: AppColors.success,
          );
        }
        return _applyButton(context);
      },
      loading: () => const GlassButton(
        label: 'Apply now',
        loading: true,
        size: GlassButtonSize.large,
        onPressed: null,
      ),
      error: (_, __) => _applyButton(context),
    );
  }

  Widget _applyButton(BuildContext context) {
    return GlassButton(
      label: 'Apply now',
      trailingIcon: AppIcons.arrow_right_3,
      size: GlassButtonSize.large,
      onPressed: () => context.push('/campaigns/$campaignId/apply'),
    );
  }
}

/// Non-actionable state in the Apply slot — closed, full, already applied.
class _StatusBtn extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBtn({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOADING / ERROR / NOT FOUND
// ═══════════════════════════════════════════════════════════════════════════════

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
              title: 'Failed to load campaign',
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
  final VoidCallback onBack;
  const _NotFound({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          const Center(
            child: GlassEmptyState(
              icon: AppIcons.document,
              title: 'Campaign not found',
              message: 'This campaign may have been removed.',
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: _BackButton(onBack: onBack),
          ),
        ],
      ),
    );
  }
}

/// Back affordance for the states that render without the sliver app bar.
class _BackButton extends StatelessWidget {
  final VoidCallback? onBack;
  const _BackButton({this.onBack});

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      icon: AppIcons.arrow_left,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      size: 36,
      iconSize: 19,
      onTap: onBack ?? () => Navigator.of(context).maybePop(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Safe string extraction with multiple key fallbacks.
String _str(Map<String, dynamic> m, String key, {String fallback = ''}) {
  final v = m[key];
  if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
  return fallback;
}

/// Safe int extraction.
int? _int(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// Format a number with Indian grouping.
String _fmtNum(dynamic v) {
  final d = double.tryParse(v.toString()) ?? 0;
  try {
    return NumberFormat('#,##0', 'en_IN').format(d);
  } catch (_) {
    return d.toStringAsFixed(0);
  }
}
