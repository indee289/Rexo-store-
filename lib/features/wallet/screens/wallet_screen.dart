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
              walletAsync.when(
                data: (wallet) => _BalanceHeroCard(wallet: wallet),
                loading: () => const ShimmerCard(height: 210),
                error: (e, _) => const _BalanceHeroCard(wallet: null),
              ),

              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Text(
                    'Recent activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const EmptyState(
                      icon: Iconsax.receipt,
                      title: 'No activity yet',
                      subtitle:
                          'Your earnings and withdrawals will appear here.',
                    );
                  }
                  final visible = transactions.take(20).toList();
                  return Column(
                    children: [
                      for (var i = 0; i < visible.length; i++)
                        _TransactionTile(transaction: visible[i])
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
                  title: "Couldn't load your activity",
                  subtitle: ErrorUtils.sanitize(e),
                  ctaLabel: 'Retry',
                  ctaIcon: Iconsax.refresh,
                  onCta: () => ref.invalidate(transactionsProvider),
                ),
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium gradient "hero" balance card: big available balance, two stat
/// chips (Escrow / Earnings) and a full-width Withdraw action.
class _BalanceHeroCard extends StatelessWidget {
  final Map<String, dynamic>? wallet;

  const _BalanceHeroCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final available = _toDouble(wallet?['available_balance']);
    final escrow = _toDouble(wallet?['escrow_balance']);
    final earnings = _toDouble(wallet?['total_earnings']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: AppRadius.allXl,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.wallet_3,
                  size: 16, color: Colors.white.withOpacity(0.85)),
              const SizedBox(width: 6),
              Text(
                'Available balance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${_formatAmount(available)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _GlassStat(
                  icon: Iconsax.lock_1,
                  label: 'In escrow',
                  value: '₹${_formatAmount(escrow)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassStat(
                  icon: Iconsax.money_recive,
                  label: 'Total earned',
                  value: '₹${_formatAmount(earnings)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PremiumButton(
            label: 'Withdraw',
            icon: Iconsax.money_send,
            variant: PremiumButtonVariant.glass,
            expand: true,
            onPressed: () => context.push('/wallet/withdraw'),
          ),
        ],
      ),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _formatAmount(double amount) {
    try {
      return NumberFormat('#,##0.##', 'en_IN').format(amount);
    } catch (_) {
      return amount.toStringAsFixed(2);
    }
  }
}

/// Translucent stat chip used inside the gradient hero card.
class _GlassStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GlassStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.white.withOpacity(0.85)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single wallet activity row (withdrawal). Status colours now match the
/// real `withdrawals.status` values: pending / processing / completed /
/// rejected.
class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amount = _toDouble(transaction['amount']);
    final status = (transaction['status'] ?? 'pending').toString().toLowerCase();
    final method =
        (transaction['payment_method'] ?? transaction['method'] ?? '')
            .toString();
    final createdAt = DateTime.tryParse(
        (transaction['created_at'] ?? transaction['createdAt'] ?? '')
            .toString());
    final dateStr =
        createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '';
    final statusColor = _statusColor(status);
    final subtitle =
        [if (method.isNotEmpty) method, if (dateStr.isNotEmpty) dateStr]
            .join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: AppRadius.allMd,
            ),
            child: const Icon(Iconsax.money_send,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdrawal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-₹${_formatAmount(amount)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  _capitalize(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'processing':
        return AppColors.primary;
      case 'rejected':
      case 'failed':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _formatAmount(double amount) {
    try {
      return NumberFormat('#,##0.##', 'en_IN').format(amount);
    } catch (_) {
      return amount.toStringAsFixed(2);
    }
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
