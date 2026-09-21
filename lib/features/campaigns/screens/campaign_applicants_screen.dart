import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_sheet.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/campaigns_provider.dart';

/// Lists the applicants for one of the brand's own campaigns. Each row is
/// tappable and opens a detail sheet with the applicant's full profile,
/// including a clickable Instagram link. RLS restricts the underlying query to
/// the campaign owner.
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
    final theme = Theme.of(context);
    final applicantsAsync = ref.watch(campaignApplicantsProvider(campaignId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: campaignTitle,
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: applicantsAsync.when(
        data: (applicants) {
          if (applicants.isEmpty) {
            return const EmptyState(
              icon: Iconsax.people,
              title: 'No applicants yet',
              subtitle: 'Creators who apply will appear here',
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(campaignApplicantsProvider(campaignId));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: applicants.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                return _ApplicantTile(application: applicants[index]);
              },
            ),
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (_, __) => const ShimmerConversationRow(),
        ),
        error: (e, _) => EmptyState(
          icon: Iconsax.warning_2,
          title: 'Could not load applicants',
          subtitle: ErrorUtils.sanitize(e),
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
    final theme = Theme.of(context);
    final creator = application['creator'] as Map<String, dynamic>?;
    final displayName =
        (application['applicant_name'] ?? creator?['name'] ?? 'Applicant')
            .toString();
    final handle = (creator?['username'] ?? '').toString(); // live: username
    final avatarUrl = creator?['profileImage'] as String?;  // live: profileImage
    final isVerified = creator?['isVerified'] == true;
    final status = (application['status'] ?? 'pending').toString();
    final category = (application['category'] ?? '').toString();
    final followers = application['followers_count'];

    return InkWell(
      borderRadius: AppRadius.allLg,
      onTap: () => _showApplicantDetail(context, application),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            PremiumAvatar(
              imageUrl: avatarUrl,
              name: displayName,
              size: 48,
              isVerified: isVerified,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (handle.isNotEmpty)
                    Text(
                      '@$handle',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (category.isNotEmpty) ...[
                        Icon(Iconsax.category,
                            size: 13,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            category,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (followers != null) ...[
                        Icon(Iconsax.people,
                            size: 13,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 3),
                        Text(
                          _formatCount(followers),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _StatusBadge(status: status),
          ],
        ),
      ),
    );
  }

  static String _formatCount(dynamic value) {
    final n = int.tryParse(value.toString()) ?? 0;
    return NumberFormat.compact().format(n);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'approved':
        color = AppColors.success;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      case 'withdrawn':
        color = AppColors.textSecondary;
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.allSm,
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1).toLowerCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
  showPremiumSheet<void>(
    context: context,
    title: 'Applicant Details',
    child: _ApplicantDetailSheet(application: application),
  );
}

class _ApplicantDetailSheet extends StatelessWidget {
  final Map<String, dynamic> application;

  const _ApplicantDetailSheet({required this.application});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creator = application['creator'] as Map<String, dynamic>?;
    final displayName =
        (application['applicant_name'] ?? creator?['name'] ?? 'Applicant')
            .toString();
    final handle = (creator?['username'] ?? '').toString(); // live: username
    final avatarUrl = creator?['profileImage'] as String?;  // live: profileImage
    final isVerified = creator?['isVerified'] == true;
    final instagram =
        _normalizeInstagram((application['instagram_url'] ?? '').toString());
    final pitch = (application['pitch'] ?? '').toString();
    final portfolio = (application['portfolio_url'] ?? '').toString();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PremiumAvatar(
                imageUrl: avatarUrl,
                name: displayName,
                size: 56,
                isVerified: isVerified,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.h6,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (handle.isNotEmpty)
                      Text(
                        '@$handle',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailRow(
              icon: Iconsax.location,
              label: 'Location',
              value: application['location']),
          _DetailRow(
              icon: Iconsax.category,
              label: 'Category',
              value: application['category']),
          _DetailRow(
              icon: Iconsax.building,
              label: 'City',
              value: application['city']),
          _DetailRow(
              icon: Iconsax.map, label: 'State', value: application['state']),
          _DetailRow(
              icon: Iconsax.call,
              label: 'Contact',
              value: application['contact_number']),
          _DetailRow(
            icon: Iconsax.people,
            label: 'Followers',
            value: application['followers_count'] != null
                ? NumberFormat.decimalPattern()
                    .format(application['followers_count'])
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Clickable Instagram link
          if (instagram != null)
            _LinkTile(
              icon: Iconsax.instagram,
              label: 'Instagram',
              display: (application['instagram_url'] ?? instagram).toString(),
              url: instagram,
            ),
          if (portfolio.isNotEmpty)
            _LinkTile(
              icon: Iconsax.link,
              label: 'Portfolio',
              display: portfolio,
              url: portfolio,
            ),

          if (pitch.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Pitch', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(pitch, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final text = (value ?? '').toString();
    if (text.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$label:',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String display;
  final String url;

  const _LinkTile({
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open link'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: InkWell(
        borderRadius: AppRadius.allSm,
        onTap: () => _open(context),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                display,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Iconsax.export_1, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
