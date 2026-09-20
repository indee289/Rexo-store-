import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_card.dart';
import '../../admin/providers/admin_provider.dart';

class WithdrawalQueueScreen extends ConsumerWidget {
  const WithdrawalQueueScreen({super.key});

  /// Builds a short, human-readable payout line from the withdrawal's
  /// `payout_details` JSONB. Returns null when there's nothing to show.
  ///
  /// `payout_details` shapes (see 07_WALLET_TABLES.sql):
  ///   UPI  -> {upi_id: "name@bank"}
  ///   Bank -> {account_number, ifsc_code, account_holder_name}
  static String? _payoutSummary(Map<String, dynamic> withdrawal) {
    final method = withdrawal['method']?.toString();
    final raw = withdrawal['payout_details'];
    if (raw is! Map) {
      // No structured details — fall back to just the method if present.
      return (method != null && method.isNotEmpty) ? 'Payout via $method' : null;
    }
    final details = Map<String, dynamic>.from(raw);

    final upi = details['upi_id']?.toString();
    if (upi != null && upi.isNotEmpty) {
      return 'UPI: $upi';
    }

    final account = details['account_number']?.toString();
    if (account != null && account.isNotEmpty) {
      final holder = details['account_holder_name']?.toString();
      final ifsc = details['ifsc_code']?.toString();
      final buffer = StringBuffer('Bank: ');
      if (holder != null && holder.isNotEmpty) buffer.write('$holder · ');
      // Mask all but the last 4 digits of the account number.
      final masked = account.length > 4
          ? '••••${account.substring(account.length - 4)}'
          : account;
      buffer.write(masked);
      if (ifsc != null && ifsc.isNotEmpty) buffer.write(' · $ifsc');
      return buffer.toString();
    }

    return (method != null && method.isNotEmpty) ? 'Payout via $method' : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawals = ref.watch(adminWithdrawalsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Withdrawal Queue'),
      ),
      body: withdrawals.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.tick_circle, size: 48, color: AppColors.success),
                  const SizedBox(height: 12),
                  Text('No pending withdrawals',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final withdrawal = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Withdrawal #${withdrawal['id']?.toString().substring(0, 8) ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '\u20B9${withdrawal['amount'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User: ${withdrawal['user_id']?.toString().substring(0, 8) ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (_payoutSummary(withdrawal) != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _payoutSummary(withdrawal)!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => ref
                                  .read(adminActionsProvider.notifier)
                                  .approveWithdrawal(withdrawal['id']),
                              icon: const Icon(Iconsax.tick_circle, size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ref
                                  .read(adminActionsProvider.notifier)
                                  .rejectWithdrawal(withdrawal['id']),
                              icon: const Icon(Iconsax.close_circle, size: 16),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
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
