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
  int _selectedTabIndex = 0;

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
                    const SizedBox(height: AppSpacing.sm),
                    const CategoryChips(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildToggleTabs(),
                    const SizedBox(height: AppSpacing.md),
                    if (_selectedTabIndex == 0) _buildCampaignsContent(),
                    if (_selectedTabIndex == 1) _buildCreatorsContent(),
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
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: AppSpacing.lg,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.allSm,
            ),
            child: const Icon(Iconsax.crown_1, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Rexo',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final profileAsync = ref.watch(homeUserProfileProvider);
            return profileAsync.when(
              data: (profile) {
                final name = profile?['name'] ?? '';
                final avatarUrl = profile?['avatar_url'];
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.push(AppRoutes.notifications),
                        icon: Icon(Iconsax.notification,
                            color: theme.colorScheme.onSurface, size: 22),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.profile),
                        child: PremiumAvatar(
                            imageUrl: avatarUrl, name: name, size: 32),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(width: 36, height: 36),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }

  /// Equal-width segmented control — both tabs always same size.
  Widget _buildToggleTabs() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceAlt
              : AppColors.surfaceAlt,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: Row(
          children: [
            _buildTab(
              index: 0,
              icon: Iconsax.briefcase,
              label: 'Campaigns',
            ),
            _buildTab(
              index: 1,
              icon: Iconsax.people,
              label: 'Top Creators',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTabIndex == index;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: AppRadius.allMd,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
      if (user.emailConfirmedAt != null) return const SizedBox.shrink();

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
                child: const Icon(Iconsax.sms,
                    color: AppColors.warning, size: 20),
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
                      'Check your inbox to verify your email address.',
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
