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
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/campaigns_provider.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final String campaignId;

  const CampaignDetailScreen({
    super.key,
    required this.campaignId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignDetailProvider(campaignId));
    final hasApplied = ref.watch(hasAppliedProvider(campaignId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) return _buildNotFound(context);
          return _CampaignDetailScrollView(
            campaign: campaign,
            hasApplied: hasApplied.valueOrNull == true,
          );
        },
        loading: () => _buildLoading(),
        error: (error, _) =>
            _buildError(context, ref, ErrorUtils.sanitize(error)),
      ),
      bottomNavigationBar: campaignAsync.whenOrNull(
        data: (campaign) {
          if (campaign == null) return null;
          // Gate the sticky Apply CTA on the campaign's status/slot state,
          // mirroring the Job Details screen's _ApplyBar. A Closed/inactive
          // campaign must not present a live "Apply Now".
          final status = (campaign['status'] as String? ?? '').toLowerCase();
          final isClosed = status == 'closed' || status == 'inactive';
          final filled = _asInt(campaign['filled_slots']) ?? 0;
          final total = _asInt(campaign['total_slots']);
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

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  Widget _buildNotFound(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: PremiumIconButton(
                icon: Iconsax.arrow_left,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
            ),
          ),
          EmptyState(
            icon: Iconsax.document,
            title: 'Campaign not found',
            subtitle: 'This campaign may have been removed.',
            cta: PremiumButton(
              label: 'Go Back',
              icon: Iconsax.arrow_left,
              expand: false,
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerCard(height: 200),
            SizedBox(height: AppSpacing.lg),
            ShimmerLine(width: 200, height: 20),
            SizedBox(height: AppSpacing.md),
            ShimmerLine(height: 14),
            SizedBox(height: AppSpacing.sm),
            ShimmerLine(width: 150, height: 14),
            SizedBox(height: AppSpacing.xl),
            ShimmerCard(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: PremiumIconButton(
                icon: Iconsax.arrow_left,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
            ),
          ),
          EmptyState(
            icon: Iconsax.warning_2,
            title: 'Failed to load campaign',
            subtitle: error,
            cta: PremiumButton(
              label: 'Retry',
              icon: Iconsax.refresh,
              variant: PremiumButtonVariant.tonal,
              expand: false,
              onPressed: () =>
                  ref.invalidate(campaignDetailProvider(campaignId)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scrollable Body ──────────────────────────────────────────────────────────

class _CampaignDetailScrollView extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final bool hasApplied;

  const _CampaignDetailScrollView({
    required this.campaign,
    required this.hasApplied,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Read the EXACT keys the screen already reads (unchanged). ──
    final title = (campaign['title'] ?? 'Untitled Campaign').toString();
    final coverImageUrl = (campaign['cover_image_url'] ?? '').toString();
    final description = (campaign['description'] ?? '').toString();
    final budget = campaign['budget'];
    final platform = (campaign['platform'] ?? '').toString();
    final category = (campaign['category'] ?? '').toString();
    final deadline = campaign['deadline'] as String?;
    final guidelines = (campaign['guidelines'] ?? '').toString();
    final minFollowers = campaign['min_followers'];
    final filledSlots = campaign['filled_slots'];
    final totalSlots = campaign['total_slots'];
    final brandInfo = campaign['users'] as Map<String, dynamic>?;
    final brandName = (brandInfo?['name'] ?? 'Unknown Brand').toString();
    final brandAvatar = brandInfo?['avatar_url'] as String?;

    // Optional keys — render ONLY when present on the map (do not invent DB
    // columns). These render conditionally per the spec.
    final status = (campaign['status'] ?? '').toString();
    final gender = (campaign['gender'] ?? '').toString();
    final location = (campaign['location'] ?? '').toString();
    final hashtags = _hashtagsFrom(campaign['hashtags']);
    final createdAt = campaign['created_at'] != null
        ? DateTime.tryParse(campaign['created_at'].toString())
        : null;
    final deadlineDate =
        deadline != null ? DateTime.tryParse(deadline) : null;

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    // ── Brand subtitle (muted category tags) ──
    final subtitleParts = <String>[
      if (category.isNotEmpty) category,
      if (platform.isNotEmpty) platform,
    ];
    final brandSubtitle =
        subtitleParts.isEmpty ? 'Brand' : subtitleParts.join(' • ');

    // ── Stat card values ──
    final budgetValue =
        budget != null ? '₹${_formatAmount(budget)}' : null;
    final int? filled = filledSlots is int
        ? filledSlots
        : (filledSlots is num ? filledSlots.toInt() : null);
    final int? total = totalSlots is int
        ? totalSlots
        : (totalSlots is num ? totalSlots.toInt() : null);
    final slotsValue = (total != null && total > 0)
        ? '${filled ?? 0}/$total'
        : null;

    // ── Details rows (only rows that have data) ──
    final detailRows = <_DetailRowData>[];
    if (deadlineDate != null || createdAt != null) {
      final start = createdAt != null
          ? DateFormat('d MMM').format(createdAt)
          : null;
      final end = deadlineDate != null
          ? DateFormat('d MMM y').format(deadlineDate)
          : null;
      final value = (start != null && end != null)
          ? '$start – $end'
          : (end ?? start!);
      detailRows.add(_DetailRowData(
        icon: Iconsax.calendar,
        label: 'Campaign Dates',
        value: value,
      ));
    }
    if (location.isNotEmpty) {
      detailRows.add(_DetailRowData(
        icon: Iconsax.location,
        label: 'Target Location',
        value: location,
      ));
    }
    if (platform.isNotEmpty || category.isNotEmpty) {
      final contentType = <String>[
        if (platform.isNotEmpty) platform,
        if (category.isNotEmpty) category,
      ].join(' • ');
      detailRows.add(_DetailRowData(
        icon: Iconsax.document,
        label: 'Content Type',
        value: contentType,
      ));
    }
    if (hashtags.isNotEmpty) {
      detailRows.add(_DetailRowData(
        icon: Iconsax.hashtag,
        label: 'Hashtags',
        value: hashtags.map((h) => h.startsWith('#') ? h : '#$h').join(' '),
      ));
    }

    // ── Pills row (only fields that exist) ──
    final pills = <_PillData>[
      if (platform.isNotEmpty)
        _PillData(icon: _platformIcon(platform), label: platform),
      if (gender.isNotEmpty)
        _PillData(icon: Iconsax.people, label: gender),
      if (category.isNotEmpty)
        _PillData(icon: Iconsax.category, label: category),
    ];

    return SafeArea(
      top: false,
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover header with overlaid app bar + status/category pill.
                _CoverHeader(
                  coverImageUrl: coverImageUrl,
                  status: status,
                  category: category,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Applied banner
                      if (hasApplied) ...[
                        const _AppliedBanner(),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Title
                      Text(
                        title,
                        style: AppTextStyles.h4.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 23,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Brand row: avatar + name + chevron + muted subtitle.
                      _BrandRow(
                        brandName: brandName,
                        brandAvatar: brandAvatar,
                        subtitle: brandSubtitle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Two side-by-side stat cards.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Iconsax.wallet,
                              value: budgetValue ?? 'N/A',
                              valueColor: AppColors.accentOrange,
                              subtitle: 'Per creator',
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              icon: Iconsax.people,
                              value: slotsValue ?? '—',
                              valueColor: textPrimary,
                              subtitle: 'Creators needed',
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                          ),
                        ],
                      ),

                      // Pills row.
                      if (pills.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final p in pills)
                              _Pill(
                                icon: p.icon,
                                label: p.label,
                                isDark: isDark,
                                textSecondary: textSecondary,
                              ),
                          ],
                        ),
                      ],

                      // About Campaign.
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'About Campaign',
                          style: AppTextStyles.h6.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ExpandableText(
                          text: description,
                          textSecondary: textSecondary,
                        ),
                      ],

                      // Details rows.
                      if (detailRows.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _DetailsCard(
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          rows: detailRows,
                        ),
                      ],

                      // Requirements (guidelines) — keep existing data.
                      if (guidelines.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Requirements',
                          style: AppTextStyles.h6.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: AppRadius.allLg,
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            guidelines,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      // Minimum followers — keep existing data.
                      if (minFollowers != null &&
                          minFollowers is num &&
                          minFollowers > 0) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            borderRadius: AppRadius.allMd,
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.people,
                                  size: 18, color: AppColors.warning),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Minimum ${NumberFormat.compact().format(minFollowers)} followers required',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Bottom padding so content clears the sticky Apply bar.
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _hashtagsFrom(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      return raw
          .split(RegExp(r'[,\s]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static IconData _platformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('insta')) return Iconsax.instagram;
    return Iconsax.global;
  }

  static String _formatAmount(dynamic amount) {
    final value = amount is num ? amount : num.tryParse(amount.toString());
    if (value == null) return amount.toString();
    if (value >= 1000) return NumberFormat('#,##0').format(value);
    return value.toStringAsFixed(
        value.truncateToDouble() == value ? 0 : 2);
  }
}

// ─── Cover Header ─────────────────────────────────────────────────────────────

class _CoverHeader extends StatelessWidget {
  final String coverImageUrl;
  final String status;
  final String category;

  const _CoverHeader({
    required this.coverImageUrl,
    required this.status,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    // Prefer status if available, else category, for the pill.
    // Match the Job Details screen: orange for Active/open and the
    // category-only case, neutral grey for the Closed state.
    String? pillText;
    bool isClosed = false;
    if (status.isNotEmpty) {
      final s = status.toLowerCase();
      if (s == 'active' || s == 'open') {
        pillText = 'Active';
      } else if (s == 'closed' || s == 'inactive') {
        pillText = 'Closed';
        isClosed = true;
      } else {
        pillText = status;
      }
    } else if (category.isNotEmpty) {
      pillText = category;
    }

    return Stack(
      children: [
        // Cover image / gradient placeholder.
        SizedBox(
          height: 200 + topPad,
          width: double.infinity,
          child: CampaignCoverHeader(
            coverImageUrl: coverImageUrl,
            height: 200 + topPad,
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

        // Top overlay row: back, bookmark + share.
        Positioned(
          top: topPad + AppSpacing.sm,
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PremiumIconButton(
                icon: Iconsax.arrow_left,
                background: true,
                color: Colors.white,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
              Row(
                children: [
                  PremiumIconButton(
                    icon: Iconsax.save_2,
                    background: true,
                    color: Colors.white,
                    tooltip: 'Save',
                    onPressed: () {},
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PremiumIconButton(
                    icon: Iconsax.share,
                    background: true,
                    color: Colors.white,
                    tooltip: 'Share',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),

        // Status/category pill (top-right, below the app bar row).
        if (pillText != null)
          Positioned(
            top: topPad + 64,
            right: AppSpacing.lg,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isClosed ? AppColors.neutral : AppColors.accentOrange,
                borderRadius: AppRadius.pillAll,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                pillText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Applied Banner ───────────────────────────────────────────────────────────

class _AppliedBanner extends StatelessWidget {
  const _AppliedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: const [
          Icon(Iconsax.tick_circle, size: 20, color: AppColors.success),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "You've applied to this campaign",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Brand Row ────────────────────────────────────────────────────────────────

class _BrandRow extends StatelessWidget {
  final String brandName;
  final String? brandAvatar;
  final String subtitle;
  final Color textPrimary;
  final Color textSecondary;

  const _BrandRow({
    required this.brandName,
    required this.brandAvatar,
    required this.subtitle,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PremiumAvatar(
          imageUrl: brandAvatar,
          name: brandName,
          size: 44,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                brandName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        Icon(Iconsax.arrow_right_3, size: 18, color: textSecondary),
      ],
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color valueColor;
  final String subtitle;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.valueColor,
    required this.subtitle,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pill ─────────────────────────────────────────────────────────────────────

class _PillData {
  final IconData icon;
  final String label;

  const _PillData({required this.icon, required this.label});
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color textSecondary;

  const _Pill({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Details Card ─────────────────────────────────────────────────────────────

class _DetailRowData {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class _DetailsCard extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final List<_DetailRowData> rows;

  const _DetailsCard({
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rows[i].icon, size: 18, color: textSecondary),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    rows[i].label,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: rows[i].valueColor ?? textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Expandable Description ───────────────────────────────────────────────────

class _ExpandableText extends StatefulWidget {
  final String text;
  final Color textSecondary;

  const _ExpandableText({required this.text, required this.textSecondary});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  static const int _collapsedLines = 4;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyMedium.copyWith(
      color: widget.textSecondary,
      height: 1.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
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
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
                if (overflows) ...[
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded ? 'Read less' : 'Read more',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── Sticky Apply Bar ─────────────────────────────────────────────────────────

/// Sticky bottom apply bar — full-width orange Apply Now with a right arrow.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _buildButton(context, hasApplied),
    );
  }

  Widget _buildButton(
    BuildContext context,
    AsyncValue<bool> hasApplied,
  ) {
    // Closed/inactive campaign — disabled neutral state, mirroring the Job
    // Details screen so a Closed campaign never presents a live Apply CTA.
    if (isClosed) {
      return const _StatusButton(
        label: 'Closed',
        icon: Iconsax.slash,
        color: AppColors.neutral,
      );
    }
    // Slots full — disabled red state (parallels the Job Details gate).
    if (isFull) {
      return const _StatusButton(
        label: 'Slots Full',
        icon: Iconsax.slash,
        color: AppColors.error,
      );
    }
    return hasApplied.when(
      data: (applied) {
        if (applied) {
          return const _StatusButton(
            label: 'Already Applied',
            icon: Iconsax.tick_circle,
            color: AppColors.success,
          );
        }
        return _ApplyNowButton(
          loading: false,
          onPressed: () => context.push('/campaigns/$campaignId/apply'),
        );
      },
      loading: () => const _ApplyNowButton(loading: true),
      error: (_, __) => _ApplyNowButton(
        loading: false,
        onPressed: () => context.push('/campaigns/$campaignId/apply'),
      ),
    );
  }
}

/// The orange "Apply Now" CTA with a right arrow icon and loading state.
class _ApplyNowButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _ApplyNowButton({required this.loading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: loading ? null : onPressed,
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accentOrange,
          borderRadius: AppRadius.allMd,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentOrange.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Apply Now',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Iconsax.arrow_right_3,
                      size: 20, color: Colors.white),
                ],
              ),
      ),
    );
  }
}

/// A disabled, tinted status button (Already Applied).
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
        borderRadius: AppRadius.allMd,
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
