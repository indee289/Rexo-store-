import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../providers/wallet_provider.dart';

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
  String _method = 'UPI';
  bool _isSubmitting = false;

  double _availableBalance = 0;

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
        payoutDetails = {
          'upi_id': _upiIdController.text.trim(),
        };
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Withdrawal request submitted successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.sanitize(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletAsync = ref.watch(walletProvider);

    walletAsync.whenData((wallet) {
      if (wallet != null) {
        _availableBalance = (wallet['available_balance'] ?? 0).toDouble();
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Withdraw Funds',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl - 4),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available balance display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: AppRadius.allMd,
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.wallet_2,
                        color: AppColors.success, size: 24),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Available Balance',
                            style: AppTextStyles.bodySmall),
                        Text(
                          '\u20b9${_availableBalance.toStringAsFixed(2)}',
                          style: AppTextStyles.h5
                              .copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Amount
              Text('Amount', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _amountController,
                hint: '0.00',
                prefixText: '\u20b9 ',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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

              const SizedBox(height: AppSpacing.xl - 4),

              // Method dropdown
              Text('Withdrawal Method', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _method,
                items: const [
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  DropdownMenuItem(
                      value: 'Bank Transfer', child: Text('Bank Transfer')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _method = value);
                  }
                },
                decoration: const InputDecoration(),
              ),

              const SizedBox(height: AppSpacing.xl - 4),

              // Payout details based on method
              if (_method == 'UPI') ...[
                Text('UPI ID', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                PremiumTextField(
                  controller: _upiIdController,
                  hint: 'yourname@upi',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'UPI ID is required';
                    }
                    return null;
                  },
                ),
              ] else ...[
                Text('Account Number', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                PremiumTextField(
                  controller: _accountNumberController,
                  hint: 'Enter account number',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Account number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('IFSC Code', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                PremiumTextField(
                  controller: _ifscController,
                  hint: 'e.g. SBIN0001234',
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'IFSC code is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Account Holder Name', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                PremiumTextField(
                  controller: _accountHolderController,
                  hint: 'Enter account holder name',
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Account holder name is required';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),

              // Submit button
              PremiumButton(
                label: 'Submit Withdrawal',
                gradient: true,
                loading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
