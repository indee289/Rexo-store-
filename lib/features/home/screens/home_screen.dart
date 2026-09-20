import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../messages/providers/messages_provider.dart';
import '../providers/banners_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/featured_campaign_card.dart';

/// Home screen — matches the provided reference:
/// a clean header (Home title + wallet / bell / inbox actions), a compact
/// violet campaign banner carousel with dots, and a "Featured Campaigns"
/// vertical list. No search, no categories, no products, no greeting.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(featuredCampaignsProvider),
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const _HomeHeader(),
              const SizedBox(height: 8),
              const _BannerCarousel(),
              const SizedBox(height: 20),
              const _FeaturedHeader(),
              const SizedBox(height: 12),
              _FeaturedList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);
    final unreadInbox = ref.watch(conversationsProvider).maybeWhen(
          data: (list) =>
              list.where((c) => c['is_read'] == false).length,
          orElse: () => 0,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            'Home',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _HeaderIconButton(
            icon: Iconsax.wallet_2,
            onTap: () => context.push(AppRoutes.wallet),
          ),
          const SizedBox(width: 10),
          _HeaderIconButton(
            icon: Iconsax.notification,
            badge: unreadNotifs,
            onTap: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(width: 10),
          _HeaderIconButton(
            icon: Iconsax.sms,
            badge: unreadInbox,
            onTap: () => context.push(AppRoutes.messages),
          ),
        ],
      ),
    );
  }
}

