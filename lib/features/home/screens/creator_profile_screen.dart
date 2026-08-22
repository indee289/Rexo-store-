import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../providers/creators_provider.dart';

/// Creator profile screen showing stats, Follow button, and Message button.
/// Navigated to from the Top Creators tab on the home screen.
class CreatorProfileScreen extends ConsumerWidget {
  final String creatorUserId;

  const CreatorProfileScreen({super.key, required this.creatorUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final creatorAsync = ref.watch(creatorProfileProvider(creatorUserId));
    final isFollowingAsync = ref.watch(isFollowingProvider(creatorUserId));
    final followerCountAsync = ref.watch(followerCountProvider(creatorUserId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Creator Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Iconsax.arrow_left, color: theme.colorScheme.onSurface),
        ),
      ),
      body: creatorAsync.when(
        data: (creator) {
          if (creator == null) {
            return Center(
              child: Text(
                'Creator not found',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          final userData = creator['users'] as Map<String, dynamic>?;
          final name = userData?['name'] ?? 'Creator';
          final avatarUrl = userData?['avatar_url'];
          final handle = userData?['handle'] ?? '';
          final category = creator['category'] ?? '';
          final bio = creator['bio'] ?? '';
          final rating = creator['rating'] ?? 0.0;
          final campaignsCompleted = creator['campaigns_completed'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                AvatarWidget(
                  url: avatarUrl,
                  name: name,
                  size: 96,
                  showBorder: true,
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                // Handle
                if (handle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@$handle',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],

                // Category
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],

                // Bio
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Stats row
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        theme,
                        icon: Iconsax.people,
                        label: 'Followers',
                        value: followerCountAsync.when(
                          data: (count) => _formatCount(count),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: theme.dividerColor,
                      ),
                      _buildStatItem(
                        theme,
                        icon: Iconsax.medal_star,
                        label: 'Campaigns',
                        value: campaignsCompleted.toString(),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: theme.dividerColor,
                      ),
                      _buildStatItem(
                        theme,
                        icon: Iconsax.star_1,
                        label: 'Rating',
                        value: double.tryParse(rating.toString())
                                ?.toStringAsFixed(1) ??
                            '0.0',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons: Follow + Message
                Row(
                  children: [
                    // Follow/Unfollow button
                    Expanded(
                      child: isFollowingAsync.when(
                        data: (isFollowing) {
                          return ElevatedButton.icon(
                            onPressed: () {
                              final notifier =
                                  ref.read(followActionsProvider.notifier);
                              if (isFollowing) {
                                notifier.unfollow(creatorUserId);
                              } else {
                                notifier.follow(creatorUserId);
                              }
                            },
                            icon: Icon(
                              isFollowing
                                  ? Iconsax.user_minus
                                  : Iconsax.user_add,
                              size: 20,
                            ),
                            label: Text(
                              isFollowing ? 'Unfollow' : 'Follow',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing
                                  ? theme.colorScheme.surface
                                  : AppColors.primary,
                              foregroundColor: isFollowing
                                  ? theme.colorScheme.onSurface
                                  : Colors.white,
                              elevation: isFollowing ? 0 : 2,
                              side: isFollowing
                                  ? BorderSide(color: theme.dividerColor)
                                  : null,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        loading: () => ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, __) => ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(
                                isFollowingProvider(creatorUserId));
                          },
                          icon: const Icon(Iconsax.user_add, size: 20),
                          label: Text(
                            'Follow',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Message button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.push('/messages/$creatorUserId');
                        },
                        icon: const Icon(Iconsax.message, size: 20),
                        label: Text(
                          'Message',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Failed to load creator profile',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
