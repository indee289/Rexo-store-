import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../providers/campaigns_provider.dart';

/// Lists the applicants for one of the brand's own campaigns. Each row is
/// tappable and opens a detail sheet with the applicant's full profile,
/// including a clickable Instagram link. RLS restricts the underlying query to
/// the campaign owner.
///
/// Rebuilt layout. Old layout: a `PremiumAppBar` over rows built from an
/// `InkWell` wrapping a hand-decorated `Container`, a bespoke `_StatusBadge`,
/// and a `showPremiumSheet` detail view whose facts were `_DetailRow`s
/// printing "Label:" and a value side by side.
///
/// New layout: a collapsing large title carrying the campaign name with
/// "Applicants" as its subtitle; rows on the shared card surface with the
/// status as a chip; and the detail sheet rebuilt so the applicant's facts are
/// a grouped section and the Instagram/portfolio links are grouped rows,
/// rather than two different hand-built row shapes.
///
/// `campaignApplicantsProvider`, every field fallback chain, the Instagram
/// handle normalisation and the external-application link launch are
/// unchanged.
class CampaignApplicantsScreen extends ConsumerWidget {
  final String campaignId;
  final String campaignTitle;

  const CampaignApplicantsScreen({
    super.key,
    required this.campaignId,
    this.campaignTitle = 'Applicants',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantsAsync = ref.watch(campaignApplicantsProvider(campaignId));

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(campaignApplicantsProvider(campaignId));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            GlassLargeTitleHeader(
              title: campaignTitle,
              subtitle: 'Applicants',
              showBack: true,
              onBack: () => Navigator.of(context).pop(),
            ),
            applicantsAsync.when(
              data: (applicants) {
                if (applicants.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.people,
                      title: 'No applicants yet',
                      message: 'Creators who apply will appear here.',
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
                    itemCount: applicants.length,
                    separatorBuilder: (_, __) => AppSpacing.gapSm,
                    itemBuilder: (context, index) => RepaintBoundary(
                      child: _ApplicantTile(application: applicants[index]),
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: GlassListSkeleton(itemCount: 6),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: GlassErrorState(
                  title: 'Could not load applicants',
                  message: ErrorUtils.sanitize(e),
                  onRetry: () =>
                      ref.invalidate(campaignApplicantsProvider(campaignId)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicantTile extends StatelessWidget {
  final Map<String, dynamic> application;

  const _ApplicantTile({required this.application});

  @override
  Widget build(BuildContext context) {
    final creator = application['creator'] as Map<String, dynamic>?;
    final displayName = (application['applicant_name'] ??
            application['creatorName'] ??
            creator?['name'] ??
            'Applicant')
        .toString();
    final handle = (creator?['username'] ?? '').toString(); // live: username
    final avatarUrl = creator?['profileImage'] as String?; // live: profileImage
    final isVerified = creator?['isVerified'] == true;
    final status = (application['status'] ?? 'pending').toString();
    final category = (application['category'] ?? '').toString();
    final followers = application['followers_count'] ?? application['followers'];

    return GlassCard(
      onTap: () => _showApplicantDetail(context, application),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          PremiumAvatar(
            imageUrl: avatarUrl,
            name: displayName,
            size: 48,
            isVerified: isVerified,
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (handle.isNotEmpty)
                  Text(
                    '@$handle',
                    style: AppTextStyles.footnote
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (category.isNotEmpty || followers != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (category.isNotEmpty) ...[
                        const Icon(
                          AppIcons.category,
                          size: 13,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            category,
                            style: AppTextStyles.caption1
                                .copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppSpacing.gapSm,
                      ],
                      if (followers != null) ...[
                        const Icon(
                          AppIcons.people,
                          size: 13,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatCount(followers),
                          style: AppTextStyles.caption1
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.gapSm,
          GlassChip.status(
            label: status[0].toUpperCase() + status.substring(1).toLowerCase(),
            color: _statusColor(status),
          ),
        ],
      ),
    );
  }

  static String _formatCount(dynamic value) {
    final n = int.tryParse(value.toString()) ?? 0;
    return NumberFormat.compact().format(n);
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'approved':
      return AppColors.success;
    case 'rejected':
      return AppColors.error;
    case 'withdrawn':
      return AppColors.textSecondary;
    default:
      return AppColors.warning;
  }
}

/// Normalize a bare handle (with or without '@') to a full Instagram URL,
/// and leave already-qualified URLs untouched.
String? _normalizeInstagram(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme && uri.hasAuthority) {
    return value;
  }
  final handle = value.startsWith('@') ? value.substring(1) : value;
  if (handle.isEmpty) return null;
  return 'https://instagram.com/$handle';
}

void _showApplicantDetail(
    BuildContext context, Map<String, dynamic> application) {
  showGlassSheet<void>(
    context: context,
    title: 'Applicant details',
    child: _ApplicantDetailSheet(application: application),
  );
}

class _ApplicantDetailSheet extends StatelessWidget {
  final Map<String, dynamic> application;

  const _ApplicantDetailSheet({required this.application});

  @override
  Widget build(BuildContext context) {
    final creator = application['creator'] as Map<String, dynamic>?;
    final displayName = (application['applicant_name'] ??
            application['creatorName'] ??
            creator?['name'] ??
            'Applicant')
        .toString();
    final handle = (creator?['username'] ?? '').toString(); // live: username
    final avatarUrl = creator?['profileImage'] as String?; // live: profileImage
    final isVerified = creator?['isVerified'] == true;
    final instagram = _normalizeInstagram(
        (application['instagram_url'] ?? application['instagram'] ?? '')
            .toString());
    final pitch = (application['pitch'] ?? '').toString();
    final portfolio =
        (application['portfolio_url'] ?? application['contentLink'] ?? '')
            .toString();

    final followersRaw =
        application['followers_count'] ?? application['followers'];

    // The facts, as grouped rows. Empty values are dropped, exactly as the
    // old `_DetailRow` did by returning a shrink-wrapped box.
    final factRows = <Widget>[
      ..._fact(AppIcons.location, 'Location', application['location']),
      ..._fact(AppIcons.category, 'Category', application['category']),
      ..._fact(AppIcons.building, 'City', application['city']),
      ..._fact(AppIcons.map, 'State', application['state']),
      ..._fact(AppIcons.call, 'Contact',
          application['contact_number'] ?? application['contact']),
      ..._fact(
        AppIcons.people,
        'Followers',
        followersRaw != null
            ? NumberFormat.decimalPattern().format(followersRaw)
            : null,
      ),
    ];

    final linkRows = <Widget>[
      if (instagram != null)
        _LinkRow(
          icon: AppIcons.instagram,
          label: 'Instagram',
          display: (application['instagram_url'] ?? instagram).toString(),
          url: instagram,
        ),
      if (portfolio.isNotEmpty)
        _LinkRow(
          icon: AppIcons.link,
          label: 'Portfolio',
          display: portfolio,
          url: portfolio,
        ),
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PremiumAvatar(
                imageUrl: avatarUrl,
                name: displayName,
                size: 56,
                isVerified: isVerified,
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.title3
                          .copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (handle.isNotEmpty)
                      Text(
                        '@$handle',
                        style: AppTextStyles.footnote
                            .copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (factRows.isNotEmpty) ...[
            AppSpacing.gapLg,
            GlassGroup(children: factRows),
          ],

          if (linkRows.isNotEmpty) ...[
            AppSpacing.gapMd,
            GlassGroup(children: linkRows),
          ],

          if (pitch.isNotEmpty) ...[
            AppSpacing.gapLg,
            Text(
              'PITCH',
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            AppSpacing.gapSm,
            GlassCard(
              child: Text(
                pitch,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// One fact row, or nothing when the value is empty.
  List<Widget> _fact(IconData icon, String label, dynamic value) {
    final text = (value ?? '').toString();
    if (text.isEmpty) return const [];
    return [
      GlassRow(
        icon: icon,
        title: label,
        trailingText: text,
        showChevron: false,
      ),
    ];
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String display;
  final String url;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.display,
    required this.url,
  });

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    var launched = false;
    if (uri != null) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }
    }
    if (!launched && context.mounted) {
      showGlassSnackBar(
        context,
        message: 'Could not open link',
        tone: GlassToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassRow(
      icon: icon,
      title: label,
      subtitle: display,
      trailing: const Icon(
        AppIcons.export_1,
        size: 16,
        color: AppColors.primary,
      ),
      onTap: () => _open(context),
    );
  }
}
