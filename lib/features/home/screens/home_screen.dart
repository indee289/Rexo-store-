import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/campaign_card.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../services/supabase_service.dart';
import '../providers/home_provider.dart';
import '../widgets/category_chips.dart';

/// Home screen — modern store-style composition:
/// pill search bar, a featured banner carousel with page dots, a horizontal
/// "Top Creators" circle row, category filter chips, and a 2-column campaign
/// card grid. Fully theme-aware (light + dark). All providers/data/navigation
/// are unchanged; the search field filters the already-fetched lists locally.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _query = '';

  // ── Theme-aware color helpers ────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg =>
      _isDark ? AppColors.darkBackground : AppColors.background;
  Color get _cardBg => _isDark ? AppColors.darkCard : Colors.white;
  Color get _borderColor =>
      _isDark ? AppColors.darkBorder : AppColors.border;
  Color get _surfaceAlt =>
      _isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
  Color get _textPrimary =>
      _isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get _textHint => _isDark ? AppColors.darkTextHint : AppColors.textHint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(featuredCampaignsProvider);
            ref.invalidate(trendingCreatorsProvider);
            ref.invalidate(recentCampaignsProvider);
            ref.invalidate(homeUserProfileProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    _buildSearchBar(),
                    _buildEmailBanner(),
                    const SizedBox(height: 4),
                    _buildBannerCarousel(),
                    const SizedBox(height: 8),
                    _buildCreatorsSection(),
                    const SizedBox(height: 4),
                    const CategoryChips(),
                    const SizedBox(height: 8),
                    SectionHeader(
                      title: 'Campaigns',
                      actionLabel: 'See all',
                      onAction: () => context.push(AppRoutes.campaigns),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    ),
                    _buildCampaignsGrid(),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar: logo + name, notifications + avatar ──────────────────────────
  Widget _buildTopBar() {
    final profileAsync = ref.watch(homeUserProfileProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.crown_1, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Text(
            'Rexo',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _circleIcon(
            icon: Iconsax.notification,
            onTap: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(width: 10),
          profileAsync.maybeWhen(
            data: (p) => GestureDetector(
              onTap: () => context.push(AppRoutes.profile),
              child: PremiumAvatar(
                imageUrl: p?['avatar_url'],
                name: p?['name'] ?? '',
                size: 38,
              ),
            ),
            orElse: () => const SizedBox(width: 38, height: 38),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _cardBg,
          shape: BoxShape.circle,
          border: Border.all(color: _borderColor),
        ),
        child: Icon(icon, size: 20, color: _textPrimary),
      ),
    );
  }

  // ── Search pill ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: AppRadius.pillAll,
        ),
        child: Row(
          children: [
            Icon(Iconsax.search_normal, size: 20, color: _textHint),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: 14, color: _textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search campaigns, creators…',
                  hintStyle: TextStyle(fontSize: 14, color: _textHint),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _query = ''),
                child: Icon(Iconsax.close_circle, size: 18, color: _textHint),
              ),
          ],
        ),
      ),
    );
  }

  // ── Featured banner carousel ──────────────────────────────────────────────
  Widget _buildBannerCarousel() {
    final async = ref.watch(featuredCampaignsProvider);
    return async.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return _BannerCarousel(
          campaigns: list.take(5).toList(),
          onTap: (id) => context.push('/campaigns/$id'),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerCard(height: 168, borderRadius: 28),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  // ── Top creators (horizontal circle row) ──────────────────────────────────
  Widget _buildCreatorsSection() {
    final async = ref.watch(trendingCreatorsProvider);
    return async.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Top Creators',
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            ),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, i) => _creatorCircle(list[i]),
              ),
            ),
          ],
        );
      },
      loading: () => SizedBox(
        height: 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, __) => const ShimmerCircle(size: 64),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _creatorCircle(Map<String, dynamic> creator) {
    final userData = creator['users'] as Map<String, dynamic>?;
    final name = (userData?['name'] ?? 'Creator').toString();
    final avatarUrl = (userData?['avatar_url'] ?? '').toString();
    final isVerified = (userData?['is_verified'] == true);
    final id = creator['user_id']?.toString();

    return GestureDetector(
      onTap: () {
        if (id != null) context.push('/creators/$id');
      },
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            PremiumAvatar(
              imageUrl: avatarUrl.isEmpty ? null : avatarUrl,
              name: name,
              size: 64,
              isVerified: isVerified,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Campaigns 2-column grid ───────────────────────────────────────────────
  Widget _buildCampaignsGrid() {
    final async = ref.watch(recentCampaignsProvider);
    return async.when(
      data: (list) {
        final filtered = _query.isEmpty
            ? list
            : list.where((c) {
                final t = (c['title'] ?? '').toString().toLowerCase();
                final b = (c['brand_name'] ?? '').toString().toLowerCase();
                return t.contains(_query.toLowerCase()) ||
                    b.contains(_query.toLowerCase());
              }).toList();

        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Iconsax.search_normal,
            title: 'No campaigns found',
            subtitle: 'Try a different search or category.',
          );
        }

        final cellWidth =
            (MediaQuery.of(context).size.width - 32 - 12) / 2;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (int i = 0; i < filtered.length; i++)
                SizedBox(
                  width: cellWidth,
                  child: CampaignCard(
                    campaign: filtered[i],
                    onTap: () {
                      final id = filtered[i]['id']?.toString();
                      if (id != null) context.push('/campaigns/$id');
                    },
                  ).staggeredEntrance(i),
                ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(4, (_) => const ShimmerCreatorCard()),
        ),
      ),
      error: (_, __) => _errorState('Failed to load campaigns'),
    );
  }

  Widget _buildEmailBanner() {
    try {
      final user = SupabaseService.currentUser;
      if (user == null || user.emailConfirmedAt != null) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.10),
          borderRadius: AppRadius.allMd,
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Iconsax.sms, color: AppColors.warning, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Please verify your email to unlock all features.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _errorState(String msg) => EmptyState(
        icon: Iconsax.warning_2,
        title: msg,
        subtitle: 'Please try again.',
        cta: PremiumButton(
          label: 'Retry',
          icon: Iconsax.refresh,
          variant: PremiumButtonVariant.tonal,
          expand: false,
          onPressed: () {
            ref.invalidate(featuredCampaignsProvider);
            ref.invalidate(trendingCreatorsProvider);
            ref.invalidate(recentCampaignsProvider);
            ref.invalidate(homeUserProfileProvider);
          },
        ),
      );
}

/// Swipeable featured-campaign banner with page dots.
class _BannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> campaigns;
  final ValueChanged<String> onTap;

  const _BannerCarousel({required this.campaigns, required this.onTap});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.campaigns.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _HeroBanner(
                campaign: widget.campaigns[i],
                onTap: widget.onTap,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.campaigns.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _page
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.25),
                borderRadius: AppRadius.pillAll,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final ValueChanged<String> onTap;

  const _HeroBanner({required this.campaign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (campaign['title'] ?? 'Featured Campaign').toString();
    final cover = (campaign['cover_image_url'] ?? '').toString();
    final id = campaign['id']?.toString();
    final brand = _brandName();

    return GestureDetector(
      onTap: () {
        if (id != null) onTap(id);
      },
      child: ClipRRect(
        borderRadius: AppRadius.allXl,
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'FEATURED CAMPAIGN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (brand.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (cover.isNotEmpty)
                CachedImage(
                  imageUrl: cover,
                  width: 130,
                  height: 168,
                  fit: BoxFit.cover,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _brandName() {
    final users = campaign['users'];
    if (users is Map && users['name'] != null) return users['name'].toString();
    final b = campaign['brand_name'];
    return (b == null) ? '' : b.toString();
  }
}
