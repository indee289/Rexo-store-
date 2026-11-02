import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../admin/providers/is_admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../campaigns/screens/my_campaigns_screen.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_completeness.dart';
import 'edit_profile_screen.dart';

/// Profile screen — liquid glass, rebuilt layout.
///
/// The previous screen was an Instagram clone: a centred-handle top bar with a
/// hairline divider, a horizontal avatar-beside-stats row, bordered white
/// action buttons, a row of outlined circular "highlights", and an
/// underline icon tab bar over a 3-up zero-gutter photo grid.
///
/// None of that structure remains. The layout is now:
///
///   1. collapsing large-title header (no divider, frosts on scroll),
///   2. a glass hero card — large avatar, name + verified badge, role chip,
///      bio — which gives the identity block its own surface instead of
///      competing with the stats,
///   3. followers / following as glass stat pills,
///   4. Edit profile / Share profile as glass buttons,
///   5. Wallet / Campaigns / Admin as a labelled glass tile grid, replacing the
///      outlined circles that had no affordance and clipped their labels,
///   6. a glass segmented control over the campaign grid, replacing the
///      icon-only underline tabs.
///
/// Providers, routes, the share text, the logout flow and the completeness
/// nudge are unchanged.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: profileAsync.when(
        data: (profileState) => _Body(profileState: profileState),
        loading: () => const _ProfileSkeleton(),
        error: (error, _) => CustomScrollView(
          slivers: [
            const GlassLargeTitleHeader(
              title: 'Profile',
              automaticallyImplyLeading: false,
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: GlassErrorState(
                title: 'Failed to load profile',
                onRetry: () => ref.invalidate(currentUserProfileProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profileState});

  final ProfileState profileState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = profileState.profile;
    if (profile == null) {
      return const CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(
            title: 'Profile',
            automaticallyImplyLeading: false,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: GlassEmptyState(
              icon: AppIcons.user,
              title: 'No profile data',
              message: 'We could not read your profile. Try again shortly.',
            ),
          ),
        ],
      );
    }

    final isAdmin = ref.watch(isAdminProvider);
    final name = (profile['name'] ?? 'User').toString();
    final handle = (profile['username'] ?? '').toString();
    final role = (profile['role'] ?? 'creator').toString();
    final avatarUrl = profile['profileImage'] as String?;
    final bio = (profile['bio'] ?? '').toString();
    final isVerified = profile['isVerified'] == true;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        GlassLargeTitleHeader(
          title: name,
          subtitle: handle.isEmpty ? null : '@$handle',
          automaticallyImplyLeading: false,
          actions: [
            GlassIconButton(
              icon: AppIcons.setting_2,
              tooltip: 'Settings',
              size: 36,
              iconSize: 19,
              onTap: () => context.push('/settings'),
            ),
            GlassIconButton(
              icon: AppIcons.logout,
              tooltip: 'Log out',
              size: 36,
              iconSize: 19,
              onTap: () => _confirmLogout(context, ref),
            ),
          ],
        ),

        // 2 — identity hero card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: _HeroCard(
              name: name,
              handle: handle,
              role: role,
              bio: bio,
              avatarUrl: avatarUrl,
              isVerified: isVerified,
            ),
          ),
        ),

        // 3 — stat pills
        const SliverToBoxAdapter(child: _StatPills()),

        // 4 — primary actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'Edit profile',
                    icon: AppIcons.edit,
                    size: GlassButtonSize.small,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: GlassButton.glass(
                    label: 'Share',
                    icon: AppIcons.share,
                    size: GlassButtonSize.small,
                    onPressed: () => _shareProfile(context, handle),
                  ),
                ),
                AppSpacing.gapSm,
                GlassIconButton(
                  icon: AppIcons.user_add,
                  tooltip: 'Linked accounts',
                  size: 38,
                  iconSize: 19,
                  onTap: () => context.push('/linked-accounts'),
                ),
              ],
            ),
          ),
        ),

        // 5 — completeness nudge (hides itself at 100%)
        SliverToBoxAdapter(
          child: ProfileCompletenessCard(
            profile: profile,
            onComplete: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
        ),

        // 6 — shortcut tiles
        SliverToBoxAdapter(
          child: GlassSection(
            title: 'Shortcuts',
            separated: false,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              GlassTileGrid(
                columns: isAdmin ? 3 : 2,
                tiles: [
                  GlassTile(
                    icon: AppIcons.wallet_1,
                    label: 'Wallet',
                    onTap: () => context.push('/wallet'),
                  ),
                  GlassTile(
                    icon: AppIcons.volume_high,
                    label: 'Campaigns',
                    onTap: () => context.push('/my-campaigns'),
                  ),
                  if (isAdmin)
                    GlassTile(
                      icon: AppIcons.shield_tick,
                      label: 'Admin',
                      color: AppColors.accentIndigo,
                      onTap: () => context.push('/admin'),
                    ),
                ],
              ),
            ],
          ),
        ),

        // 7 — segmented control + campaign grid
        const SliverToBoxAdapter(child: _CampaignTabs()),

        // Clear the floating nav dock.
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showGlassConfirm(
      context: context,
      title: 'Log out',
      message: 'Are you sure you want to log out of Campster?',
      icon: AppIcons.logout,
      confirmLabel: 'Log out',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (ok) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  void _shareProfile(BuildContext context, String handle) {
    if (handle.isEmpty) {
      showGlassSnackBar(
        context,
        message: 'Set a username first to share your profile',
        tone: GlassToastTone.warning,
      );
      return;
    }
    // The old link pointed at a domain that does not exist (rexo.app), so it
    // opened nothing. Share a real, working message through the OS share sheet.
    Share.share('Check out @$handle on Campster — influencer marketing, '
        'made simple.');
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 2 — identity hero card
// ─────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.handle,
    required this.role,
    required this.bio,
    required this.avatarUrl,
    required this.isVerified,
  });

  final String name;
  final String handle;
  final String role;
  final String bio;
  final String? avatarUrl;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: AppRadius.allXl,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          _Avatar(imageUrl: avatarUrl, name: name),
          AppSpacing.gapLg,
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
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
          if (handle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '@$handle',
              style: AppTextStyles.subheadline
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          AppSpacing.gapSm,
          GlassChip.status(label: _formatRole(role), color: AppColors.primary),
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
    );
  }

  String _formatRole(String r) {
    if (r.isEmpty) return 'Creator';
    return r[0].toUpperCase() + r.substring(1).toLowerCase();
  }
}

