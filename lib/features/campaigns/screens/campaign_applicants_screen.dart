import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/verified_badge.dart';
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
      appBar: AppBar(
        title: Text(campaignTitle, style: AppTextStyles.h5),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: applicantsAsync.when(
        data: (applicants) {
          if (applicants.isEmpty) {
            return _buildEmptyState(theme);
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(campaignApplicantsProvider(campaignId));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: applicants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ApplicantTile(application: applicants[index]);
              },
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(ErrorUtils.sanitize(e), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.people,
              size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No applicants yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Creators who apply will appear here',
            style: AppTextStyles.bodySmall,
          ),
        ],
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
    final displayName = (application['applicant_name'] ??
            creator?['name'] ??
            'Applicant')
        .toString();
    final handle = (creator?['handle'] ?? '').toString();
    final avatarUrl = creator?['avatar_url'] as String?;
    final isVerified = creator?['is_verified'] == true;
    final status = (application['status'] ?? 'pending').toString();
    final category = (application['category'] ?? '').toString();
    final followers = application['followers_count'];

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showApplicantDetail(context, application),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            AvatarWidget(url: avatarUrl, name: displayName, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) const VerifiedBadge(size: 14),
                    ],
                  ),
                  if (handle.isNotEmpty)
                    Text(
                      '@$handle',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  const SizedBox(height: 4),
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
                        const SizedBox(width: 10),
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
        color = Colors.grey;
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 9,
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ApplicantDetailSheet(application: application),
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
    final handle = (creator?['handle'] ?? '').toString();
    final avatarUrl = creator?['avatar_url'] as String?;
    final isVerified = creator?['is_verified'] == true;
    final instagram = _normalizeInstagram(
        (application['instagram_url'] ?? '').toString());
    final pitch = (application['pitch'] ?? '').toString();
    final portfolio = (application['portfolio_url'] ?? '').toString();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                AvatarWidget(url: avatarUrl, name: displayName, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: AppTextStyles.h6,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) const VerifiedBadge(size: 16),
                        ],
                      ),
                      if (handle.isNotEmpty)
                        Text(
                          '@$handle',
                          style: AppTextStyles.bodySmall.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                icon: Iconsax.map,
                label: 'State',
                value: application['state']),
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
            const SizedBox(height: 8),

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
              const SizedBox(height: 16),
              Text('Pitch', style: AppTextStyles.labelLarge),
              const SizedBox(height: 6),
              Text(pitch, style: AppTextStyles.bodyMedium),
            ],
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 8),
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
        launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _open(context),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 8),
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
