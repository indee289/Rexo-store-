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
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_chip.dart';
import '../../../core/widgets/section_header.dart';
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
  int _selectedTabIndex = 0; // 0 = Campaigns, 1 = Top Creators

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEmailVerificationBanner(),
                    _buildSearchBar(),
                    const SizedBox(height: AppSpacing.lg),
                    const CategoryChips(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildFeaturedCarousel(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildToggleTabs(),
                    const SizedBox(height: AppSpacing.md),
                    if (_selectedTabIndex == 0) _buildCampaignsContent(),
                    if (_selectedTabIndex == 1) _buildCreatorsContent(),
                    // Leave room for the floating translucent dock.
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

  Widget _buildSliverAppBar() {
    final theme = Theme.of(context);

    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      title: Text(
        'Rexo',
        style: AppTextStyles.h4.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          icon: Icon(
            Iconsax.notification,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.pillAll,
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              Iconsax.search_normal,
              size: 20,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Search campaigns...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    ).staggeredEntrance(1);
  }

  /// Horizontal featured-campaign carousel using the shared [CampaignCard] in
  /// its [CampaignCardLayout.horizontal] layout.
  Widget _buildFeaturedCarousel() {
    final campaignsAsync = ref.watch(featuredCampaignsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screenPadding,
          child: const SectionHeader(title: 'Featured Campaigns'),
        ),
        const SizedBox(height: AppSpacing.sm),
        campaignsAsync.when(
          data: (campaigns) {
            if (campaigns.isEmpty) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: AppSpacing.screenPadding,
                itemCount: campaigns.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final campaign = campaigns[index];
                  return CampaignCard(
                    campaign: campaign,
                    layout: CampaignCardLayout.horizontal,
                    onTap: () => _openCampaign(campaign),
                  ).staggeredEntrance(index);
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 176,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screenPadding,
              itemCount: 3,
              itemBuilder: (context, index) => const ShimmerCampaignCard(),
            ),
          ),
          error: (_, __) => _buildErrorState('Failed to load campaigns'),
        ),
      ],
    );
  }

  /// Segmented Campaigns / Top Creators toggle built from [PremiumChip]s.
  Widget _buildToggleTabs() {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Row(
        children: [
          PremiumChip(
            label: 'Campaigns',
            icon: Iconsax.briefcase,
            selected: _selectedTabIndex == 0,
            onTap: () => setState(() => _selectedTabIndex = 0),
          ),
          const SizedBox(width: AppSpacing.sm),
          PremiumChip(
            label: 'Top Creators',
            icon: Iconsax.people,
            selected: _selectedTabIndex == 1,
            onTap: () => setState(() => _selectedTabIndex = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsContent() {
    final campaignsAsync = ref.watch(recentCampaignsProvider);

    return campaignsAsync.when(
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return const EmptyState(
            icon: Iconsax.document,
            title: 'No campaigns available',
            subtitle: 'Pull to refresh or check back later.',
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final campaign = campaigns[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: CampaignCard(
                campaign: campaign,
                onTap: () => _openCampaign(campaign),
              ).staggeredEntrance(index),
            );
          },
        );
      },
      loading: () => Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: List.generate(
            3,
            (index) => const ShimmerCampaignCardCompact(),
          ),
        ),
      ),
      error: (_, __) => _buildErrorState('Failed to load campaigns'),
    );
  }

  Widget _buildCreatorsContent() {
    final creatorsAsync = ref.watch(trendingCreatorsProvider);

    return creatorsAsync.when(
      data: (creators) {
        if (creators.isEmpty) {
          return const EmptyState(
            icon: Iconsax.people,
            title: 'No creators found',
            subtitle: 'Pull to refresh or check back later.',
          );
        }
        return Padding(
          padding: AppSpacing.screenPadding,
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (int i = 0; i < creators.length; i++)
                SizedBox(
                  width: (MediaQuery.of(context).size.width -
                          (AppSpacing.lg * 2) -
                          AppSpacing.md) /
                      2,
                  child: CreatorCard(
                    creator: creators[i],
                    onTap: () {
                      final userId = creators[i]['user_id']?.toString();
                      if (userId != null) {
                        context.push('/creators/$userId');
                      }
                    },
                  ).staggeredEntrance(i),
                ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: AppSpacing.screenPadding,
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: List.generate(
            4,
            (index) => const ShimmerCreatorCard(),
          ),
        ),
      ),
      error: (_, __) => _buildErrorState('Failed to load creators'),
    );
  }

  void _openCampaign(Map<String, dynamic> campaign) {
    final id = campaign['id']?.toString();
    if (id != null) {
      context.push('/campaigns/$id');
    }
  }

  Widget _buildEmailVerificationBanner() {
    final theme = Theme.of(context);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) return const SizedBox.shrink();

      final emailConfirmedAt = user.emailConfirmedAt;
      if (emailConfirmedAt != null) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Container(
          margin: AppSpacing.screenPadding,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: AppRadius.allSm,
                ),
                child: const Icon(
                  Iconsax.sms,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify your email',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Please check your inbox and verify your email address '
                      'to access all features.',
                      style: AppTextStyles.caption.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildErrorState(String message) {
    return EmptyState(
      icon: Iconsax.warning_2,
      title: message,
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
}
