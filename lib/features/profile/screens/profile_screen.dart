import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../admin/providers/is_admin_provider.dart';
import '../providers/profile_provider.dart';
import '../../campaigns/providers/campaigns_provider.dart';
import 'edit_profile_screen.dart';

/// Redesigned Profile — "Cover Hero" layout.
///
/// Emerald gradient hero panel with a big centered avatar sits at the top.
/// A white sheet with a large top-radius overlaps it, hosting the stat row,
/// primary actions, and a grid of colored feature tiles.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: profileAsync.when(
        data: (profileState) => _Body(profileState: profileState),
        loading: () => const ShimmerProfile(),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.invalidate(currentUserProfileProvider),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final ProfileState profileState;

  const _Body({required this.profileState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = profileState.profile;
    if (profile == null) {
      return const Center(child: Text('No profile data'));
    }

    final isAdmin = ref.watch(isAdminProvider);
    final name = (profile['name'] ?? 'User').toString();
    final handle = (profile['username'] ?? '').toString();
    final role = (profile['role'] ?? 'creator').toString();
    final avatarUrl = profile['profileImage'] as String?;
    final bio = (profile['bio'] ?? '').toString();
    final isVerified = profile['isVerified'] == true;

    return Stack(
      children: [
        // 1. Emerald hero panel
        _CoverHero(
          name: name,
          handle: handle,
          role: role,
          avatarUrl: avatarUrl,
          bio: bio,
          isVerified: isVerified,
          onSettingsTap: () => context.push('/settings'),
        ),

        // 2. Scrollable content over the hero
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Spacer for the hero region
                const SizedBox(height: 320),

                // Overlapping white sheet
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Stat row
                      _StatsRow(),
                      const SizedBox(height: 24),

                      // Action buttons
                      _ActionRow(
                        handle: handle,
                      ),
                      const SizedBox(height: 32),

                      // Section header
                      _SectionHeader('QUICK ACCESS'),
                      const SizedBox(height: 12),

                      // Feature tile grid
                      _FeatureGrid(isAdmin: isAdmin),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover Hero
// ─────────────────────────────────────────────────────────────────────────────

class _CoverHero extends StatelessWidget {
  final String name;
  final String handle;
  final String role;
  final String? avatarUrl;
  final String bio;
  final bool isVerified;
  final VoidCallback onSettingsTap;

  const _CoverHero({
    required this.name,
    required this.handle,
    required this.role,
    required this.avatarUrl,
    required this.bio,
    required this.isVerified,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF10B981),
            Color(0xFF047857),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -40,
            right: -60,
            child: _Blob(
              size: 200,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Positioned(
            top: 60,
            left: -80,
            child: _Blob(
              size: 240,
              color: Colors.white.withOpacity(0.08),
            ),
          ),

          // Top action row
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _CircleGlassButton(
                    icon: Iconsax.setting_2,
                    onTap: onSettingsTap,
                  ),
                ],
              ),
            ),
          ),

          // Avatar + name block
          Positioned.fill(
            top: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Avatar with ring
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                            ? Image.network(
                                avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _InitialAvatar(name: name),
                              )
                            : _InitialAvatar(name: name),
                      ),
                    ),
                    if (isVerified)
                      const Positioned(
                        right: -4,
                        bottom: -4,
                        child: VerifiedBadge(size: 28),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Handle
                if (handle.isNotEmpty)
                  Text(
                    '@$handle',
                    style: AppTextStyles.callout.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                const SizedBox(height: 10),

                // Role pill
                _RolePill(role: role),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _CircleGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleGlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;

  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTextStyles.largeTitle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 44,
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String role;

  const _RolePill({required this.role});

  @override
  Widget build(BuildContext context) {
    final label =
        role.isEmpty ? 'Creator' : role[0].toUpperCase() + role.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.crown_1, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.footnote.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row (3 colored pill cards)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(currentUserCampaignsCountProvider);
    final followers = ref.watch(currentUserFollowersCountProvider);
    final following = ref.watch(currentUserFollowingCountProvider);

    return Row(
      children: [
        Expanded(
          child: _StatPill(
            label: 'Campaigns',
            value: _fmt(campaigns),
            color: AppColors.primary,
            bgColor: AppColors.primaryBg,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            label: 'Followers',
            value: _fmt(followers),
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            label: 'Following',
            value: _fmt(following),
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
        ),
      ],
    );
  }

  String _fmt(AsyncValue<int> v) => v.when(
        data: (c) {
          if (c >= 1000000) return '${(c / 1000000).toStringAsFixed(1)}M';
          if (c >= 1000) return '${(c / 1000).toStringAsFixed(1)}K';
          return c.toString();
        },
        loading: () => '—',
        error: (_, __) => '0',
      );
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.allLg,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.title2.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: color.withOpacity(0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action row
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final String handle;

  const _ActionRow({required this.handle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _PrimaryActionButton(
            label: 'Edit Profile',
            icon: Iconsax.edit_2,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SecondaryActionButton(
          icon: Iconsax.share,
          onTap: () => _shareProfile(context, handle),
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
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
    );
  }
}

class _PrimaryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.allLg,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTextStyles.headline.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryActionButton({required this.icon, required this.onTap});

  @override
  State<_SecondaryActionButton> createState() =>
      _SecondaryActionButtonState();
}

class _SecondaryActionButtonState extends State<_SecondaryActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primaryBg,
            borderRadius: AppRadius.allLg,
          ),
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            color: AppColors.primaryDeep,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature grid
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: AppTextStyles.footnote.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final bool isAdmin;

  const _FeatureGrid({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _FeatureTile(
        title: 'Wallet',
        subtitle: 'Balance & pay',
        icon: Iconsax.wallet_1,
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => context.push('/wallet'),
      ),
      _FeatureTile(
        title: 'Subscriptions',
        subtitle: 'Your plan',
        icon: Iconsax.crown_1,
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => context.push('/subscriptions'),
      ),
      if (isAdmin)
        _FeatureTile(
          title: 'Admin Center',
          subtitle: 'Platform ops',
          icon: Iconsax.shield_tick,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF87171)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin'),
        ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: tiles,
    );
  }
}

class _FeatureTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: AppRadius.allLg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon in white circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Text(
                widget.title,
                style: AppTextStyles.headline.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: AppTextStyles.footnote.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.warning_2, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Failed to load profile',
              style: AppTextStyles.callout
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
