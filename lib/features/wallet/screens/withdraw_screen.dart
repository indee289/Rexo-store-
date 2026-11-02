import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/wallet_provider.dart';

/// Withdraw — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over a form where every field was preceded by a
/// local `_label` helper printing a bare `Text`, and the method picker was two
/// hand-built `AnimatedContainer`s with their own selected/unselected border
/// logic.
///
/// New layout: collapsing large title; the available balance as a green-edged
/// card (it is the constraint the user is working against, so it stays at the
/// top); the method picker as a segmented control; field labels from the
/// shared text field; and the submit action pinned so it is reachable while
/// the bank fields are on screen.
///
/// `walletProvider`, `walletActionsProvider.submitWithdrawal`, the exact
/// method strings ('UPI' / 'Bank Transfer'), the payout-detail keys and every
/// validation rule are unchanged.
class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();

  /// Index maps into [_methods]; the string sent to the provider is unchanged.
  static const _methods = ['UPI', 'Bank Transfer'];
  int _methodIndex = 0;

  bool _isSubmitting = false;
  double _availableBalance = 0;

  String get _method => _methods[_methodIndex];

  @override
  void dispose() {
    _amountController.dispose();
    _upiIdController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      Map<String, dynamic> payoutDetails;
      if (_method == 'UPI') {
        payoutDetails = {'upi_id': _upiIdController.text.trim()};
      } else {
        payoutDetails = {
          'account_number': _accountNumberController.text.trim(),
          'ifsc_code': _ifscController.text.trim(),
          'account_holder_name': _accountHolderController.text.trim(),
        };
      }

      final success =
          await ref.read(walletActionsProvider.notifier).submitWithdrawal(
                amount: amount,
                method: _method,
                payoutDetails: payoutDetails,
              );

      if (success && mounted) {
        showGlassSnackBar(
          context,
          message: 'Withdrawal request submitted successfully!',
          tone: GlassToastTone.success,
        );
        context.pop();
      } else if (!success && mounted) {
        // submitWithdrawal returns false (instead of throwing) on failure —
        // previously the user saw nothing at all.
        final err = ref.read(walletActionsProvider).error;
        showGlassSnackBar(
          context,
          message: ErrorUtils.sanitize(err),
          tone: GlassToastTone.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: ErrorUtils.sanitize(e),
          tone: GlassToastTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    walletAsync.whenData((wallet) {
      if (wallet != null) {
        _availableBalance = (wallet['available_balance'] ?? 0).toDouble();
      }
    });

    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                GlassLargeTitleHeader(
                  title: 'Withdraw',
                  showBack: true,
                  onBack: () => context.pop(),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The balance is the constraint, so it leads.
                        GlassCard(
                          borderRadius: AppRadius.allLg,
                          rim: AppColors.success.withOpacity(0.28),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              const GlassIconBubble(
                                icon: AppIcons.wallet_2,
                                color: AppColors.success,
                                size: 40,
                                iconSize: 20,
                              ),
                              AppSpacing.gapMd,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Available balance',
                                      style: AppTextStyles.footnote.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '\u20B9'
                                      '${_availableBalance.toStringAsFixed(2)}',
                                      style: AppTextStyles.title1.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapXl,

                        GlassTextField(
                          controller: _amountController,
                          label: 'Amount',
                          hint: '0.00',
                          prefixText: '\u20B9 ',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an amount';
                            }
                            final amount = double.tryParse(value.trim());
                            if (amount == null || amount <= 0) {
                              return 'Please enter a valid amount';
                            }
                            if (amount > _availableBalance) {
                              return 'Amount exceeds available balance';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapLg,

                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            bottom: AppSpacing.sm,
                          ),
                          child: Text(
                            'Withdrawal method',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        GlassTabBar(
                          labels: _methods,
                          selectedIndex: _methodIndex,
                          onSelected: (i) =>
                              setState(() => _methodIndex = i),
                          margin: EdgeInsets.zero,
                        ),
                        AppSpacing.gapLg,

                        if (_method == 'UPI')
                          GlassTextField(
                            controller: _upiIdController,
                            label: 'UPI ID',
                            hint: 'yourname@upi',
                            prefixIcon: AppIcons.user_tag,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'UPI ID is required';
                              }
                              return null;
                            },
                          )
                        else ...[
                          GlassTextField(
                            controller: _accountNumberController,
                            label: 'Account number',
                            hint: 'Enter account number',
                            prefixIcon: AppIcons.hashtag,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Account number is required'
                                    : null,
                          ),
                          AppSpacing.gapLg,
                          GlassTextField(
                            controller: _ifscController,
                            label: 'IFSC code',
                            hint: 'e.g. SBIN0001234',
                            prefixIcon: AppIcons.building,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'IFSC code is required'
                                    : null,
                          ),
                          AppSpacing.gapLg,
                          GlassTextField(
                            controller: _accountHolderController,
                            label: 'Account holder name',
                            hint: 'Enter name',
                            prefixIcon: AppIcons.user,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Account holder name is required'
                                    : null,
                          ),
                        ],
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: GlassButton(
              label: 'Submit withdrawal',
              loading: _isSubmitting,
              size: GlassButtonSize.large,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
