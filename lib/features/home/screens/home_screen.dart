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

/// Instagram-style Home feed.
///
/// Top: white app bar with the 'Rexo' logo left-aligned + notification/inbox
/// icons right. Then: horizontal 'Stories' row of banner/campaign highlights
/// (with the iconic story-ring gradient around each avatar). Then: vertical
/// feed of featured campaign cards, Instagram post-style.
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

              // Hairline separator
              const SliverToBoxAdapter(
                child: Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: AppColors.border,
                ),
              ),

              // Stories row
              const SliverToBoxAdapter(child: _StoriesRow()),

              const SliverToBoxAdapter(
                child: Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: AppColors.border,
                ),
              ),

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
          // Rexo "logo" — bold left-aligned wordmark (IG's Billabong style)
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
          // Wallet icon (Rexo-specific)
          _HeaderIcon(
            icon: Iconsax.wallet_2,
            onTap: () => context.push(AppRoutes.wallet),
          ),
          const SizedBox(width: 4),
          // Notifications (IG heart)
          _HeaderIcon(
            icon: Iconsax.notification,
            badge: unreadNotifs,
            onTap: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(width: 4),
          // DM / messages (IG paper plane)
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
                    border:
                        Border.all(color: Colors.white, width: 1.5),
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
// Stories row — horizontal scroll of banner "stories" with IG rings
// ─────────────────────────────────────────────────────────────────────────

class _StoriesRow extends ConsumerWidget {
  const _StoriesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(bannersProvider).value ??
        const <Map<String, dynamic>>[];
    final profile = ref.watch(currentUserProfileProvider).value?.profile;

    if (banners.isEmpty && profile == null) {
      return const SizedBox(height: 0);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            // "Your story" — user avatar with plus badge
            if (profile != null)
              _StoryCircle.user(
                name: (profile['name'] ?? 'You').toString(),
                imageUrl: profile['profileImage'] as String?,
                label: 'Your story',
              ),
            // Banner stories
            for (final b in banners)
              _StoryCircle(
                imageUrl: (b['image_url'] ?? '').toString(),
                label: (b['title'] ?? 'Story').toString(),
                onTap: () {
                  final linkType = b['link_type'] as String? ?? 'none';
                  final campaignId = b['link_campaign_id'] as String?;
                  final page = b['link_page'] as String?;
                  if (linkType == 'campaign' && campaignId != null) {
                    context.push('/campaigns/$campaignId');
                  } else if (linkType == 'page' &&
                      page != null &&
                      page.isNotEmpty) {
                    context.push(page);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A single Instagram-style story circle with the iconic gradient ring.
class _StoryCircle extends StatefulWidget {
  final String? imageUrl;
  final String label;
  final VoidCallback? onTap;
  final bool isUser;
  final String? name;

  const _StoryCircle({
    required this.imageUrl,
    required this.label,
    this.onTap,
    this.isUser = false,
    this.name,
  });

  const _StoryCircle.user({
    required String name,
    required String? imageUrl,
    required this.label,
  })  : imageUrl = imageUrl,
        onTap = null,
        isUser = true,
        name = name;

  @override
  State<_StoryCircle> createState() => _StoryCircleState();
}

class _StoryCircleState extends State<_StoryCircle> {
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
        opacity: _pressed ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RingedAvatar(
                imageUrl: widget.imageUrl,
                name: widget.name,
                isUser: widget.isUser,
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Text(
                  widget.label,
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

class _RingedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final bool isUser;

  const _RingedAvatar({
    required this.imageUrl,
    required this.name,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Story gradient ring
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            gradient: isUser ? null : AppColors.storyGradient,
            color: isUser ? AppColors.border : null,
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _initialFallback(name ?? '?'),
                    )
                  : _initialFallback(name ?? '?'),
            ),
          ),
        ),
        // Plus badge for "your story"
        if (isUser)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Iconsax.add,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _initialFallback(String n) {
    final letter = n.trim().isEmpty ? '?' : n.trim()[0].toUpperCase();
    return Container(
      color: AppColors.surfaceAlt,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTextStyles.title3.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
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
            padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
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
              padding: EdgeInsets.fromLTRB(24, 40, 24, 40),
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
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
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
