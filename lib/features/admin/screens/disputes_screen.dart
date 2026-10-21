import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../widgets/premium_card.dart';
import '../providers/admin_provider.dart';

class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputes = ref.watch(adminDisputesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Disputes',
      ),
      body: disputes.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.tick_circle, size: 48, color: AppColors.success),
                  const SizedBox(height: 12),
                  Text('No disputes yet',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final dispute = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Iconsax.message_question,
                                color: AppColors.error, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titleOf(dispute),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _statusLine(dispute),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (dispute['description'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          dispute['description'],
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                      if (_metaOf(dispute).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _metaOf(dispute),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                      if ((dispute['resolution'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Resolution: ${dispute['resolution']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if ((dispute['status'] ?? 'open').toString().toLowerCase() != 'resolved')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showResolveDialog(
                              context, ref, dispute['id'].toString()),
                          icon: const Icon(Iconsax.tick_circle, size: 16),
                          label: const Text('Resolve'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                          ),
                        ),
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

  /// The table column is `subject` (the old code read a non-existent `title`).
  static String _titleOf(Map<String, dynamic> d) {
    final subject = (d['subject'] ?? d['title'] ?? '').toString().trim();
    if (subject.isNotEmpty) return subject;
    final id = (d['id'] ?? '').toString();
    return 'Dispute #${id.length > 8 ? id.substring(0, 8) : id}';
  }

  static String _statusLine(Map<String, dynamic> d) {
    final status = (d['status'] ?? 'open').toString();
    final date = _dateOf(d);
    return date.isEmpty ? 'Status: $status' : 'Status: $status  •  $date';
  }

  static String _dateOf(Map<String, dynamic> d) {
    final raw = (d['created_at'] ?? d['createdAt'] ?? '').toString();
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String _metaOf(Map<String, dynamic> d) {
    final parts = <String>[];
    final user = (d['user_id'] ?? '').toString();
    if (user.isNotEmpty) parts.add('User: $user');
    final order = (d['order_id'] ?? '').toString();
    if (order.isNotEmpty) parts.add('Order: $order');
    final campaign = (d['campaign_id'] ?? '').toString();
    if (campaign.isNotEmpty) parts.add('Campaign: $campaign');
    return parts.join('\n');
  }

  void _showResolveDialog(
      BuildContext context, WidgetRef ref, String disputeId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Dispute'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Resolution',
            hintText: 'Describe the resolution...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final ok = await ref
                  .read(adminActionsProvider.notifier)
                  .resolveDispute(disputeId, controller.text.trim());
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Dispute resolved. The user has been notified.'
                      : 'Could not resolve the dispute. Please try again.'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }
}
