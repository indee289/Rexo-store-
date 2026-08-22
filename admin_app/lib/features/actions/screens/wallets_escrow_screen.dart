import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_card.dart';
import '../../admin/providers/admin_provider.dart';

class WalletsEscrowScreen extends ConsumerWidget {
  const WalletsEscrowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(adminWalletsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Wallets & Escrow'),
      ),
      body: wallets.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text('No wallets found',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final wallet = list[index];
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
                              color: Colors.brown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Iconsax.wallet,
                                color: Colors.brown, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wallet #${wallet['id']?.toString().substring(0, 8) ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Status: ${wallet['status'] ?? 'active'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\u20B9${wallet['available_balance'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showAmountDialog(
                                  context, ref, wallet['id'], true),
                              icon: const Icon(Iconsax.add, size: 16),
                              label: const Text('Credit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.success,
                                side: const BorderSide(color: AppColors.success),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showAmountDialog(
                                  context, ref, wallet['id'], false),
                              icon: const Icon(Iconsax.minus, size: 16),
                              label: const Text('Debit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => ref
                                .read(adminActionsProvider.notifier)
                                .freezeWallet(wallet['id']),
                            icon: const Icon(Iconsax.lock, size: 20),
                            color: AppColors.warning,
                            tooltip: 'Freeze Wallet',
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

  void _showAmountDialog(
      BuildContext context, WidgetRef ref, String walletId, bool isCredit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCredit ? 'Credit Wallet' : 'Debit Wallet'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '\u20B9 ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                if (isCredit) {
                  ref
                      .read(adminActionsProvider.notifier)
                      .creditWallet(walletId, amount);
                } else {
                  ref
                      .read(adminActionsProvider.notifier)
                      .debitWallet(walletId, amount);
                }
                Navigator.pop(context);
              }
            },
            child: Text(isCredit ? 'Credit' : 'Debit'),
          ),
        ],
      ),
    );
  }
}
