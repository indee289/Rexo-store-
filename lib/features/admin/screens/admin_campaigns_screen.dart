import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

class AdminCampaignsScreen extends ConsumerWidget {
  const AdminCampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return _buildAccessDenied(context);

    final campaignsAsync = ref.watch(adminCampaignsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Campaign Control',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: campaignsAsync.when(
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return _buildEmpty();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return _buildCampaignCard(context, ref, campaign);
            },
          );
        },
        loading: () => const ShimmerLoading(height: 400),
        error: (error, _) => _buildError(ref),
      ),
    );
  }

  Widget _buildCampaignCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> campaign,
  ) {
    final title = campaign['title'] ?? 'Untitled';
    final status = campaign['status'] ?? 'draft';
    final budget = campaign['budget']?.toString() ?? '0';
    final campaignId = campaign['id'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumCard(
        onTap: () => _showCampaignActions(context, ref, campaignId, title, status),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Budget: \u20B9$budget',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusChip(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = AppColors.success;
        break;
      case 'paused':
        color = AppColors.warning;
        break;
      case 'completed':
        color = const Color(0xFF2196F3);
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showCampaignActions(
    BuildContext context,
    WidgetRef ref,
    String campaignId,
    String title,
    String currentStatus,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (currentStatus == 'active')
              ListTile(
                leading: const Icon(Iconsax.pause, color: AppColors.warning),
                title: Text('Pause', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAndUpdate(context, ref, campaignId, 'paused', 'Pause campaign?');
                },
              ),
            if (currentStatus == 'paused')
              ListTile(
                leading: const Icon(Iconsax.play, color: AppColors.success),
                title: Text('Resume', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAndUpdate(context, ref, campaignId, 'active', 'Resume campaign?');
                },
              ),
            if (currentStatus != 'completed')
              ListTile(
                leading: const Icon(Iconsax.tick_circle, color: Color(0xFF2196F3)),
                title: Text('Force Complete', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAndUpdate(context, ref, campaignId, 'completed', 'Force complete campaign?');
                },
              ),
            if (currentStatus != 'cancelled')
              ListTile(
                leading: const Icon(Iconsax.close_circle, color: AppColors.error),
                title: Text('Cancel', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAndUpdate(context, ref, campaignId, 'cancelled', 'Cancel campaign? This is destructive.');
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmAndUpdate(
    BuildContext context,
    WidgetRef ref,
    String campaignId,
    String newStatus,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(adminActionsProvider.notifier)
                  .updateCampaignStatus(campaignId, newStatus);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Status updated' : 'Action failed'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: Text('Confirm', style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Campaign Control', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.lock, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Access Denied', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.briefcase, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No campaigns found', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.warning_2, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Failed to load campaigns', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
          TextButton(
            onPressed: () => ref.invalidate(adminCampaignsProvider),
            child: Text('Retry', style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
