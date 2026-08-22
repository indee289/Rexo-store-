import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../admin/providers/admin_provider.dart';

class CampaignControlScreen extends ConsumerWidget {
  const CampaignControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(adminCampaignsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Campaign Control'),
      ),
      body: campaigns.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No campaigns found',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final campaign = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              campaign['title'] ?? 'Untitled',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _StatusBadge(status: campaign['status'] ?? 'unknown'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        campaign['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ActionButton(
                            label: 'Pause',
                            icon: Iconsax.pause,
                            color: AppColors.warning,
                            onTap: () => ref
                                .read(adminActionsProvider.notifier)
                                .updateCampaignStatus(
                                    campaign['id'], 'paused'),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            label: 'Resume',
                            icon: Iconsax.play,
                            color: AppColors.success,
                            onTap: () => ref
                                .read(adminActionsProvider.notifier)
                                .updateCampaignStatus(
                                    campaign['id'], 'active'),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            label: 'Complete',
                            icon: Iconsax.tick_circle,
                            color: AppColors.primary,
                            onTap: () => ref
                                .read(adminActionsProvider.notifier)
                                .updateCampaignStatus(
                                    campaign['id'], 'completed'),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            label: 'Cancel',
                            icon: Iconsax.close_circle,
                            color: AppColors.error,
                            onTap: () => ref
                                .read(adminActionsProvider.notifier)
                                .updateCampaignStatus(
                                    campaign['id'], 'cancelled'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = AppColors.success;
        break;
      case 'paused':
        color = AppColors.warning;
        break;
      case 'completed':
        color = AppColors.primary;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
