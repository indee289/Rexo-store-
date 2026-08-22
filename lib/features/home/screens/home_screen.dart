import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/home_provider.dart';
import '../widgets/campaign_card.dart';
import '../widgets/category_chips.dart';
import '../widgets/creator_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(featuredCampaignsProvider);
          ref.invalidate(trendingCreatorsProvider);
          ref.invalidate(recentCampaignsProvider);
          ref.invalidate(homeUserProfileProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            _buildSliverAppBar(ref),
            // Body content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildGreetingSection(ref),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  const CategoryChips(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Featured Campaigns', onSeeAll: () {}),
                  const SizedBox(height: 12),
                  _buildFeaturedCampaigns(ref),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Trending Creators', onSeeAll: () {}),
                  const SizedBox(height: 12),
                  _buildTrendingCreators(ref),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Recent Campaigns', onSeeAll: () {}),
                  const SizedBox(height: 12),
                  _buildRecentCampaigns(ref),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(WidgetRef ref) {
    final userProfile = ref.watch(homeUserProfileProvider);
    final avatarUrl = userProfile.whenOrNull(
      data: (data) => data?['avatar_url'] as String?,
    );
    final userName = userProfile.whenOrNull(
      data: (data) => data?['name'] as String?,
    );

    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Text(
        'Rexo',
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Iconsax.notification,
            color: AppColors.textPrimary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AvatarWidget(
            url: avatarUrl,
            name: userName,
            size: 34,
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingSection(WidgetRef ref) {
    final userProfile = ref.watch(homeUserProfileProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: userProfile.when(
        data: (data) {
          final name = data?['name'] ?? 'there';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $name!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Discover amazing campaigns',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        },
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerLine(width: 180, height: 22),
            const SizedBox(height: 8),
            const ShimmerLine(width: 200, height: 14),
          ],
        ),
        error: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Discover amazing campaigns',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(
              Iconsax.search_normal,
              size: 20,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 12),
            Text(
              'Search campaigns, creators...',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCampaigns(WidgetRef ref) {
    final campaignsAsync = ref.watch(featuredCampaignsProvider);

    return SizedBox(
      height: 260,
      child: campaignsAsync.when(
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return Center(
              child: Text(
                'No campaigns available',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CampaignCard(
                  campaign: campaigns[index],
                  onTap: () {
                    // Navigate to campaign detail
                  },
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (context, index) => const ShimmerCampaignCard(),
        ),
        error: (error, _) => Center(
          child: Text(
            'Failed to load campaigns',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingCreators(WidgetRef ref) {
    final creatorsAsync = ref.watch(trendingCreatorsProvider);

    return SizedBox(
      height: 170,
      child: creatorsAsync.when(
        data: (creators) {
          if (creators.isEmpty) {
            return Center(
              child: Text(
                'No creators found',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: creators.length,
            itemBuilder: (context, index) {
              return CreatorCard(
                creator: creators[index],
                onTap: () {
                  // Navigate to creator profile
                },
              );
            },
          );
        },
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          itemBuilder: (context, index) => const ShimmerCreatorCard(),
        ),
        error: (error, _) => Center(
          child: Text(
            'Failed to load creators',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCampaigns(WidgetRef ref) {
    final recentAsync = ref.watch(recentCampaignsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: recentAsync.when(
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No recent campaigns',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: campaigns.length > 5 ? 5 : campaigns.length,
            itemBuilder: (context, index) {
              return CampaignCard(
                campaign: campaigns[index],
                isCompact: true,
                onTap: () {
                  // Navigate to campaign detail
                },
              );
            },
          );
        },
        loading: () => Column(
          children: List.generate(
            3,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerCard(height: 120),
            ),
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load campaigns',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
