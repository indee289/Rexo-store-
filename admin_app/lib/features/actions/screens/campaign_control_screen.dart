import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_card.dart';
import '../../admin/providers/admin_provider.dart';
import 'create_campaign_screen.dart';

class CampaignControlScreen extends ConsumerStatefulWidget {
  const CampaignControlScreen({super.key});

  @override
  ConsumerState<CampaignControlScreen> createState() =>
      _CampaignControlScreenState();
}

class _CampaignControlScreenState extends ConsumerState<CampaignControlScreen> {
  void _navigateToCreateCampaign(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCampaignScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(adminCampaignsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Campaign Control'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _navigateToCreateCampaign(context),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
      body: campaigns.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text('No campaigns found',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
        error: (error, _) => Center(child: Text(ErrorUtils.sanitize(error))),
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
        color = Colors.grey;
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
