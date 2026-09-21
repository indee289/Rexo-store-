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

    // Clean white card floating on Sand Dune background.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.allXl,
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Total balance" label
          Text(
            'Total balance',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          // Big balance number
          Text(
            '₹${_formatAmount(available)}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 20),

          // Escrow + Earnings row — two stat pills side by side
          Row(
            children: [
              Expanded(
                child: _WalletStatPill(
                  icon: Iconsax.lock,
                  label: 'Escrow',
                  value: '₹${_formatAmount(escrow)}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WalletStatPill(
                  icon: Iconsax.money_recive,
                  label: 'Earnings',
                  value: '₹${_formatAmount(earnings)}',
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Deposit + Withdraw — ALWAYS horizontal, equal width
          Row(
            children: [
              Expanded(
                child: _WalletActionButton(
                  label: 'Deposit',
                  icon: Iconsax.money_add,
                  filled: true,
                  onTap: () => context.push('/wallet/deposit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WalletActionButton(
                  label: 'Withdraw',
                  icon: Iconsax.money_send,
                  filled: false,
                  onTap: () => context.push('/wallet/withdraw'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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

/// Compact stat pill shown on the balance card (Escrow / Earnings).
class _WalletStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _WalletStatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppRadius.allMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wallet action button — filled (blue) or outlined (bordered).
class _WalletActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _WalletActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_WalletActionButton> createState() => _WalletActionButtonState();
}

class _WalletActionButtonState extends State<_WalletActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.7 : 1.0,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.filled ? AppColors.primary : Colors.white,
            borderRadius: AppRadius.allMd,
            border: widget.filled
                ? null
                : Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.filled
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.filled
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
