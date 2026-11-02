import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/wallet_provider.dart';

/// Wallet — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over a `SingleChildScrollView` containing a
/// gradient `Container` hero with two translucent `_GlassStat` boxes and the
/// Withdraw button inside it, then a bare `Text` heading above a column of
/// hand-built `_TransactionTile` containers.
///
/// New layout: collapsing large title; the balance hero keeps the brand fill
/// but the two sub-balances move **out** of it onto their own stat pills, so
/// the card states one number and the withdraw action is unobstructed;
/// activity becomes a titled section of rows with the amount and status as
/// trailing detail.
///
/// `walletProvider`, `transactionsProvider`, the `take(20)` cap, the status
/// colour mapping and the `/wallet/withdraw` route are unchanged.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
        onRefresh: () async {
          ref.invalidate(walletProvider);
          ref.invalidate(transactionsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            const GlassLargeTitleHeader(
              title: 'Wallet',
              automaticallyImplyLeading: false,
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: walletAsync.when(
                  data: (wallet) => _BalanceBlock(wallet: wallet),
                  loading: () => const _BalanceSkeleton(),
                  error: (e, _) => const _BalanceBlock(wallet: null),
                ),
              ),
            ),

            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: GlassEmptyState(
                      icon: AppIcons.receipt,
                      title: 'No activity yet',
                      message:
                          'Your earnings and withdrawals will appear here.',
                      compact: true,
                    ),
                  );
                }
                final visible = transactions.take(20).toList();
                return SliverToBoxAdapter(
                  child: GlassSection(
                    title: 'Recent activity',
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
                    ),
                    children: [
                      for (final t in visible) _TransactionRow(transaction: t),
                    ],
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: GlassLoader(),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: GlassErrorState(
                  compact: true,
                  title: "Couldn't load your activity",
                  message: ErrorUtils.sanitize(e),
                  onRetry: () => ref.invalidate(transactionsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand balance card plus the two sub-balance pills beneath it.
class _BalanceBlock extends StatelessWidget {
  const _BalanceBlock({required this.wallet});

  final Map<String, dynamic>? wallet;

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _format(double amount) {
    try {
      return NumberFormat('#,##0.##', 'en_IN').format(amount);
    } catch (_) {
      return amount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _toDouble(wallet?['available_balance']);
    final escrow = _toDouble(wallet?['escrow_balance']);
    final earnings = _toDouble(wallet?['total_earnings']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSurface(
          level: GlassLevel.card,
          borderRadius: AppRadius.allXl,
          gradient: AppColors.primaryGradient,
          bordered: false,
          shadow: AppElevation.brand(false),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    AppIcons.wallet_3,
                    size: 15,
                    color: Colors.white.withOpacity(0.82),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AVAILABLE BALANCE',
                    style: AppTextStyles.caption1.copyWith(
                      color: Colors.white.withOpacity(0.82),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '\u20B9${_format(available)}',
                  maxLines: 1,
                  style: AppTextStyles.largeTitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 42,
                    letterSpacing: -1,
                    height: 1.05,
                  ),
                ),
              ),
              AppSpacing.gapLg,
              GlassButton.glass(
                label: 'Withdraw',
                icon: AppIcons.money_send,
                onPressed: () => context.push('/wallet/withdraw'),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        // Sub-balances live outside the hero so the card states one number.
        Row(
          children: [
            Expanded(
              child: GlassStatPill(
                icon: AppIcons.lock_1,
                value: '\u20B9${_format(escrow)}',
                label: 'In escrow',
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: GlassStatPill(
                icon: AppIcons.money_recive,
                value: '\u20B9${_format(earnings)}',
                label: 'Total earned',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        GlassSkeleton(height: 182, borderRadius: AppRadius.allXl),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: GlassSkeleton(height: 72)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: GlassSkeleton(height: 72)),
          ],
        ),
      ],
    );
  }
}

/// A single wallet activity row (withdrawal). Status colours match the real
/// `withdrawals.status` values: pending / processing / completed / rejected.
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final Map<String, dynamic> transaction;

  static Color _statusColor(String status) {
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

  static String _format(double amount) {
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

  @override
  Widget build(BuildContext context) {
    final amount = _toDouble(transaction['amount']);
    final status =
        (transaction['status'] ?? 'pending').toString().toLowerCase();
    final method =
        (transaction['payment_method'] ?? transaction['method'] ?? '')
            .toString();
    final createdAt = DateTime.tryParse(
        (transaction['created_at'] ?? transaction['createdAt'] ?? '')
            .toString());
    final dateStr =
        createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '';
    final statusColor = _statusColor(status);

    final subtitle = [
      if (method.isNotEmpty) method,
      if (dateStr.isNotEmpty) dateStr,
    ].join('  ·  ');

    return GlassRow(
      icon: AppIcons.money_send,
      title: 'Withdrawal',
      subtitle: subtitle.isEmpty ? null : subtitle,
      showChevron: false,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '-\u20B9${_format(amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headline.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          GlassChip.status(
            label: _capitalize(status),
            color: statusColor,
          ),
        ],
      ),
    );
  }
}
