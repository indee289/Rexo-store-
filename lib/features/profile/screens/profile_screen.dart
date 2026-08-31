import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
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
      backgroundColor: Colors.white,
      body: profileAsync.when(
        data: (profileState) =>
            _buildContent(context, ref, profileState),
        loading: () => const ShimmerProfile(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.warning_2,
                  size: 48, color: AppColors.textHint),
              const SizedBox(height: 16),
              const Text(
                'Failed to load profile',
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    ref.invalidate(currentUserProfileProvider),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, ProfileState profileState) {
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
        // ── White AppBar with settings icon ────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Iconsax.menu_1,
                  color: AppColors.textPrimary, size: 22),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.border),
          ),
        ),

        // ── Avatar + stats row ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar circle
                PremiumAvatar(
                  imageUrl: avatarUrl,
                  name: name,
                  size: 80,
                  isVerified: isVerified,
                ),
                const SizedBox(width: 20),
                // Stats
                Expanded(
                  child: _buildFollowStats(context, ref),
                ),
              ],
            ),
          ),
        ),

        // ── Name, handle, bio, role ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const VerifiedBadge(size: 18),
                    ],
                  ],
                ),
                if (handle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$handle',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Role chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Action buttons row ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Edit Profile',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Share',
                    onTap: () => _shareProfile(context, handle),
                    ghost: true,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Divider ────────────────────────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Divider(height: 1, color: AppColors.border),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatCol(label: 'Campaigns', value: '0'),
        _StatCol(label: 'Followers', value: fmt(followersAsync)),
        _StatCol(label: 'Following', value: fmt(followingAsync)),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
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
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
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
        splashColor: AppColors.primary.withOpacity(0.04),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: AppRadius.allSm,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool ghost;
  const _ActionBtn(
      {required this.label, required this.onTap, this.ghost = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ghost ? Colors.transparent : Colors.white,
          borderRadius: AppRadius.allMd,
          border: Border.all(
            color: ghost ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ghost ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
