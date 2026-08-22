import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../services/supabase_service.dart';
import '../../admin/providers/admin_provider.dart';

class CampaignControlScreen extends ConsumerStatefulWidget {
  const CampaignControlScreen({super.key});

  @override
  ConsumerState<CampaignControlScreen> createState() =>
      _CampaignControlScreenState();
}

class _CampaignControlScreenState extends ConsumerState<CampaignControlScreen> {
  void _showCreateCampaignDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final budgetController = TextEditingController();
    final perCreatorPayoutController = TextEditingController();
    final totalSlotsController = TextEditingController();
    final guidelinesController = TextEditingController();
    final minFollowersController = TextEditingController();
    final coverImageUrlController = TextEditingController();
    String selectedPlatform = 'Instagram';
    String selectedCategory = 'Fashion';
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Campaign'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Budget',
                    prefixText: '\u20B9 ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: perCreatorPayoutController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Per Creator Payout',
                    prefixText: '\u20B9 ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPlatform,
                  decoration: const InputDecoration(labelText: 'Platform'),
                  items: const [
                    DropdownMenuItem(value: 'Instagram', child: Text('Instagram')),
                    DropdownMenuItem(value: 'YouTube', child: Text('YouTube')),
                    DropdownMenuItem(value: 'Twitter', child: Text('Twitter')),
                    DropdownMenuItem(value: 'TikTok', child: Text('TikTok')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedPlatform = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'Fashion', child: Text('Fashion')),
                    DropdownMenuItem(value: 'Technology', child: Text('Technology')),
                    DropdownMenuItem(value: 'Food', child: Text('Food')),
                    DropdownMenuItem(value: 'Travel', child: Text('Travel')),
                    DropdownMenuItem(value: 'Fitness', child: Text('Fitness')),
                    DropdownMenuItem(value: 'Beauty', child: Text('Beauty')),
                    DropdownMenuItem(value: 'Lifestyle', child: Text('Lifestyle')),
                    DropdownMenuItem(value: 'Gaming', child: Text('Gaming')),
                    DropdownMenuItem(value: 'Education', child: Text('Education')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalSlotsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Slots'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    selectedDeadline != null
                        ? 'Deadline: ${selectedDeadline!.toLocal().toString().split(' ')[0]}'
                        : 'Select Deadline',
                  ),
                  trailing: const Icon(Iconsax.calendar),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDeadline = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: guidelinesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Guidelines'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minFollowersController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min Followers Required',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: coverImageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Cover Image URL',
                    hintText: 'https://...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a campaign title')),
                  );
                  return;
                }
                final budget = double.tryParse(budgetController.text);
                if (budget == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid budget amount')),
                  );
                  return;
                }
                try {
                  final data = <String, dynamic>{
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'budget': budget,
                    'platform': selectedPlatform,
                    'category': selectedCategory,
                    'status': 'active',
                    'brand_id': SupabaseService.currentUser?.id,
                    'created_at': DateTime.now().toIso8601String(),
                  };

                  // Add optional fields if provided
                  final perCreatorPayout =
                      double.tryParse(perCreatorPayoutController.text);
                  if (perCreatorPayout != null) {
                    data['per_creator_payout'] = perCreatorPayout;
                  }

                  final totalSlots =
                      int.tryParse(totalSlotsController.text);
                  if (totalSlots != null) {
                    data['total_slots'] = totalSlots;
                  }

                  if (selectedDeadline != null) {
                    data['deadline'] = selectedDeadline!.toIso8601String();
                  }

                  if (guidelinesController.text.isNotEmpty) {
                    data['guidelines'] = guidelinesController.text;
                  }

                  final minFollowers =
                      int.tryParse(minFollowersController.text);
                  if (minFollowers != null) {
                    data['min_followers'] = minFollowers;
                  }

                  if (coverImageUrlController.text.isNotEmpty) {
                    data['cover_image_url'] = coverImageUrlController.text;
                  }

                  await SupabaseService.client.from('campaigns').insert(data);
                  ref.invalidate(adminCampaignsProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Failed to create campaign: ${ErrorUtils.sanitize(e)}'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(adminCampaignsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Campaign Control'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showCreateCampaignDialog(context),
        child: const Icon(Iconsax.add, color: Colors.white),
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
