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
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_completeness.dart';
import '../../campaigns/providers/campaigns_provider.dart';
import '../../campaigns/screens/my_campaigns_screen.dart';
import 'edit_profile_screen.dart';

/// Instagram-style Profile screen.
///
/// White background. Top: back arrow + username center + settings/menu right.
/// Below: horizontal row of [avatar | Campaigns | Followers | Following] with
/// stats. Then: name (bold), role/handle line, bio. Then: full-width
/// [Edit Profile | Share Profile] bordered buttons. Then: story highlights.
/// Then: tab bar (Grid / Applications / Saved) and content below.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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

// ─────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────

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

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Instagram top bar with username centered
          SliverToBoxAdapter(
            child: _TopBar(handle: handle.isEmpty ? name : handle),
          ),
          const SliverToBoxAdapter(
            child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: AppColors.border,
            ),
          ),

          // Avatar + stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  _Avatar(imageUrl: avatarUrl, name: name),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StatsRow(),
                  ),
                ],
              ),
            ),
          ),

          // Name + role/handle + bio
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatRole(role),
                    style: AppTextStyles.subheadline.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      bio,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action buttons row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _IgButton(
                      label: 'Edit profile',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _IgButton(
                      label: 'Share profile',
                      onTap: () => _shareProfile(context, handle),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _IgIconButton(
                    icon: Iconsax.user_add,
                    onTap: () => context.push('/linked-accounts'),
                  ),
                ],
              ),
            ),
          ),

          // Profile completeness nudge (hidden when 100% complete)
          SliverToBoxAdapter(
            child: ProfileCompletenessCard(
              profile: profile,
              onComplete: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
          ),

          // Story highlights row
          SliverToBoxAdapter(
            child: _HighlightsRow(isAdmin: isAdmin),
          ),

          const SliverToBoxAdapter(
            child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: AppColors.border,
            ),
          ),

          // Tabs (Grid = my campaigns, Saved = bookmarked) + content
          const SliverToBoxAdapter(child: _ProfileTabsSection()),
        ],
      ),
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
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
    );
  }

  String _formatRole(String r) {
    if (r.isEmpty) return 'Creator';
    return r[0].toUpperCase() + r.substring(1).toLowerCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Top bar (Instagram: back arrow / handle centered / menu right)
// ─────────────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final String handle;
  const _TopBar({required this.handle});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of Campster?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Row(
        children: [
          const SizedBox(width: 96), // symmetric spacer (2 right icons)
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.lock,
                      size: 14, color: AppColors.textPrimary),
                  const SizedBox(width: 4),
                  Text(
                    handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _TopBarIcon(
            icon: Iconsax.setting_2,
            onTap: () => context.push('/settings'),
          ),
          _TopBarIcon(
            icon: Iconsax.logout,
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _TopBarIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarIcon({required this.icon, required this.onTap});

  @override
  State<_TopBarIcon> createState() => _TopBarIconState();
}

class _TopBarIconState extends State<_TopBarIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.4 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(widget.icon, size: 24, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Avatar (no story ring in profile header — matches IG's own profile)
// ─────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  const _Avatar({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialFallback(),
              )
            : _initialFallback(),
      ),
    );
  }

  Widget _initialFallback() {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      color: AppColors.surfaceAlt,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTextStyles.largeTitle.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 36,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Stats row (Campaigns / Followers / Following)
// ─────────────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followers = ref.watch(currentUserFollowersCountProvider);
    final following = ref.watch(currentUserFollowingCountProvider);

    return Row(
      children: [
        Expanded(child: _Stat(value: _fmt(followers), label: 'Followers')),
        Expanded(child: _Stat(value: _fmt(following), label: 'Following')),
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

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.title2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTextStyles.footnote.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Instagram bordered action buttons
// ─────────────────────────────────────────────────────────────────────────

class _IgButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _IgButton({required this.label, required this.onTap});

  @override
  State<_IgButton> createState() => _IgButtonState();
}

class _IgButtonState extends State<_IgButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _IgIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IgIconButton({required this.icon, required this.onTap});

  @override
  State<_IgIconButton> createState() => _IgIconButtonState();
}

class _IgIconButtonState extends State<_IgIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Highlights row (Wallet / Subs / Admin as IG-style circular highlights)
// ─────────────────────────────────────────────────────────────────────────

class _HighlightsRow extends StatelessWidget {
  final bool isAdmin;
  const _HighlightsRow({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final items = <_HighlightData>[
      _HighlightData(
        icon: Iconsax.wallet_1,
        label: 'Wallet',
        onTap: () => context.push('/wallet'),
      ),
      _HighlightData(
        icon: Iconsax.send_2,
        label: 'Campaigns',
        onTap: () => context.push('/my-campaigns'),
      ),
      if (isAdmin)
        _HighlightData(
          icon: Iconsax.shield_tick,
          label: 'Admin',
          onTap: () => context.push('/admin'),
        ),
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _HighlightCircle(data: items[index]),
      ),
    );
  }
}

class _HighlightData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _HighlightData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _HighlightCircle extends StatefulWidget {
  final _HighlightData data;
  const _HighlightCircle({required this.data});

  @override
  State<_HighlightCircle> createState() => _HighlightCircleState();
}

class _HighlightCircleState extends State<_HighlightCircle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.data.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.data.icon,
                  size: 26,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Text(
                  widget.data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Profile tabs: Grid (my campaigns) + Saved (bookmarked campaigns)
// ─────────────────────────────────────────────────────────────────────────

class _ProfileTabsSection extends ConsumerStatefulWidget {
  const _ProfileTabsSection();

  @override
  ConsumerState<_ProfileTabsSection> createState() =>
      _ProfileTabsSectionState();
}

class _ProfileTabsSectionState extends ConsumerState<_ProfileTabsSection> {
  int _tab = 0; // 0 = grid (my campaigns), 1 = saved

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),
        // Tab bar — Grid + Saved only (Tag removed)
        SizedBox(
          height: 44,
          child: Row(
            children: [
              _tabIcon(Iconsax.category, 0),
              _tabIcon(Iconsax.bookmark, 1),
            ],
          ),
        ),
        const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),
        // Content
        if (_tab == 0) _buildGrid(ref.watch(myCampaignsListProvider), isSaved: false)
        else _buildGrid(ref.watch(savedCampaignsListProvider), isSaved: true),
      ],
    );
  }

  Widget _tabIcon(IconData icon, int index) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = index),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.textPrimary : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon,
              size: 22,
              color: active ? AppColors.textPrimary : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildGrid(AsyncValue<List<Map<String, dynamic>>> async,
      {required bool isSaved}) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => _emptyState(
        isSaved ? 'Could not load saved campaigns' : 'Could not load campaigns',
        'Pull down to refresh and try again.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return _emptyState(
            isSaved ? 'No saved campaigns yet' : 'Share your first campaign',
            isSaved
                ? 'Campaigns you bookmark will appear here.'
                : 'Your posted campaigns will appear on your profile.',
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(2),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _GridTile(campaign: items[i]),
        );
      },
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textPrimary, width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Icon(Iconsax.camera,
                size: 30, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.title2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.subheadline
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// A single campaign thumbnail in the profile grid.
class _GridTile extends StatelessWidget {
  final Map<String, dynamic> campaign;
  const _GridTile({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final id = (campaign['id'] ?? '').toString();
    final cover = (campaign['cover_image'] ??
            campaign['coverImage'] ??
            campaign['cover_image_url'] ??
            '')
        .toString();
    final title = (campaign['title'] ?? 'Campaign').toString();

    return GestureDetector(
      onTap: () {
        if (id.isNotEmpty) context.push('/campaigns/$id');
      },
      child: Container(
        color: AppColors.surfaceAlt,
        child: cover.isNotEmpty
            ? Image.network(
                cover,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(title),
              )
            : _placeholder(title),
      ),
    );
  }

  Widget _placeholder(String title) {
    return Container(
      color: AppColors.surfaceAlt,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption1.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textPrimary, width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Icon(Iconsax.warning_2,
                size: 36, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: AppTextStyles.title2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
