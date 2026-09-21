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
import '../../profile/providers/profile_provider.dart';
import '../providers/banners_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/featured_campaign_card.dart';

/// Redesigned Home — "Personalized Hero" layout.
///
/// Emerald gradient greeting card at top with the user's name, a floating
/// action row of quick-access pills (Wallet / Notifications / Messages), a
/// banner carousel, and a Featured Campaigns feed below.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(featuredCampaignsProvider),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const _GreetingHero(),
            const SizedBox(height: 20),
            const _BannerCarousel(),
            const SizedBox(height: 24),
            const _FeaturedHeader(),
            const SizedBox(height: 14),
            _FeaturedList(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Greeting Hero (gradient card with personalized welcome + action pills)
// ─────────────────────────────────────────────────────────────────────────

class _GreetingHero extends ConsumerWidget {
  const _GreetingHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final name = profileAsync.whenOrNull(
          data: (state) => (state.profile?['name'] ?? 'there').toString(),
        ) ??
        'there';
    final firstName = name.split(' ').first;

    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);
    final unreadInbox = ref.watch(conversationsProvider).maybeWhen(
          data: (list) => list.where((c) => c['is_read'] == false).length,
          orElse: () => 0,
        );

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF10B981),
            Color(0xFF047857),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative blob
          Positioned(
            top: -30,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Greeting
                  Text(
                    greeting + ',',
                    style: AppTextStyles.callout.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    firstName + ' 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.largeTitle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to grow your reach today?',
                    style: AppTextStyles.subheadline.copyWith(
                      color: Colors.white.withOpacity(0.80),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick access pills row
                  Row(
                    children: [
                      Expanded(
                        child: _QuickPill(
                          icon: Iconsax.wallet_2,
                          label: 'Wallet',
                          onTap: () => context.push(AppRoutes.wallet),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickPill(
                          icon: Iconsax.notification,
                          label: 'Alerts',
                          badge: unreadNotifs,
                          onTap: () => context.push(AppRoutes.notifications),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickPill(
                          icon: Iconsax.sms,
                          label: 'Inbox',
                          badge: unreadInbox,
                          onTap: () => context.push(AppRoutes.messages),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass pill in the greeting hero — icon + label + optional badge.
class _QuickPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _QuickPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  State<_QuickPill> createState() => _QuickPillState();
}

class _QuickPillState extends State<_QuickPill> {
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
        opacity: _pressed ? 0.7 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: AppRadius.allLg,
            border: Border.all(
              color: Colors.white.withOpacity(0.30),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 22),
                  if (widget.badge > 0)
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: AppRadius.pillAll,
                          border: Border.all(
                              color: Colors.white, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.badge > 99 ? '99+' : '${widget.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: AppTextStyles.caption1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
// Banner carousel (admin-managed banners; hidden when none)
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
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: slideCount,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DbBannerSlide(banner: dbBanners[i]),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slideCount,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 22 : 7,
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.allXl,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.allXl,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackContainer(),
                )
              : _fallbackContainer(),
        ),
      ),
    );
  }

  Widget _fallbackContainer() => Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Featured campaigns section
// ─────────────────────────────────────────────────────────────────────────

class _FeaturedHeader extends StatelessWidget {
  const _FeaturedHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Featured Campaigns',
            style: AppTextStyles.title3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go(AppRoutes.campaigns),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: AppRadius.pillAll,
              ),
              child: Row(
                children: [
                  Text(
                    'See all',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Iconsax.arrow_right_3,
                      size: 14, color: AppColors.primaryDeep),
                ],
              ),
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
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: ShimmerCard(height: 92),
            ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (rows) {
        final items = rows.map(_mapCampaign).toList();
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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

// ── Data mapping helpers ──────────────────────────────────────────────────

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
