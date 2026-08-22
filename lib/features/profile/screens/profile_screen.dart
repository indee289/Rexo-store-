import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/stat_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Profile',
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
            onPressed: () {},
            icon: const Icon(
              Iconsax.setting_2,
              color: AppColors.textPrimary,
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
              const Icon(
                Iconsax.warning_2,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
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
    final bio = profile['bio'] ?? '';
    final avatarUrl = profile['avatar_url'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Avatar with edit overlay
          _buildAvatarSection(context, avatarUrl, name),
          const SizedBox(height: 16),
          // Name
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          // Handle
          if (handle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '@$handle',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Role badge
          _buildRoleBadge(role),
          // Bio
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                bio,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Stats row
          _buildStatsRow(profileState),
          const SizedBox(height: 24),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 8),
          // Menu items
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
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Iconsax.bag_2,
            title: 'My Orders',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Iconsax.shield_tick,
            title: 'KYC Verification',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Iconsax.notification,
            title: 'Notifications',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Iconsax.setting_2,
            title: 'Settings',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Iconsax.message_question,
            title: 'Help & Support',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Logout',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  ref.read(authProvider.notifier).signOut();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, String? avatarUrl, String name) {
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
              border: Border.all(color: Colors.white, width: 2),
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

  Widget _buildStatsRow(ProfileState profileState) {
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
              color: AppColors.divider,
            ),
            StatChip(
              icon: Iconsax.wallet_1,
              value: '\u20B9$totalEarnings',
              label: 'Earnings',
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.divider,
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
      // For brands: Campaigns Posted, Total Spent, Active Campaigns
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
              color: AppColors.divider,
            ),
            StatChip(
              icon: Iconsax.wallet_1,
              value: '\u20B9${profileState.wallet?['total_earnings']?.toString() ?? '0'}',
              label: 'Total Spent',
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.divider,
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
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Iconsax.arrow_right_3,
        size: 18,
        color: AppColors.textHint,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
