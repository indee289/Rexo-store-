import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/admin_provider.dart';

/// Admin wallets & escrow — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over admin-local `PremiumCard`s, each with a
/// hand-built tinted icon square, the frozen/active state as plain grey text,
/// two `OutlinedButton.icon`s carrying inline `styleFrom` colours, and an
/// unlabelled `IconButton` for freeze. The credit/debit flow was an
/// `AlertDialog` around a raw `TextField`.
///
/// New layout: a collapsing large title, cards on the shared surface with the
/// balance as the leading figure and the frozen state as a chip, the three
/// actions as labelled `GlassButton`s, and the amount flow as a glass sheet.
///
/// `adminWalletsProvider`, `creditWallet`, `debitWallet`, `freezeWallet` and
/// the rule that a non-positive amount neither dismisses nor posts are
/// unchanged.
class WalletsEscrowScreen extends ConsumerWidget {
  const WalletsEscrowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(adminWalletsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminWalletsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GlassLargeTitleHeader(
              title: 'Wallets & escrow',
              subtitle: 'Credit, debit and freeze balances',
              showBack: true,
            ),
            wallets.when(
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.wallet,
                      title: 'No wallets found',
                      message: 'Nothing to show yet.',
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
                    itemBuilder: (context, index) {
                      final wallet = list[index];
                      final id = wallet['id'];
                      return RepaintBoundary(
                        child: _WalletCard(
                          wallet: wallet,
                          onCredit: () =>
                              _showAmountSheet(context, ref, id.toString(), true),
                          onDebit: () => _showAmountSheet(
                              context, ref, id.toString(), false),
                          onFreeze: () => ref
                              .read(adminActionsProvider.notifier)
                              .freezeWallet(id),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: GlassListSkeleton(itemCount: 6),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: GlassErrorState(
                  message: ErrorUtils.sanitize(error),
                  onRetry: () => ref.invalidate(adminWalletsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Credit / debit flow.
  ///
  /// The gate is unchanged: a null or non-positive amount neither posts nor
  /// dismisses. The controller is now disposed — the old dialog leaked it.
  Future<void> _showAmountSheet(
    BuildContext context,
    WidgetRef ref,
    String walletId,
    bool isCredit,
  ) async {
    final controller = TextEditingController();
    try {
      await showGlassSheet<void>(
        context: context,
        title: isCredit ? 'Credit wallet' : 'Debit wallet',
        subtitle: 'Wallet #${_shortId(walletId)}',
        child: Builder(
          builder: (sheetContext) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassTextField(
                controller: controller,
                label: 'Amount',
                hint: '0.00',
                prefixText: '\u20B9 ',
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              AppSpacing.gapLg,
              GlassButton(
                label: isCredit ? 'Credit' : 'Debit',
                icon: isCredit ? AppIcons.add : AppIcons.minus,
                size: GlassButtonSize.medium,
                variant: isCredit
                    ? GlassButtonVariant.filled
                    : GlassButtonVariant.destructive,
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
                    Navigator.pop(sheetContext);
                  } else {
                    showGlassSnackBar(
                      sheetContext,
                      message: 'Enter an amount greater than zero.',
                      tone: GlassToastTone.error,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

class _WalletCard extends StatelessWidget {
  final Map<String, dynamic> wallet;
  final VoidCallback onCredit;
  final VoidCallback onDebit;
  final VoidCallback onFreeze;

  const _WalletCard({
    required this.wallet,
    required this.onCredit,
    required this.onDebit,
    required this.onFreeze,
  });

  @override
  Widget build(BuildContext context) {
    final isFrozen = wallet['is_frozen'] == true;

    return GlassCard(
      rim: isFrozen ? AppColors.warning.withOpacity(0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GlassIconBubble(
                icon: AppIcons.wallet,
                color: AppColors.accentBrown,
                size: 36,
                iconSize: 18,
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\u20B9${wallet['available_balance'] ?? 0}',
                      style: AppTextStyles.title3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Wallet #${_shortId(wallet['id'])}',
                      style: AppTextStyles.caption1
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapSm,
              GlassChip.status(
                label: isFrozen ? 'Frozen' : 'Active',
                color: isFrozen ? AppColors.warning : AppColors.success,
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: GlassButton.outline(
                  label: 'Credit',
                  icon: AppIcons.add,
                  size: GlassButtonSize.small,
                  onPressed: onCredit,
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: GlassButton.outline(
                  label: 'Debit',
                  icon: AppIcons.minus,
                  size: GlassButtonSize.small,
                  onPressed: onDebit,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          // Was an unlabelled IconButton in the action row.
          GlassButton.ghost(
            label: isFrozen ? 'Freeze again' : 'Freeze wallet',
            icon: AppIcons.lock,
            size: GlassButtonSize.small,
            expand: true,
            onPressed: onFreeze,
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
