import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../services/supabase_service.dart';
import '../providers/campaigns_provider.dart';
import '../widgets/campaign_list_card.dart';
import 'create_campaign_screen.dart';

/// Provider for current user's role (for FAB visibility)
final _campaignsUserRoleProvider = FutureProvider<String?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  final profile = await SupabaseService.getUserProfile(user.id);
  return profile?['role'] as String?;
});

class CampaignsScreen extends ConsumerStatefulWidget {
  const CampaignsScreen({super.key});

  @override
  ConsumerState<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends ConsumerState<CampaignsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  final List<String> _categories = [
    'All',
    'Fashion',
    'Tech',
    'Beauty',
    'Food',
    'Fitness',
    'Travel',
    'Gaming',
    'Lifestyle',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignsListProvider);
    final selectedCategory = ref.watch(campaignFilterProvider);
    final roleAsync = ref.watch(_campaignsUserRoleProvider);

    // Determine if FAB should be shown (brand or admin only)
    final showFab = roleAsync.whenOrNull(
          data: (role) => role == 'brand' || role == 'admin',
        ) ??
        false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Campaigns',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(
              Iconsax.filter,
              color: _showFilters ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateCampaignScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(campaignsListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildSearchBar(),
              ),
            ),

            // Category filter chips
            if (_showFilters)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCategoryChips(selectedCategory),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Campaign list
            campaigns.when(
              data: (data) {
                if (data.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CampaignListCard(campaign: data[index]),
                        );
                      },
                      childCount: data.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ShimmerCard(height: 200),
                    ),
                    childCount: 4,
                  ),
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(ErrorUtils.sanitize(error)),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(campaignSearchProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: 'Search campaigns...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(
            Iconsax.search_normal,
            color: AppColors.textHint,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(campaignSearchProvider.notifier).state = '';
                  },
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(String selectedCategory) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == selectedCategory;

          return GestureDetector(
            onTap: () {
              ref.read(campaignFilterProvider.notifier).state = category;
            },
            child: Chip(
              label: Text(
                category,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              backgroundColor:
                  isSelected ? AppColors.primary : AppColors.surface,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No campaigns found',
            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.h5.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(campaignsListProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
