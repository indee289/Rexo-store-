import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../widgets/premium_card.dart';
import '../providers/admin_provider.dart';

/// Admin review queue for pending subscription payments.
///
/// Lists each pending row from `subscription_payments` (user, plan, amount,
/// transaction ref, proof). Approving activates the subscription
/// (AdminActionsNotifier.approveSubscriptionPayment); rejecting marks it
/// 'rejected'.
class SubscriptionRequestsScreen extends ConsumerWidget {
  const SubscriptionRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(adminSubscriptionPaymentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Subscription Requests'),
      ),
      body: payments.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.tick_circle,
                      size: 48, color: AppColors.success),
                  const SizedBox(height: 12),
                  Text(
                    'No pending subscription requests',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminSubscriptionPaymentsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final payment = list[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RequestCard(payment: payment),
                );
              },
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(child: Text(ErrorUtils.sanitize(error))),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.payment});

  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final id = payment['id']?.toString() ?? '';
    final amount = payment['amount'] ?? 0;
    final planName = payment['plan_name']?.toString() ??
        (payment['plan_id']?.toString().substring(0, 8) ?? 'Plan');
    final durationDays = payment['duration_days'] ?? 30;
    final paymentMethod = payment['payment_method']?.toString() ?? '-';
    final transactionRef = payment['transaction_ref']?.toString() ?? '-';
    final proofUrl = payment['proof_url']?.toString();

    // The joined user object (users(name, email)) if available.
    final user = payment['users'];
    String userLabel;
    if (user is Map) {
      userLabel = (user['name'] ?? user['email'] ?? '').toString();
    } else {
      userLabel = payment['user_id']?.toString().substring(0, 8) ?? 'Unknown';
    }
    if (userLabel.isEmpty) {
      userLabel = payment['user_id']?.toString().substring(0, 8) ?? 'Unknown';
    }

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  planName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '\u20B9$amount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _infoRow(context, 'User', userLabel),
          _infoRow(context, 'Duration', '$durationDays days'),
          _infoRow(context, 'Method', paymentMethod),
          _infoRow(context, 'Txn Ref', transactionRef),
          if (proofUrl != null && proofUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showProof(context, proofUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  proofUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    alignment: Alignment.center,
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    child: Text('Proof unavailable',
                        style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5))),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(adminActionsProvider.notifier)
                        .approveSubscriptionPayment(id);
                    _surface(context, ref, 'approved');
                  },
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
                  onPressed: () async {
                    await ref
                        .read(adminActionsProvider.notifier)
                        .rejectSubscriptionPayment(id);
                    _surface(context, ref, 'rejected');
                  },
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
    );
  }

  void _surface(BuildContext context, WidgetRef ref, String verb) {
    final actionState = ref.read(adminActionsProvider);
    if (!context.mounted) return;
    actionState.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription payment $verb'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.sanitize(error)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showProof(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
