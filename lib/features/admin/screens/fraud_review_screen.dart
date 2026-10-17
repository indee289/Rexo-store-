import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../widgets/premium_card.dart';
import '../providers/fraud_provider.dart';

/// Admin "Risk & Fraud" review surface. Shows heuristic wallet risk flags
/// derived from deposits/withdrawals. Review-only — it never moves money.
class FraudReviewScreen extends ConsumerWidget {
  const FraudReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(flaggedActivityProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Risk & Fraud'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(flaggedActivityProvider),
        child: flagsAsync.when(
          data: (flags) {
            if (flags.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  const Icon(Iconsax.shield_tick,
                      size: 48, color: AppColors.success),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('No risk flags',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: flags.length,
              itemBuilder: (context, index) => _FlagCard(flag: flags[index]),
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (error, _) => Center(child: Text(ErrorUtils.sanitize(error))),
        ),
      ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  final RiskFlag flag;
  const _FlagCard({required this.flag});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isHigh = flag.severity == 'high';
    final color = isHigh ? AppColors.error : AppColors.warning;
    final date = flag.createdAt != null
        ? DateFormat('MMM dd, HH:mm').format(flag.createdAt!)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    flag.severity.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    flag.type[0].toUpperCase() + flag.type.substring(1),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ),
                const Spacer(),
                if (date.isNotEmpty)
                  Text(date,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              flag.reason,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'User: ${flag.userId.isNotEmpty && flag.userId.length >= 8 ? flag.userId.substring(0, 8) : flag.userId}'
              '${flag.id.startsWith('velocity-') ? '' : '  ·  ₹${flag.amount}'}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
