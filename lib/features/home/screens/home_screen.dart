import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../messages/providers/messages_provider.dart';
import '../providers/banners_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/featured_campaign_card.dart';

/// Instagram-style Home feed — no stories row.
///
/// Top: 'Rexo' logo left-aligned + wallet/heart/DM icons right, hairline
/// separator, banner carousel (admin-managed), and a vertical feed of
/// featured campaign cards.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(featuredCampaignsProvider);
            ref.invalidate(bannersProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Sticky Instagram-style header
              const SliverToBoxAdapter(child: _IgHeader()),

              // Hairline separator under header
              const SliverToBoxAdapter(
                child: Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: AppColors.border,
                ),
              ),

              // Banner carousel (admin-managed banners)
              const SliverToBoxAdapter(child: _BannerCarousel()),

              // Feed
              _FeedList(),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Instagram top header
// ─────────────────────────────────────────────────────────────────────────

class _IgHeader extends ConsumerWidget {
  const _IgHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);
    final unreadInbox = ref.watch(conversationsProvider).maybeWhen(
          data: (list) => list.where((c) => c['is_read'] == false).length,
          orElse: () => 0,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      child: Row(
        children: [
          // Rexo "logo" — bold left-aligned wordmark
          Text(
            'Rexo',
            style: AppTextStyles.largeTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _HeaderIcon(
            icon: Iconsax.wallet_2,
            onTap: () => context.push(AppRoutes.wallet),
          ),
          const SizedBox(width: 4),
          _HeaderIcon(
            icon: Iconsax.notification,
            badge: unreadNotifs,
            onTap: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(width: 4),
          _HeaderIcon(
            icon: Iconsax.send_2,
            badge: unreadInbox,
            onTap: () => context.push(AppRoutes.messages),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatefulWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  @override
  State<_HeaderIcon> createState() => _HeaderIconState();
}

class _HeaderIconState extends State<_HeaderIcon> {
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(widget.icon,
                  size: 26, color: AppColors.textPrimary),
            ),
            if (widget.badge > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: AppColors.accentPink,
                    borderRadius: AppRadius.pillAll,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.badge > 99 ? '99+' : '${widget.badge}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
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
        const SizedBox(height: 12),
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: slideCount,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DbBannerSlide(banner: dbBanners[i]),
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
              width: i == _page ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _page
                    ? AppColors.textPrimary
                    : AppColors.systemGray4,
                borderRadius: AppRadius.pillAll,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

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
        color: AppColors.surfaceAlt,
        child: const Center(
          child: Icon(Iconsax.gallery,
              color: AppColors.textSecondary, size: 32),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Feed list (Instagram-style vertical posts)
// ─────────────────────────────────────────────────────────────────────────

class _FeedList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(featuredCampaignsProvider);
    final saved = ref.watch(savedCampaignsProvider);

    return async.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ShimmerCard(height: 320),
          ),
          childCount: 3,
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (rows) {
        final items = rows.map(_mapCampaign).toList();
        if (items.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 40, 20, 40),
              child: Center(
                child: Text(
                  'No campaigns yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FeaturedCampaignCard(
                data: items[index],
                saved: saved.contains(items[index].id),
                onToggleSave: () {
                  final notifier =
                      ref.read(savedCampaignsProvider.notifier);
                  final next = Set<String>.from(notifier.state);
                  if (!next.add(items[index].id)) {
                    next.remove(items[index].id);
                  }
                  notifier.state = next;
                },
                onTap: () => context.push('/campaigns/${items[index].id}'),
              ),
            ),
            childCount: items.length,
          ),
        );
      },
    );
  }
}

// ── Data mapping helpers ─────────────────────────────────────────────────

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