/// Rounded white icon button with an optional unread count badge.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: cs.onSurface),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.pillAll,
                  border: Border.all(color: bg, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
// Banner carousel — uses live DB banners with static fallback
// ─────────────────────────────────────────────────────────────────────────
class _BannerSlideData {
  final String title;
  final String subtitle;
  const _BannerSlideData(this.title, this.subtitle);
}

class _BannerCarousel extends ConsumerStatefulWidget {
  const _BannerCarousel();

  @override
  ConsumerState<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<_BannerCarousel> {
  final _controller = PageController();
  int _page = 0;

  static const _fallbackSlides = [
    _BannerSlideData('Create Content.\nEarn Rewards.',
        'Collaborate with top brands\nand grow your influence.'),
    _BannerSlideData('Top Brands\nAwait You.',
        'Join campaigns from leading\nbrands and start earning.'),
    _BannerSlideData('Grow Your\nInfluence.',
        'Turn your creativity into\nreal, rewarding collaborations.'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Height reduced by 15% from original
    final width = MediaQuery.of(context).size.width;
    final bannerHeight = (width * 0.391).clamp(151.0, 177.0);

    // Use live DB banners if available, else fallback to static slides
    final liveBanners = ref.watch(bannersProvider);
    final useDbBanners = liveBanners.value != null &&
        liveBanners.value!.isNotEmpty;
    final dbBanners = liveBanners.value ?? [];
    final slideCount = useDbBanners ? dbBanners.length : _fallbackSlides.length;

    return Column(
      children: [
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: slideCount,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: useDbBanners
                  ? _DbBannerSlide(banner: dbBanners[i])
                  : _BannerSlide(data: _fallbackSlides[i]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slideCount,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _page
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.22),
                borderRadius: AppRadius.pillAll,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final _BannerSlideData data;
  const _BannerSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.allLg,
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            // Decorative artwork on the right
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: _BannerArt(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 21,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // Explore button
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.campaigns),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.pillAll,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Explore Campaigns',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Iconsax.arrow_right_3,
                              size: 16, color: AppColors.primaryDeep),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A DB banner slide — shows the uploaded image and handles tap navigation.
class _DbBannerSlide extends StatelessWidget {
  final Map<String, dynamic> banner;
  const _DbBannerSlide({required this.banner});

  @override
  Widget build(BuildContext context) {
    final imageUrl = banner['image_url'] as String? ?? '';
    final linkType = banner['link_type'] as String? ?? 'none';
    final campaignId = banner['link_campaign_id'] as String?;
    final page = banner['link_page'] as String?;

    void onTap() {
      if (linkType == 'campaign' && campaignId != null) {
        context.push('/campaigns/$campaignId');
      } else if (linkType == 'page' && page != null && page.isNotEmpty) {
        context.push(page);
      }
    }

    return GestureDetector(
      onTap: linkType != 'none' ? onTap : null,
      child: ClipRRect(
        borderRadius: AppRadius.allLg,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackContainer(),
              )
            : _fallbackContainer(),
      ),
    );
  }

  Widget _fallbackContainer() => Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      );
}

/// Lightweight decorative artwork (gift + megaphone-ish speaker + badges)
/// from icons so it needs no image asset while keeping the campaign vibe.
class _BannerArt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget circle(double size, double opacity) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );

    Widget bubble(IconData icon, Color color) => Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 14, color: color),
        );

    return SizedBox(
      width: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(right: 8, bottom: 14, child: circle(96, 0.10)),
          Positioned(right: 60, top: 26, child: circle(26, 0.14)),
          const Center(
            child: Icon(Iconsax.gift, size: 64, color: Colors.white),
          ),
          Positioned(top: 22, right: 14, child: bubble(Iconsax.heart, AppColors.accentPink)),
          Positioned(bottom: 30, right: 66, child: bubble(Iconsax.star_1, AppColors.accentAmber)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Featured campaigns
// ─────────────────────────────────────────────────────────────────────────
class _FeaturedHeader extends StatelessWidget {
  const _FeaturedHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Featured Campaigns',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go(AppRoutes.campaigns),
            behavior: HitTestBehavior.opaque,
            child: const Row(
              children: [
                Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Iconsax.arrow_right_3, size: 15, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(featuredCampaignsProvider);
    final saved = ref.watch(savedCampaignsProvider);

    return async.when(
      loading: () => Column(
        children: [
          for (int i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ShimmerCard(height: 90),
            ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (rows) {
        final items = rows.map(_mapCampaign).toList();
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Center(
              child: Text(
                'No campaigns yet',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final data in items)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FeaturedCampaignCard(
                  data: data,
                  saved: saved.contains(data.id),
                  onToggleSave: () {
                    final notifier = ref.read(savedCampaignsProvider.notifier);
                    final next = Set<String>.from(notifier.state);
                    if (!next.add(data.id)) next.remove(data.id);
                    notifier.state = next;
                  },
                  onTap: () => context.push('/campaigns/${data.id}'),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Mapping + sample data ─────────────────────────────────────────────────
FeaturedCampaignData _mapCampaign(Map<String, dynamic> c) {
  int asInt(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0);

  final filled = asInt(c['filled_slots']);
  final total = asInt(c['total_slots']);
  final pct = total > 0 ? ((filled / total) * 100).round().clamp(0, 100) : 0;
  final platform = (c['platform'] ?? '').toString();
  final perCreator = c['per_creator_payout'];

  return FeaturedCampaignData(
    id: (c['id'] ?? '').toString(),
    title: (c['title'] ?? 'Untitled Campaign').toString(),
    category: (c['category'] ?? 'Campaign').toString(),
    imageUrl: (c['cover_image_url'] ?? '').toString(),
    private: c['is_private'] == true,
    platforms: platform.isEmpty ? const [] : [platform],
    paidOutPercent: pct,
    budgetText: _money(c['budget']),
    rateText: _rate(perCreator),
  );
}

String _grouped(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _money(dynamic value) {
  final v = double.tryParse('${value ?? ''}') ?? 0;
  return '₹${_grouped(v)}';
}

String _rate(dynamic value) {
  final v = double.tryParse('${value ?? ''}') ?? 0;
  if (v <= 0) return '—';
  return '₹${_grouped(v)}';
}

// ── Mapping helpers ───────────────────────────────────────────────────────
