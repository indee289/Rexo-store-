import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../../services/supabase_service.dart';

/// Provider to fetch a public profile by handle
final publicProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, handle) async {
  final response = await SupabaseService.client
      .from('users')
      .select()
      .eq('handle', handle)
      .maybeSingle();

  return response;
});

class PublicProfileScreen extends ConsumerWidget {
  final String handle;

  const PublicProfileScreen({super.key, required this.handle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(handle));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: '@$handle',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildNotFound(context);
          }
          return _buildProfileContent(context, profile);
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: ShimmerLoading(height: 200),
        ),
        error: (error, _) => EmptyState(
          icon: Iconsax.warning_2,
          title: 'Failed to load profile',
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return EmptyState(
      icon: Iconsax.user,
      title: 'User not found',
      subtitle: 'No user with handle @$handle exists.',
    );
  }

  Widget _buildProfileContent(
      BuildContext context, Map<String, dynamic> profile) {
    final name = profile['name'] ?? 'User';
    final avatarUrl = profile['avatar_url'] as String?;
    final bio = profile['bio'] ?? '';
    final role = profile['role'] ?? 'creator';
    final userHandle = profile['handle'] ?? handle;
    final isVerified = (profile['is_verified'] == true);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          // Avatar
          PremiumAvatar(
            imageUrl: avatarUrl,
            name: name,
            size: PremiumAvatar.sizeXl,
            showRing: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Name + verified badge
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (isVerified) const VerifiedBadge(size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Handle
          Text(
            '@$userHandle',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Role badge (token-driven)
          RoleBadge.fromString(role.toString()),
          // Bio
          if (bio.toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              bio.toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          // Stats
          _buildStatsSection(context, profile),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
      BuildContext context, Map<String, dynamic> profile) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatPill(
            label: 'Campaigns',
            value: profile['campaigns_count']?.toString() ?? '0',
          ),
          Container(
              width: 1, height: 32, color: Theme.of(context).dividerColor),
          StatPill(
            label: 'Rating',
            value: profile['rating']?.toString() ?? '-',
          ),
          Container(
              width: 1, height: 32, color: Theme.of(context).dividerColor),
          StatPill(
            label: 'Joined',
            value: _formatJoinDate(profile['created_at']),
          ),
        ],
      ),
    );
  }

  String _formatJoinDate(dynamic createdAt) {
    if (createdAt == null) return '-';
    try {
      final date = DateTime.parse(createdAt.toString());
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '-';
    }
  }
}