/// Avatar with a brand-gradient ring. No story ring semantics — the ring is
/// purely to lift the avatar off the glass pane behind it.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  static const double _size = 92;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: SizedBox(
          width: _size,
          height: _size,
          child: ClipOval(
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? CachedImage(
                    imageUrl: imageUrl,
                    width: _size,
                    height: _size,
                    fit: BoxFit.cover,
                    errorBuilder: (_) => _InitialFallback(name: name),
                    placeholderBuilder: (_) => _InitialFallback(name: name),
                  )
                : _InitialFallback(name: name),
          ),
        ),
      ),
    );
  }
}

class _InitialFallback extends StatelessWidget {
  const _InitialFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: Text(
          letter,
          style: AppTextStyles.largeTitle.copyWith(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 38,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 3 — stat pills
// ─────────────────────────────────────────────────────────────────────────

class _StatPills extends ConsumerWidget {
  const _StatPills();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followers = ref.watch(currentUserFollowersCountProvider);
    final following = ref.watch(currentUserFollowingCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: GlassStatPill(
              icon: AppIcons.people,
              value: _fmt(followers),
              label: 'Followers',
            ),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: GlassStatPill(
              icon: AppIcons.user_add,
              value: _fmt(following),
              label: 'Following',
            ),
          ),
        ],
      ),
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

// ─────────────────────────────────────────────────────────────────────────
// 7 — segmented control + campaign grid
// ─────────────────────────────────────────────────────────────────────────

class _CampaignTabs extends ConsumerStatefulWidget {
  const _CampaignTabs();

  @override
  ConsumerState<_CampaignTabs> createState() => _CampaignTabsState();
}

class _CampaignTabsState extends ConsumerState<_CampaignTabs> {
  int _tab = 0; // 0 = my campaigns, 1 = saved

  @override
  Widget build(BuildContext context) {
    final async = _tab == 0
        ? ref.watch(myCampaignsListProvider)
        : ref.watch(savedCampaignsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Labelled segmented control, replacing the two icon-only underline
        // tabs that gave no indication of what they switched between.
        GlassTabBar(
          labels: const ['My campaigns', 'Saved'],
          selectedIndex: _tab,
          onSelected: (i) => setState(() => _tab = i),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        AppSpacing.gapSm,
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: GlassLoader(),
          ),
          error: (_, __) => GlassErrorState(
            compact: true,
            title: _tab == 1
                ? 'Could not load saved campaigns'
                : 'Could not load campaigns',
            onRetry: () => ref.invalidate(
              _tab == 0 ? myCampaignsListProvider : savedCampaignsListProvider,
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return GlassEmptyState(
                compact: true,
                icon: _tab == 1 ? AppIcons.bookmark : AppIcons.volume_high,
                title: _tab == 1
                    ? 'No saved campaigns yet'
                    : 'No campaigns yet',
                message: _tab == 1
                    ? 'Campaigns you bookmark will appear here.'
                    : 'Campaigns you post will appear here.',
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  // Real gutters: the old grid used 2px seams, which only
                  // works for edge-to-edge photos, not glass tiles.
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.84,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => RepaintBoundary(
                  child: _CampaignTile(campaign: items[i]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Campaign thumbnail as a glass tile with its title on a readable scrim.
class _CampaignTile extends StatelessWidget {
  const _CampaignTile({required this.campaign});

  final Map<String, dynamic> campaign;

  @override
  Widget build(BuildContext context) {
    final id = (campaign['id'] ?? '').toString();
    final cover = (campaign['cover_image'] ??
            campaign['coverImage'] ??
            campaign['cover_image_url'] ??
            '')
        .toString();
    final title = (campaign['title'] ?? 'Campaign').toString();

    return GlassCard.bare(
      borderRadius: AppRadius.allSm,
      onTap: id.isEmpty ? null : () => context.push('/campaigns/$id'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover.isNotEmpty)
            CachedImage(
              imageUrl: cover,
              fit: BoxFit.cover,
              errorBuilder: (_) => const ColoredBox(
                color: AppColors.surfaceAlt,
              ),
              placeholderBuilder: (_) => const ColoredBox(
                color: AppColors.surfaceAlt,
              ),
            )
          else
            const ColoredBox(color: AppColors.surfaceAlt),
          // Title always legible, regardless of the artwork behind it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 22, 10, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.78),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const GlassLargeTitleHeader(
          title: 'Profile',
          automaticallyImplyLeading: false,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                GlassCard(
                  borderRadius: AppRadius.allXl,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: const [
                      GlassSkeleton(
                        width: 98,
                        height: 98,
                        borderRadius: AppRadius.pillAll,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      GlassSkeleton(width: 160, height: 20),
                      SizedBox(height: AppSpacing.sm),
                      GlassSkeleton(width: 110, height: 13),
                      SizedBox(height: AppSpacing.lg),
                      GlassSkeleton(height: 12),
                      SizedBox(height: 6),
                      GlassSkeleton(width: 220, height: 12),
                    ],
                  ),
                ),
                AppSpacing.gapLg,
                Row(
                  children: const [
                    Expanded(child: GlassSkeleton(height: 72)),
                    SizedBox(width: AppSpacing.md),
                    Expanded(child: GlassSkeleton(height: 72)),
                  ],
                ),
                AppSpacing.gapLg,
                Row(
                  children: const [
                    Expanded(child: GlassSkeleton(height: 38)),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(child: GlassSkeleton(height: 38)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
