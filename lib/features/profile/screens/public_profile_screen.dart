import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../services/supabase_service.dart';

/// Provider to fetch a public profile by username.
/// Live users table uses `username` column (not `handle`).
final publicProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, handle) async {
  final response = await SupabaseService.client
      .from('users')
      .select()
      .eq('username', handle) // live column: username
      .maybeSingle();

  return response;
});

/// Public profile — rebuilt layout.
///
/// Old: `PremiumAppBar` over a centre-stacked column — avatar, name, handle,
/// role badge, bio — then one `PremiumCard` holding three `StatPill`s split by
/// 1px `Container` dividers, with a 200px shimmer block as the loading state.
///
/// New: collapsing large title, an identity hero card matching the owner's own
/// profile screen, and the three stats as separate glass pills so each is its
/// own surface instead of sharing one card split by rules.
class PublicProfileScreen extends ConsumerWidget {
  final String handle;

  const PublicProfileScreen({super.key, required this.handle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(handle));

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(title: '@$handle', showBack: true),
          profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassEmptyState(
                    icon: AppIcons.user,
                    title: 'User not found',
                    message: 'No user with handle @$handle exists.',
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: _Body(profile: profile, fallbackHandle: handle),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: GlassLoader(),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: GlassErrorState(
                title: 'Failed to load profile',
                onRetry: () => ref.invalidate(publicProfileProvider(handle)),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.profile, required this.fallbackHandle});

  final Map<String, dynamic> profile;
  final String fallbackHandle;

  @override
  Widget build(BuildContext context) {
    // live column: username (was handle); live column: profileImage
    final name = (profile['name'] ?? 'User').toString();
    final avatarUrl = profile['profileImage'] as String?;
    final bio = (profile['bio'] ?? '').toString();
    final role = (profile['role'] ?? 'creator').toString();
    final userHandle = (profile['username'] ?? fallbackHandle).toString();
    final isVerified = profile['isVerified'] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            borderRadius: AppRadius.allXl,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                PremiumAvatar(
                  imageUrl: avatarUrl,
                  name: name,
                  size: PremiumAvatar.sizeXl,
                  showRing: true,
                ),
                AppSpacing.gapLg,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        AppIcons.verify,
                        size: 20,
                        color: AppColors.verified,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@$userHandle',
                  style: AppTextStyles.subheadline
                      .copyWith(color: AppColors.textSecondary),
                ),
                AppSpacing.gapSm,
                GlassChip.status(
                  label: _formatRole(role),
                  color: AppColors.primary,
                ),
                if (bio.isNotEmpty) ...[
                  AppSpacing.gapLg,
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: GlassStatPill(
                  icon: AppIcons.volume_high,
                  value: profile['campaigns_count']?.toString() ?? '0',
                  label: 'Campaigns',
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: GlassStatPill(
                  icon: AppIcons.star_1,
                  value: profile['rating']?.toString() ?? '—',
                  label: 'Rating',
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: GlassStatPill(
                  icon: AppIcons.calendar,
                  value: _formatJoinDate(profile['createdAt']),
                  label: 'Joined',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRole(String r) {
    if (r.isEmpty) return 'Creator';
    return r[0].toUpperCase() + r.substring(1).toLowerCase();
  }

  String _formatJoinDate(dynamic createdAt) {
    if (createdAt == null) return '—';
    try {
      final date = DateTime.parse(createdAt.toString());
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '—';
    }
  }
}
