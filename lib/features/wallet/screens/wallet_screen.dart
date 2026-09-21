import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/utils/error_utils.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              // ── Balance card ────────────────────────────────────────────
              walletAsync.when(
                data: (wallet) => _buildBalanceCard(context, wallet),
                loading: () => const ShimmerCard(height: 180),
                error: (e, _) => _buildBalanceCard(context, null),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Transactions ────────────────────────────────────────────
              Text(
                'Recent transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const EmptyState(
                      icon: Iconsax.receipt,
                      title: 'No transactions yet',
                      subtitle:
                          'Your deposits, withdrawals and earnings will show up here.',
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0;
                          i < transactions.take(20).length;
                          i++)
                        _buildTransactionTile(context, transactions[i])
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
                error: (e, _) => EmptyState(
                  icon: Iconsax.warning_2,
                  title: "Couldn't load your transactions",
                  subtitle: ErrorUtils.sanitize(e),
                  ctaLabel: 'Retry',
                  ctaIcon: Iconsax.refresh,
                  onCta: () => ref.invalidate(transactionsProvider),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, Map<String, dynamic>? wallet) {
    final available = (wallet?['available_balance'] ?? 0).toDouble();
    final escrow = (wallet?['escrow_balance'] ?? 0).toDouble();
    final earnings = (wallet?['total_earnings'] ?? 0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadius.allXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: AppRadius.allSm,
                ),
                child: const Icon(Iconsax.wallet_2,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Total balance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Use content-driven height with maxLines + overflow instead of
          // FittedBox.scaleDown which aggressively shrinks fonts at large text scale.
          Text(
            '₹${_formatAmount(available)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.05,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: AppRadius.allMd,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _BalanceStat(
                      icon: Iconsax.lock,
                      label: 'Escrow',
                      value: '₹${_formatAmount(escrow)}'),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: Colors.white.withOpacity(0.18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _BalanceStat(
                      icon: Iconsax.money_recive,
                      label: 'Earnings',
                      value: '₹${_formatAmount(earnings)}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Deposit / Withdraw actions. On comfortable widths they sit
          // side by side; on very narrow phones (or at the largest text
          // scale) they stack full-width so the 'Withdraw' label is never
          // clipped to 'Withdr...'. No fixed pixel width, no shrunken font.
          LayoutBuilder(
            builder: (context, constraints) {
              final depositBtn = PremiumButton(
                label: 'Deposit',
                variant: PremiumButtonVariant.glass,
                icon: Iconsax.money_add,
                onPressed: () => context.push('/wallet/deposit'),
              );
              final withdrawBtn = PremiumButton(
                label: 'Withdraw',
                variant: PremiumButtonVariant.glass,
                icon: Iconsax.money_send,
                onPressed: () => context.push('/wallet/withdraw'),
              );

              // Estimate the width one button needs for its icon + full
              // 'Withdraw' label at the current text scale. If two buttons
              // plus the gap don't fit, stack them.
              final scale = MediaQuery.textScalerOf(context).scale(15);
              final estButtonWidth = 32 + 18 + 8 + ('Withdraw'.length * scale * 0.62);
              final fitsSideBySide =
                  constraints.maxWidth >= (estButtonWidth * 2) + 12;

              if (fitsSideBySide) {
                return Row(
                  children: [
                    Expanded(child: depositBtn),
                    const SizedBox(width: 12),
                    Expanded(child: withdrawBtn),
                  ],
                );
              }
              return Column(
                children: [
                  depositBtn,
                  const SizedBox(height: 12),
                  withdrawBtn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
      BuildContext context, Map<String, dynamic> transaction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final type = transaction['type'] as String;
    final amount = (transaction['amount'] ?? 0).toDouble();
    final status = transaction['status'] as String? ?? 'pending';
    final method =
        transaction['payment_method'] ?? transaction['method'] ?? '';
    final createdAt =
        DateTime.tryParse(transaction['created_at'] ?? '');
    final dateStr = createdAt != null
        ? DateFormat('dd MMM yyyy').format(createdAt)
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
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isDeposit ? AppColors.success : AppColors.primary)
                  .withOpacity(0.10),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(
              isDeposit
                  ? Iconsax.money_add
                  : Iconsax.money_send,
              color: isDeposit
                  ? AppColors.success
                  : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeposit ? 'Deposit' : 'Withdrawal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  '$method • $dateStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDeposit ? '+' : '-'}₹${_formatAmount(amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDeposit ? AppColors.success : AppColors.error,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    _capitalize(status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a numeric amount into a clean, Indian-grouped string
  /// (e.g. 1234567.5 -> "12,34,567.5"). Falls back to a plain string
  /// if formatting fails for any reason.
  String _formatAmount(double amount) {
    try {
      return NumberFormat('#,##0.##', 'en_IN').format(amount);
    } catch (_) {
      return amount.toStringAsFixed(2);
    }
  }

  /// Capitalizes the first letter of a status string for badge display.
  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

/// Compact stat cell shown on the gradient balance card (Escrow / Earnings).
class _BalanceStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BalanceStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
