import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/campaign_card.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../services/supabase_service.dart';
import '../providers/home_provider.dart';
import '../widgets/category_chips.dart';
import '../widgets/creator_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                centerTitle: false,
                titleSpacing: 20,
                title: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Iconsax.crown_1,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        'Rexo',
                        style: AppTextStyles.h4.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  _buildNavActions(isDark),
                ],
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEmailBanner(),
                    const SizedBox(height: 4),
                    const CategoryChips(),
                    const SizedBox(height: 16),
                    _buildSegmentedTabs(isDark),
                    const SizedBox(height: 16),
                    if (_tab == 0) _buildCampaigns(),
                    if (_tab == 1) _buildCreators(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavActions(bool isDark) {
    final profileAsync = ref.watch(homeUserProfileProvider);
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          // Notification bell
          GestureDetector(
            onTap: () => context.push(AppRoutes.notifications),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceAlt
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.border,
                ),
              ),
              child: Icon(
                Iconsax.notification,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
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

  /// Equal-width segmented control — both tabs always same width.
  Widget _buildSegmentedTabs(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            _segTab(0, Iconsax.briefcase, 'Campaigns', isDark),
            _segTab(1, Iconsax.people, 'Top Creators', isDark),
          ],
        ),
      ),
    );
  }

  Widget _segTab(int idx, IconData icon, String label, bool isDark) {
    final active = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: active ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: active
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextHint
                        : AppColors.textHint),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w500,
                  color: active
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextHint
                          : AppColors.textHint),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaigns() {
    final async = ref.watch(recentCampaignsProvider);
    return async.when(
      data: (list) => list.isEmpty
          ? const EmptyState(
              icon: Iconsax.document,
              title: 'No campaigns yet',
              subtitle: 'Pull down to refresh.',
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: list.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CampaignCard(
                  campaign: list[i],
                  onTap: () {
                    final id = list[i]['id']?.toString();
                    if (id != null) context.push('/campaigns/$id');
                  },
                ).staggeredEntrance(i),
              ),
            ),
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(
            3,
            (_) => const ShimmerCampaignCardCompact(),
          ),
        ),
      ),
      error: (_, __) => _errorState('Failed to load campaigns'),
    );
  }

  Widget _buildCreators() {
    final async = ref.watch(trendingCreatorsProvider);
    return async.when(
      data: (list) => list.isEmpty
          ? const EmptyState(
              icon: Iconsax.people,
              title: 'No creators found',
              subtitle: 'Pull down to refresh.',
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (int i = 0; i < list.length; i++)
                    SizedBox(
                      width:
                          (MediaQuery.of(context).size.width - 40 - 12) / 2,
                      child: CreatorCard(
                        creator: list[i],
                        onTap: () {
                          final id = list[i]['user_id']?.toString();
                          if (id != null) context.push('/creators/$id');
                        },
                      ).staggeredEntrance(i),
                    ),
                ],
              ),
            ),
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(4, (_) => const ShimmerCreatorCard()),
        ),
      ),
      error: (_, __) => _errorState('Failed to load creators'),
    );
  }

  Widget _buildEmailBanner() {
    try {
      final user = SupabaseService.currentUser;
      if (user == null || user.emailConfirmedAt != null) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.sms, color: AppColors.warning, size: 18),
            const SizedBox(width: 10),
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
