import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_avatar.dart';
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

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: profileAsync.when(
        data: (profileState) =>
            _buildProfileContent(context, ref, profileState),
        loading: () => const ShimmerProfile(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Iconsax.warning_2,
                size: 48,
                color: AppColors.darkTextSecondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Failed to load profile',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.darkTextSecondary,
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

    final isAdmin = ref.watch(isAdminProvider);
    final name = profile['name'] ?? 'User';
    final handle = profile['handle'] ?? '';
    final role = profile['role'] ?? 'creator';
    final avatarUrl = profile['avatar_url'];
    final bio = (profile['bio'] ?? '').toString();
    final isVerified = (profile['is_verified'] == true);

    return CustomScrollView(
      slivers: [
        // ── Custom stack-based header ──────────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 260,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient banner
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 180,
                    decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient,
                    ),
                  ),
                ),

                // Top bar: settings icon
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile',
                            style: AppTextStyles.h5.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/settings'),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: AppRadius.allMd,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              child: const Icon(
                                Iconsax.menu_1,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Avatar floating on banner edge
                Positioned(
                  top: 130,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildAvatarSection(context, avatarUrl, name),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Name, handle, role ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const VerifiedBadge(size: 20),
                    ],
                  ],
                ),
                if (handle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$handle',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Role pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: AppRadius.pillAll,
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Stats row ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildFollowStats(context, ref),
          ),
        ),

        // ── Bio ────────────────────────────────────────────────────────────
        if (bio.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.darkTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bio,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.darkTextSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Action buttons ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildProfileButtons(context, handle),
          ),
        ),

        // ── Divider ────────────────────────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 20, 0, 4),
            child: Divider(
              color: AppColors.darkBorder,
              thickness: 1,
              height: 1,
            ),
          ),
        ),

        // ── Menu items ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Column(
            children: [
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
              if (isAdmin)
                _buildMenuItem(
                  icon: Iconsax.shield_tick,
                  title: 'Admin Center',
                  onTap: () => context.push('/admin'),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowStats(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(currentUserFollowersCountProvider);
    final followingAsync = ref.watch(currentUserFollowingCountProvider);

    String fmt(AsyncValue<int> v) => v.when(
          data: (c) => _formatCount(c),
          loading: () => '—',
          error: (_, __) => '0',
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatPill(label: 'Followers', value: fmt(followersAsync)),
          Container(width: 1, height: 36, color: AppColors.darkBorder),
          _StatPill(label: 'Following', value: fmt(followingAsync)),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Widget _buildProfileButtons(BuildContext context, String handle) {
    return Row(
      children: [
        Expanded(
          child: _OutlineBtn(
            label: 'Edit Profile',
            icon: Iconsax.edit,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OutlineBtn(
            label: 'Share',
            icon: Iconsax.share,
            onPressed: () => _shareProfile(context, handle),
          ),
        ),
      ],
    );
  }

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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
    );
  }

  Widget _buildAvatarSection(
      BuildContext context, String? avatarUrl, String name) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.darkBackground,
              width: 4,
            ),
          ),
          child: PremiumAvatar(
            imageUrl: avatarUrl,
            name: name,
            size: 88,
            showRing: true,
            ringColor: AppColors.primary,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBackground, width: 2),
            ),
            child: const Icon(Iconsax.camera, size: 14, color: Colors.white),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: AppRadius.allSm,
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Icon(icon,
                    color: AppColors.darkTextSecondary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: AppColors.darkTextHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h5.copyWith(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.darkTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _OutlineBtn(
      {required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: AppColors.darkTextPrimary),
        label: Text(label,
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.darkTextPrimary)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.darkBorder),
          shape:
              RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          backgroundColor: AppColors.darkCard,
        ),
      ),
    );
  }
}
