import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../admin/providers/is_admin_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Profile',
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: Icon(
              Iconsax.menu_1,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profileState) =>
            _buildProfileContent(context, ref, profileState),
        loading: () => const ShimmerProfile(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.warning_2,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Failed to load profile',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref.invalidate(currentUserProfileProvider),
                child: Text(
                  'Retry',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    ProfileState profileState,
  ) {
    final profile = profileState.profile;
    if (profile == null) {
      return const Center(child: Text('No profile data'));
    }

    // Admin Center entry is shown ONLY to admins (role == 'admin' or the
    // hardcoded admin email). Gated via isAdminProvider.
    final isAdmin = ref.watch(isAdminProvider);

    final name = profile['name'] ?? 'User';
    final handle = profile['handle'] ?? '';
    final role = profile['role'] ?? 'creator';
    final avatarUrl = profile['avatar_url'];
    final bio = (profile['bio'] ?? '').toString();
    final isVerified = (profile['is_verified'] == true);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          // Avatar
          _buildAvatarSection(context, avatarUrl, name),
          const SizedBox(height: AppSpacing.lg),
          // Name + verified badge (badge sits right after the username)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
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
          ),
          // Handle
          if (handle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '@$handle',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Role badge (token-driven)
          RoleBadge.fromString(role),
          // Bio
          if (bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          // Followers / Following stats (only these two — no post/campaign count)
          _buildFollowStats(context, ref),
          const SizedBox(height: AppSpacing.xl),
          // Edit Profile + Share Profile buttons
          _buildProfileButtons(context, handle),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          const SizedBox(height: AppSpacing.sm),
          // Quick action menu items
          _buildMenuItem(
            icon: Iconsax.wallet_1,
            title: 'Wallet',
            onTap: () => context.push('/wallet'),
          ),
          _buildMenuItem(
            icon: Iconsax.bag_2,
            title: 'My Orders',
            onTap: () => context.push('/orders'),
          ),
          _buildMenuItem(
            icon: Iconsax.crown_1,
            title: 'Subscriptions',
            onTap: () => context.push('/subscriptions'),
          ),
          // Admin Center — visible only to admins.
          if (isAdmin)
            _buildMenuItem(
              icon: Iconsax.shield_tick,
              title: 'Admin Center',
              onTap: () => context.push('/admin'),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Instagram-style stats row: only Followers and Following.
  Widget _buildFollowStats(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(currentUserFollowersCountProvider);
    final followingAsync = ref.watch(currentUserFollowingCountProvider);

    String fmt(AsyncValue<int> v) => v.when(
          data: (c) => _formatCount(c),
          loading: () => '—',
          error: (_, __) => '0',
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatPill(label: 'Followers', value: fmt(followersAsync)),
          Container(
            width: 1,
            height: 36,
            color: Theme.of(context).dividerColor,
          ),
          StatPill(label: 'Following', value: fmt(followingAsync)),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  /// Edit Profile + Share Profile buttons (side by side, Instagram style).
  Widget _buildProfileButtons(BuildContext context, String handle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: PremiumButton(
              label: 'Edit Profile',
              variant: PremiumButtonVariant.outline,
              icon: Iconsax.edit,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PremiumButton(
              label: 'Share Profile',
              variant: PremiumButtonVariant.outline,
              icon: Iconsax.share,
              onPressed: () => _shareProfile(context, handle),
            ),
          ),
        ],
      ),
    );
  }

  /// Copies the public profile link to the clipboard so it can be shared.
  void _shareProfile(BuildContext context, String handle) {
    if (handle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set a username first to share your profile'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final link = 'https://rexo.app/profile/$handle';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile link copied: $link'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.allMd,
        ),
      ),
    );
  }

  Widget _buildAvatarSection(
      BuildContext context, String? avatarUrl, String name) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        PremiumAvatar(
          imageUrl: avatarUrl,
          name: name,
          size: 100,
          showRing: true,
          ringColor: AppColors.primary,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.surface, width: 2),
            ),
            child: const Icon(
              Iconsax.camera,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return ListTile(
          leading: Icon(icon,
              color: theme.colorScheme.onSurface.withOpacity(0.6), size: 22),
          title: Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            Iconsax.arrow_right_3,
            size: 18,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        );
      },
    );
  }
}
