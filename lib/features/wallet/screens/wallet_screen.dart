import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PremiumAppBar(title: 'Wallet'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(walletProvider);
          ref.invalidate(transactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              walletAsync.when(
                data: (wallet) => _buildBalanceCard(wallet),
                loading: () => const ShimmerCard(height: 200),
                error: (e, _) => _buildBalanceCard(null),
              ),

              const SizedBox(height: AppSpacing.xl - 4),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: PremiumButton(
                      label: 'Deposit',
                      variant: PremiumButtonVariant.tonal,
                      icon: Iconsax.money_add,
                      onPressed: () => context.push('/wallet/deposit'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PremiumButton(
                      label: 'Withdraw',
                      variant: PremiumButtonVariant.outline,
                      icon: Iconsax.money_send,
                      onPressed: () => context.push('/wallet/withdraw'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl - 4),

              // Transaction History
              Text('Transaction History', style: AppTextStyles.h6),
              const SizedBox(height: AppSpacing.md),

              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return _buildEmptyState();
                  }
                  return Column(
                    children: [
                      for (var i = 0;
                          i < transactions.take(20).length;
                          i++)
                        _buildTransactionTile(transactions[i], theme)
                            .staggeredEntrance(i),
                    ],
                  );
                },
                loading: () => Column(
                  children: List.generate(
                    4,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ShimmerCard(height: 72),
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('Failed to load transactions',
                      style: AppTextStyles.bodyMedium),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, dynamic>? wallet) {
    final available = (wallet?['available_balance'] ?? 0).toDouble();
    final escrow = (wallet?['escrow_balance'] ?? 0).toDouble();
    final earnings = (wallet?['total_earnings'] ?? 0).toDouble();
    final withdrawn = (wallet?['total_withdrawn'] ?? 0).toDouble();
    final currency = wallet?['currency'] ?? 'INR';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.allXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '\u20b9${_formatAmount(available)}',
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.xl - 4),
          Row(
            children: [
              _BalanceStat(
                label: 'Escrow',
                value: '\u20b9${_formatAmount(escrow)}',
              ),
              const SizedBox(width: AppSpacing.xl),
              _BalanceStat(
                label: 'Earnings',
                value: '\u20b9${_formatAmount(earnings)}',
              ),
              const SizedBox(width: AppSpacing.xl),
              _BalanceStat(
                label: 'Withdrawn',
                value: '\u20b9${_formatAmount(withdrawn)}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              currency,
              style: AppTextStyles.caption.copyWith(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
      Map<String, dynamic> transaction, ThemeData theme) {
    final type = transaction['type'] as String;
    final amount = (transaction['amount'] ?? 0).toDouble();
    final status = transaction['status'] as String? ?? 'pending';
    final method = transaction['payment_method'] ?? transaction['method'] ?? '';
    final createdAt = DateTime.tryParse(transaction['created_at'] ?? '');
    final dateStr = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
        : '';

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    final isDeposit = type == 'deposit';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isDeposit ? AppColors.success : AppColors.primary)
                  .withOpacity(0.1),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(
              isDeposit ? Iconsax.money_add : Iconsax.money_send,
              color: isDeposit ? AppColors.success : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeposit ? 'Deposit' : 'Withdrawal',
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '$method \u2022 $dateStr',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDeposit ? '+' : '-'}\u20b9${_formatAmount(amount)}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isDeposit
                      ? AppColors.success
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm - 4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Iconsax.empty_wallet,
      title: 'No transactions yet',
      subtitle: 'Your deposit and withdrawal history will appear here',
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;

  const _BalanceStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
