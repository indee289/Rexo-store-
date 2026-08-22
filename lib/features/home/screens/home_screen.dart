import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/home_provider.dart';
import '../widgets/campaign_card.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
              // App Bar
              _buildSliverAppBar(),
              // Body content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    const CategoryChips(),
                    const SizedBox(height: 20),
                    _buildToggleTabs(),
                    const SizedBox(height: 16),
                    if (_selectedTabIndex == 0) _buildCampaignsContent(ref),
                    if (_selectedTabIndex == 1) _buildCreatorsContent(ref),
                    const SizedBox(height: 100),
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
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          context.push(AppRoutes.profile);
        },
        icon: const Icon(
          Iconsax.user,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
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
          onPressed: () {
            context.push(AppRoutes.notifications);
          },
          icon: const Icon(
            Iconsax.notification,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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
              'Search campaigns...',
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

  Widget _buildToggleTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.border.withOpacity(0.5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTabIndex = 0);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 40,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 0
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Campaigns',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedTabIndex == 0
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTabIndex = 1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 40,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 1
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Top Creators',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedTabIndex == 1
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignsContent(WidgetRef ref) {
    final campaignsAsync = ref.watch(featuredCampaignsProvider);

    return campaignsAsync.when(
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return _buildEmptyState('No campaigns available');
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            return CampaignCard(
              campaign: campaigns[index],
              isCompact: true,
              onTap: () {
                final id = campaigns[index]['id']?.toString();
                if (id != null) {
                  context.push('/campaigns/$id');
                }
              },
            );
          },
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(
            3,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerCard(height: 200),
            ),
          ),
        ),
      ),
      error: (error, _) => _buildErrorState('Failed to load campaigns'),
    );
  }

  Widget _buildCreatorsContent(WidgetRef ref) {
    final creatorsAsync = ref.watch(trendingCreatorsProvider);

    return creatorsAsync.when(
      data: (creators) {
        if (creators.isEmpty) {
          return _buildEmptyState('No creators found');
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: creators.map((creator) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 44) / 2,
                child: CreatorCard(
                  creator: creator,
                  onTap: () {
                    // Navigate to creator profile
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            4,
            (index) => SizedBox(
              width: (MediaQuery.of(context).size.width - 44) / 2,
              height: 180,
              child: const ShimmerCard(height: 180),
            ),
          ),
        ),
      ),
      error: (error, _) => _buildErrorState('Failed to load creators'),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Iconsax.document,
              size: 48,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}
