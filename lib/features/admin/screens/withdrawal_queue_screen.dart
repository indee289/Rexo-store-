import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/admin_provider.dart';

/// Admin withdrawal queue — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over admin-local `PremiumCard`s, with the
/// approve/reject pair built from an `ElevatedButton.icon` and an
/// `OutlinedButton.icon` carrying inline `styleFrom` colours, and bare
/// icon-plus-`Text` blocks for the empty and error states.
///
/// New layout: a collapsing large title, cards on the shared surface with the
/// amount as the leading figure, the actions as a destructive/confirm
/// `GlassButton` pair, and the shared glass states with pull-to-refresh and a
/// retry.
///
/// `adminWithdrawalsProvider`, `approveWithdrawal`, `rejectWithdrawal` and the
/// `_payoutSummary` reading of `payout_details` (including the account-number
/// masking) are unchanged.
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

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminWithdrawalsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GlassLargeTitleHeader(
              title: 'Withdrawal queue',
              subtitle: 'Approve or reject payout requests',
              showBack: true,
            ),
            withdrawals.when(
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.tick_circle,
                      title: 'No pending withdrawals',
                      message: 'The queue is clear.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => AppSpacing.gapMd,
                    itemBuilder: (context, index) => RepaintBoundary(
                      child: _WithdrawalCard(
                        withdrawal: list[index],
                        payoutSummary: _payoutSummary(list[index]),
                        onApprove: () => ref
                            .read(adminActionsProvider.notifier)
                            .approveWithdrawal(list[index]['id']),
                        onReject: () => ref
                            .read(adminActionsProvider.notifier)
                            .rejectWithdrawal(list[index]['id']),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: GlassListSkeleton(itemCount: 5),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: GlassErrorState(
                  message: ErrorUtils.sanitize(error),
                  onRetry: () => ref.invalidate(adminWithdrawalsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final Map<String, dynamic> withdrawal;
  final String? payoutSummary;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _WithdrawalCard({
    required this.withdrawal,
    required this.payoutSummary,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The amount leads — it is what the reviewer is deciding on.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '\u20B9${withdrawal['amount'] ?? 0}',
                  style: AppTextStyles.title2.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GlassChip(
                label: '#${_shortId(withdrawal['id'])}',
                dense: true,
              ),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            'User: ${_shortId(withdrawal['user_id'], fallback: 'Unknown')}',
            style: AppTextStyles.footnote
                .copyWith(color: AppColors.textSecondary),
          ),
          if (payoutSummary != null) ...[
            const SizedBox(height: 2),
            Text(
              payoutSummary!,
              style: AppTextStyles.footnote
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Approve',
                  icon: AppIcons.tick_circle,
                  size: GlassButtonSize.small,
                  onPressed: onApprove,
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: GlassButton.outline(
                  label: 'Reject',
                  icon: AppIcons.close_circle,
                  size: GlassButtonSize.small,
                  onPressed: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// First 8 characters of an id, or the whole thing when it is shorter.
///
/// The old code called `.substring(0, 8)` directly, which throws on any id
/// shorter than 8 characters; this keeps the same display and cannot throw.
String _shortId(Object? id, {String fallback = ''}) {
  final s = id?.toString() ?? '';
  if (s.isEmpty) return fallback;
  return s.length >= 8 ? s.substring(0, 8) : s;
}
