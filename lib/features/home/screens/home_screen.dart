import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../messages/providers/messages_provider.dart';
import '../providers/banners_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/featured_campaign_card.dart';

/// Home feed — liquid glass.
///
/// The header is now a **pinned** [GlassAppBar] rather than a header that
/// scrolls away, so the feed visibly refracts through it as you scroll. That is
/// the whole point of the glass language, and it also keeps the wallet,
/// notification and inbox actions permanently reachable.
///
/// Providers, refresh behaviour, routes and the campaign data mapping are
/// unchanged.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);
    final unreadInbox = ref.watch(visibleConversationsProvider).maybeWhen(
          data: (list) => list.where((c) => c['is_read'] == false).length,
          orElse: () => 0,
        );

    // The bar is pinned and content scrolls under it, so the scroll view needs
    // to start below it rather than being padded by the scaffold.
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return GlassScaffold(
      padBodyForAppBar: false,
      appBar: GlassAppBar(
        title: 'Campster',
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleWidget: Text(
          'Campster',
          style: AppTextStyles.title1.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          GlassIconButton(
            icon: AppIcons.wallet_2,
            tooltip: 'Wallet',
            size: 36,
            iconSize: 19,
            onTap: () => context.push(AppRoutes.wallet),
          ),
          GlassIconButton(
            icon: AppIcons.notification,
            tooltip: 'Notifications',
            size: 36,
            iconSize: 19,
            badgeCount: unreadNotifs,
            onTap: () => context.push(AppRoutes.notifications),
          ),
          GlassIconButton(
            icon: AppIcons.message_text,
            tooltip: 'Messages',
            size: 36,
            iconSize: 19,
            badgeCount: unreadInbox,
            onTap: () => context.push(AppRoutes.messages),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        edgeOffset: topInset,
        onRefresh: () async {
          ref.invalidate(featuredCampaignsProvider);
          ref.invalidate(bannersProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topInset)),
            const SliverToBoxAdapter(child: _BannerCarousel()),
            const _FeedList(),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Banner carousel (admin-managed)
// ─────────────────────────────────────────────────────────────────────────

class _BannerCarousel extends ConsumerStatefulWidget {
  const _BannerCarousel();

  @override
  ConsumerState<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<_BannerCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bannerHeight = (width * 0.42).clamp(160.0, 190.0);

    final liveBanners = ref.watch(bannersProvider);
    final dbBanners = liveBanners.value ?? const <Map<String, dynamic>>[];
    if (dbBanners.isEmpty) return const SizedBox.shrink();

    final slideCount = dbBanners.length;

    return Column(
      children: [
        AppSpacing.gapMd,
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: slideCount,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: RepaintBoundary(
                child: _BannerSlide(banner: dbBanners[i]),
              ),
            ),
          ),
        ),
        AppSpacing.gapMd,
        // Brand-red pill for the active page, hairline glass dots otherwise.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slideCount,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _page
                    ? AppColors.primary
                    : AppColors.textPrimary.withOpacity(0.16),
                borderRadius: AppRadius.pillAll,
              ),
            ),
          ),
        ),
        AppSpacing.gapMd,
      ],
    );
  }
}

/// Banner slide framed as a glass card: large radius, hairline rim and the
/// standard glass shadow, so admin artwork sits inside the design system
/// instead of floating as a bare rounded image.
class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner});

  final Map<String, dynamic> banner;

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

    return GlassCard.bare(
      onTap: linkType != 'none' ? onTap : null,
      borderRadius: AppRadius.allLg,
      child: imageUrl.isNotEmpty
          ? CachedImage(
              imageUrl: imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_) => const _BannerFallback(),
              // A plain translucent fill rather than a sized skeleton: the
              // placeholder must stretch to the slide, and GlassSkeleton
              // needs an explicit height.
              placeholderBuilder: (_) => const ColoredBox(
                color: AppColors.surfaceAlt,
              ),
            )
          : const _BannerFallback(),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(AppIcons.gallery, color: AppColors.textHint, size: 30),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Feed list
// ─────────────────────────────────────────────────────────────────────────

class _FeedList extends ConsumerWidget {
  const _FeedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(featuredCampaignsProvider);
    final saved = ref.watch(savedCampaignsProvider).valueOrNull ?? {};

    return async.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: RepaintBoundary(child: _FeedCardSkeleton()),
          ),
          childCount: 3,
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: GlassErrorState(
          message: 'Pull down to retry.',
          onRetry: () => ref.invalidate(featuredCampaignsProvider),
        ),
      ),
      data: (rows) {
        final items = rows.map(_mapCampaign).toList();
        if (items.isEmpty) {
          return const SliverToBoxAdapter(
            child: GlassEmptyState(
              icon: AppIcons.volume_high,
              title: 'No campaigns yet',
              message: 'New campaigns will show up here as brands post them.',
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              // Keeps each card's glass pane from repainting its neighbours
              // while the feed scrolls.
              child: RepaintBoundary(
                child: FeaturedCampaignCard(
                  data: items[index],
                  saved: saved.contains(items[index].id),
                  onToggleSave: () {
                    ref
                        .read(savedCampaignsProvider.notifier)
                        .toggle(items[index].id);
                  },
                  onTap: () => context.push('/campaigns/${items[index].id}'),
                ),
              ),
            ),
            childCount: items.length,
          ),
        );
      },
    );
  }
}

/// Glass skeleton shaped like a [FeaturedCampaignCard].
class _FeedCardSkeleton extends StatelessWidget {
  const _FeedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassCard.bare(
      borderRadius: AppRadius.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassSkeleton(height: 190, borderRadius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlassSkeleton(height: 16),
                AppSpacing.gapSm,
                const GlassSkeleton(width: 180, height: 12),
                AppSpacing.gapMd,
                Row(
                  children: const [
                    GlassSkeleton(width: 70, height: 26),
                    SizedBox(width: 8),
                    GlassSkeleton(width: 70, height: 26),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data mapping helpers (unchanged) ─────────────────────────────────────

FeaturedCampaignData _mapCampaign(Map<String, dynamic> c) {
  int asInt(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0);

  final filled = asInt(c['filled_slots']);
  final total = asInt(c['slots'] ?? c['total_slots']);
  final pct = total > 0 ? ((filled / total) * 100).round().clamp(0, 100) : 0;
  final platform = (c['platform'] ?? '').toString();
  final perCreator = c['payout_per_creator'] ?? c['payoutPerCreator'];

  return FeaturedCampaignData(
    id: (c['id'] ?? '').toString(),
    title: (c['title'] ?? 'Untitled Campaign').toString(),
    category: (c['category'] ?? 'Campaign').toString(),
    imageUrl:
        (c['cover_image'] ?? c['coverImage'] ?? c['cover_image_url'] ?? '')
            .toString(),
    private: c['is_private'] == true || c['hidden'] == true,
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
