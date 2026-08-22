import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../services/supabase_service.dart';
import '../providers/campaigns_provider.dart';

/// Provider for user's own campaigns (brand role)
final myCampaignsListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final response = await SupabaseService.client
      .from('campaigns')
      .select('*, applications(id)')
      .eq('brand_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Provider for current user's role
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  final profile = await SupabaseService.getUserProfile(user.id);
  return profile?['role'] as String?;
});

class MyCampaignsScreen extends ConsumerWidget {
  const MyCampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        final isBrand = role == 'brand';
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              isBrand ? 'My Campaigns' : 'My Applications',
              style: AppTextStyles.h5,
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: isBrand
              ? _BrandCampaignsList()
              : _CreatorApplicationsList(),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('My Campaigns', style: AppTextStyles.h5),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('My Campaigns', style: AppTextStyles.h5),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: Text('Failed to load', style: AppTextStyles.bodyMedium),
        ),
      ),
    );
  }
}

class _BrandCampaignsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(myCampaignsListProvider);

    return campaignsAsync.when(
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return _buildEmptyState(
            icon: Iconsax.volume_high,
            title: 'No campaigns yet',
            subtitle: 'Create your first campaign to find creators',
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(myCampaignsListProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return _BrandCampaignCard(campaign: campaign);
            },
          ),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerCard(height: 100),
        ),
      ),
      error: (e, _) => Center(
        child:
            Text('Failed to load campaigns', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}

class _CreatorApplicationsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return applicationsAsync.when(
      data: (applications) {
        if (applications.isEmpty) {
          return _buildEmptyState(
            icon: Iconsax.document,
            title: 'No applications yet',
            subtitle: 'Apply to campaigns to start collaborating with brands',
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(myApplicationsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              return _ApplicationCard(application: application);
            },
          ),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerCard(height: 100),
        ),
      ),
      error: (e, _) => Center(
        child: Text('Failed to load applications',
            style: AppTextStyles.bodyMedium),
      ),
    );
  }
}

class _BrandCampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;

  const _BrandCampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final title = campaign['title'] ?? 'Untitled Campaign';
    final status = campaign['status'] ?? 'draft';
    final createdAt = DateTime.tryParse(campaign['created_at'] ?? '');
    final dateStr =
        createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '';
    final applications = campaign['applications'] as List? ?? [];
    final totalSlots = campaign['total_slots'] ?? 0;
    final filledSlots = applications.length;

    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = AppColors.success;
        break;
      case 'completed':
        statusColor = const Color(0xFF2196F3);
        break;
      case 'paused':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Iconsax.people, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text(
                '$filledSlots / $totalSlots slots filled',
                style: AppTextStyles.bodySmall,
              ),
              const Spacer(),
              Icon(Iconsax.calendar, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text(dateStr, style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final campaign = application['campaigns'] as Map<String, dynamic>? ?? {};
    final campaignTitle = campaign['title'] ?? 'Unknown Campaign';
    final status = application['status'] ?? 'pending';
    final pitch = application['pitch'] ?? '';
    final createdAt = DateTime.tryParse(application['created_at'] ?? '');
    final dateStr =
        createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '';

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        break;
      case 'withdrawn':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  campaignTitle,
                  style: AppTextStyles.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (pitch.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              pitch,
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Iconsax.calendar, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text('Applied $dateStr', style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            subtitle,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
