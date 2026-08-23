import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/stat_chip.dart';
import '../../../core/widgets/verified_badge.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: Icon(
              Iconsax.setting_2,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profileState) => _buildProfileContent(context, ref, profileState),
        loading: () => const ShimmerProfile(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.warning_2,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(currentUserProfileProvider),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    ProfileState profileState,
  ) {
    final profile = profileState.profile;
    if (profile == null) {
      return const Center(child: Text('No profile data'));
    }

    final name = profile['name'] ?? 'User';
    final handle = profile['handle'] ?? '';
    final role = profile['role'] ?? 'creator';
    final avatarUrl = profile['avatar_url'];
    final isVerified = (profile['is_verified'] == true);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Avatar
          _buildAvatarSection(context, avatarUrl, name),
          const SizedBox(height: 16),
          // Name + verified badge
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (isVerified) const VerifiedBadge(size: 20),
            ],
          ),
          // Handle
          if (handle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '@$handle',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Role badge
          _buildRoleBadge(role),
          const SizedBox(height: 24),
          // Stats row
          _buildStatsRow(context, profileState),
          const SizedBox(height: 24),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          const SizedBox(height: 8),
          // Quick action menu items - only 4 items
          _buildMenuItem(
            icon: Iconsax.edit,
            title: 'Edit Profile',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Iconsax.wallet_1,
            title: 'Wallet',
            onTap: () => context.push('/wallet'),
          ),
          _buildMenuItem(
            icon: Iconsax.bag_2,
            title: 'My Orders',
            onTap: () => context.push('/orders'),
          ),
          _buildMenuItem(
            icon: Iconsax.crown_1,
            title: 'Subscriptions',
            onTap: () => context.push('/subscriptions'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, String? avatarUrl, String name) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        AvatarWidget(
          url: avatarUrl,
          name: name,
          size: 100,
          showBorder: true,
          borderColor: AppColors.primary,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.surface, width: 2),
            ),
            child: const Icon(
              Iconsax.camera,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    Color badgeColor;
    String label;

    switch (role) {
      case 'brand':
        badgeColor = const Color(0xFF2196F3);
        label = 'Brand';
        break;
      case 'admin':
        badgeColor = const Color(0xFF9C27B0);
        label = 'Admin';
        break;
      default:
        badgeColor = AppColors.primary;
        label = 'Creator';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, ProfileState profileState) {
    if (profileState.isCreator) {
      final completedCampaigns =
          profileState.roleProfile?['completed_campaigns']?.toString() ?? '0';
      final totalEarnings =
          profileState.wallet?['total_earnings']?.toString() ?? '0';
      final rating =
          profileState.roleProfile?['rating']?.toString() ?? '0.0';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            StatChip(
              icon: Iconsax.briefcase,
              value: completedCampaigns,
              label: 'Campaigns',
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            StatChip(
              icon: Iconsax.wallet_1,
              value: '\u20B9$totalEarnings',
              label: 'Earnings',
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            StatChip(
              icon: Iconsax.star_1,
              value: rating,
              label: 'Rating',
              iconColor: AppColors.warning,
            ),
          ],
        ),
      );
    } else if (profileState.isBrand) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const StatChip(
              icon: Iconsax.briefcase,
              value: '-',
              label: 'Posted',
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            StatChip(
              icon: Iconsax.wallet_1,
              value: '\u20B9${profileState.wallet?['total_earnings']?.toString() ?? '0'}',
              label: 'Total Spent',
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            const StatChip(
              icon: Iconsax.chart_2,
              value: '-',
              label: 'Active',
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return ListTile(
          leading: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 22),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            Iconsax.arrow_right_3,
            size: 18,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        );
      },
    );
  }
}
