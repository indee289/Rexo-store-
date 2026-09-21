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
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/campaigns_provider.dart';

/// Campaign detail screen — rewritten from scratch.
///
/// Shows ALL campaign information that a creator needs to understand the
/// campaign. Layout: cover image → title + status → brand row → stat cards →
/// info sections (description, requirements, deliverables, rules, demo asset,
/// deadline, targeting). Sticky Apply Now button at bottom.
///
/// No save/share buttons. No unnecessary scrolling.
class CampaignDetailScreen extends ConsumerWidget {
  final String campaignId;
  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignDetailProvider(campaignId));
    final hasApplied = ref.watch(hasAppliedProvider(campaignId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) return _NotFound(onBack: () => context.pop());
          return _DetailBody(campaign: campaign, hasApplied: hasApplied);
        },
        loading: () => _Loading(),
        error: (e, _) => _Error(
          message: ErrorUtils.sanitize(e),
          onRetry: () => ref.invalidate(campaignDetailProvider(campaignId)),
          onBack: () => context.pop(),
        ),
      ),
      // Sticky Apply Now bar at the very bottom — never scrolls.
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
        fallback: _str(campaign, 'coverImage', fallback: _str(campaign, 'bannerUrl')));
    final description = _str(campaign, 'description');
    final status = _str(campaign, 'status');
    final category = _str(campaign, 'category');
    final platform = _str(campaign, 'platform');
    final brandName = _str(campaign, 'brandName',
        fallback: _str(campaign, 'companyName',
            fallback: _str(campaign, 'company_name',
                fallback: (campaign['users'] as Map?)?['name']?.toString() ?? '')));
    final brandAvatar = (campaign['users'] as Map?)?['profileImage'] as String?;
    final budget = campaign['budget'] ?? campaign['totalBudget'] ?? campaign['total_budget'];
    final perCreator = campaign['payout_per_creator'] ?? campaign['payoutPerCreator'];
    final slots = _int(campaign, 'slots');
    final filledSlots = _int(campaign, 'filled_slots') ?? 0;
    final deadline = _str(campaign, 'deadline');
    final requirements = _str(campaign, 'requirements');
    final deliverables = _str(campaign, 'deliverables');
    final rules = _str(campaign, 'rules');
    final demoType = _str(campaign, 'demo_asset_type');
    final demoUrl = _str(campaign, 'demo_asset_url');
    final gender = _str(campaign, 'gender',
        fallback: _str(campaign, 'targetGender', fallback: _str(campaign, 'target_gender')));
    final minFollowers = _int(campaign, 'min_followers');
    final pageCategory = _str(campaign, 'pageProfileCategory',
        fallback: _str(campaign, 'page_profile_category'));
    final createdAt = DateTime.tryParse(_str(campaign, 'createdAt',
        fallback: _str(campaign, 'created_at')));
    final deadlineDate = deadline.isNotEmpty ? DateTime.tryParse(deadline) : null;

    // Platforms split
    final platforms = platform.isNotEmpty
        ? platform.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList()
        : <String>[];

    return SafeArea(
      top: false,
      bottom: false,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        children: [
          // ── Cover image + back button + status badge ──
          _CoverSection(
            coverImage: coverImage,
            status: status,
            onBack: () => context.pop(),
          ),

          // ── Main content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Applied banner
                if (hasApplied.valueOrNull == true) ...[
                  _InfoBanner(
                    icon: Iconsax.tick_circle,
                    text: 'You have already applied to this campaign',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                Text(
                  title,
                  style: AppTextStyles.title1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Brand row
                if (brandName.isNotEmpty)
                  _BrandRow(name: brandName, avatarUrl: brandAvatar),

                const SizedBox(height: 20),

                // ── Stat cards row ──
                Row(
                  children: [
                    if (perCreator != null)
                      Expanded(
                        child: _StatTile(
                          label: 'Per Creator',
                          value: '₹${_fmtNum(perCreator)}',
                          icon: Iconsax.wallet,
                          color: AppColors.primary,
                        ),
                      ),
                    if (perCreator != null && slots != null)
                      const SizedBox(width: 10),
                    if (slots != null)
                      Expanded(
                        child: _StatTile(
                          label: 'Slots',
                          value: '$filledSlots / $slots',
                          icon: Iconsax.people,
                          color: AppColors.textPrimary,
                        ),
                      ),
                  ],
                ),

                // Total budget
                if (budget != null) ...[
                  const SizedBox(height: 10),
                  _StatTile(
                    label: 'Total Budget',
                    value: '₹${_fmtNum(budget)}',
                    icon: Iconsax.chart_2,
                    color: AppColors.primary,
                  ),
                ],

                // ── Tags row ──
                if (platforms.isNotEmpty || category.isNotEmpty || gender.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final p in platforms) _Tag(p),
                      if (category.isNotEmpty) _Tag(category),
                      if (gender.isNotEmpty) _Tag(gender),
                      if (pageCategory.isNotEmpty) _Tag(pageCategory),
                    ],
                  ),
                ],

                // ── Dates ──
                if (deadlineDate != null || createdAt != null) ...[
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Iconsax.calendar,
                    label: 'Deadline',
                    value: deadlineDate != null
                        ? DateFormat('d MMM yyyy').format(deadlineDate)
                        : (createdAt != null
                            ? 'Started ${DateFormat('d MMM').format(createdAt)}'
                            : ''),
                  ),
                ],

                // Min followers
                if (minFollowers != null && minFollowers > 0) ...[
                  const SizedBox(height: 10),
                  _InfoBanner(
                    icon: Iconsax.people,
                    text: 'Minimum ${NumberFormat.compact().format(minFollowers)} followers required',
                    color: AppColors.warning,
                  ),
                ],

                // ── Description ──
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _Section(title: 'About This Campaign', body: description),
                ],

                // ── Requirements ──
                if (requirements.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _Section(title: 'Requirements', body: requirements),
                ],

                // ── Deliverables ──
                if (deliverables.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _Section(title: 'Deliverables', body: deliverables),
                ],

                // ── Rules ──
                if (rules.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _Section(title: 'Rules', body: rules),
                ],

                // ── Demo Asset ──
                if (demoType.isNotEmpty && demoUrl.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Demo Asset',
                      style: AppTextStyles.headline
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  DemoAssetView(type: demoType, value: demoUrl),
                ],

                // Bottom padding for the sticky Apply bar
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COVER IMAGE SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class _CoverSection extends StatelessWidget {
  final String coverImage;
  final String status;
  final VoidCallback onBack;

  const _CoverSection({
    required this.coverImage,
    required this.status,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        CampaignCoverHeader(
          coverImageUrl: coverImage,
          height: 200 + topPad,
          overlay: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
        // Back button only — NO save/share
        Positioned(
          top: topPad + 8,
          left: 8,
          child: PremiumIconButton(
            icon: Iconsax.arrow_left,
            background: true,
            color: Colors.white,
            onPressed: onBack,
          ),
        ),
        // Status badge
        if (status.isNotEmpty)
          Positioned(
            top: topPad + 12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor(status),
                borderRadius: AppRadius.allSm,
              ),
              child: Text(
                _statusLabel(status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// BRAND ROW
// ═══════════════════════════════════════════════════════════════════════════════

class _BrandRow extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _BrandRow({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PremiumAvatar(imageUrl: avatarUrl, name: name, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAT TILE
// ═══════════════════════════════════════════════════════════════════════════════

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTextStyles.headline.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(label,
                    style: AppTextStyles.footnote
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAG CHIP
// ═══════════════════════════════════════════════════════════════════════════════

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: AppTextStyles.footnote.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INFO ROW (icon + label + value)
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: AppTextStyles.subheadline
                .copyWith(color: AppColors.textSecondary)),
        Expanded(
          child: Text(value,
              style: AppTextStyles.subheadline
                  .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INFO BANNER (colored bar with icon + text)
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBanner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTextStyles.subheadline.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION (title + body text)
// ═══════════════════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Text(
            body,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
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

    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16, 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: _buildButton(context, hasApplied),
    );
  }

  Widget _buildButton(BuildContext context, AsyncValue<bool> hasApplied) {
    if (isClosed) {
      return _StatusBtn(label: 'Closed', color: AppColors.neutral);
    }
    if (isFull) {
      return _StatusBtn(label: 'Slots Full', color: AppColors.error);
    }
    return hasApplied.when(
      data: (applied) {
        if (applied) {
          return _StatusBtn(label: 'Already Applied', color: AppColors.success);
        }
        return _ApplyBtn(
          onPressed: () => context.push('/campaigns/$campaignId/apply'),
        );
      },
      loading: () => _ApplyBtn(loading: true),
      error: (_, __) => _ApplyBtn(
        onPressed: () => context.push('/campaigns/$campaignId/apply'),
      ),
    );
  }
}

class _ApplyBtn extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const _ApplyBtn({this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 48,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.allMd,
        ),
        child: loading
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Apply Now',
                      style: AppTextStyles.button
                          .copyWith(color: Colors.white, fontSize: 15)),
                  const SizedBox(width: 6),
                  const Icon(Iconsax.arrow_right_3,
                      size: 18, color: Colors.white),
                ],
              ),
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBtn({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOADING / ERROR / NOT FOUND
// ═══════════════════════════════════════════════════════════════════════════════

class _Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerCard(height: 200),
            SizedBox(height: 16),
            ShimmerLine(width: 200, height: 20),
            SizedBox(height: 12),
            ShimmerLine(height: 14),
            SizedBox(height: 8),
            ShimmerLine(width: 150, height: 14),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _Error({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 8, left: 8,
            child: PremiumIconButton(
              icon: Iconsax.arrow_left,
              onPressed: onBack,
            ),
          ),
          Center(
            child: EmptyState(
              icon: Iconsax.warning_2,
              title: 'Failed to load campaign',
              subtitle: message,
              ctaLabel: 'Retry',
              onCta: onRetry,
            ),
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
          Positioned(
            top: 8, left: 8,
            child: PremiumIconButton(
              icon: Iconsax.arrow_left,
              onPressed: onBack,
            ),
          ),
          const Center(
            child: EmptyState(
              icon: Iconsax.document,
              title: 'Campaign not found',
              subtitle: 'This campaign may have been removed.',
            ),
          ),
        ],
      ),
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
