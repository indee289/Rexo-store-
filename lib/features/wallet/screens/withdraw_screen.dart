import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
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
        payoutDetails = {'upi_id': _upiIdController.text.trim()};
      } else {
        payoutDetails = {
          'account_number': _accountNumberController.text.trim(),
          'ifsc_code': _ifscController.text.trim(),
          'account_holder_name':
              _accountHolderController.text.trim(),
        };
      }

      final success = await ref
          .read(walletActionsProvider.notifier)
          .submitWithdrawal(
            amount: amount,
            method: _method,
            payoutDetails: payoutDetails,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Withdrawal request submitted successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
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
    final walletAsync = ref.watch(walletProvider);
    walletAsync.whenData((wallet) {
      if (wallet != null) {
        _availableBalance =
            (wallet['available_balance'] ?? 0).toDouble();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Withdraw',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Available balance ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.06),
                  borderRadius: AppRadius.allMd,
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.wallet_2,
                        color: AppColors.success, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '₹${_availableBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Amount ────────────────────────────────────────────────
              _label(context, 'Amount'),
              PremiumTextField(
                controller: _amountController,
                hint: '0.00',
                prefixText: '₹ ',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}')),
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

              const SizedBox(height: 24),

              // ── Method ────────────────────────────────────────────────
              _label(context, 'Withdrawal Method'),
              Row(
                children: ['UPI', 'Bank Transfer'].map((m) {
                  final selected = _method == m;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: m == 'UPI' ? 8 : 0),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _method = m),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                    .withOpacity(isDark ? 0.16 : 0.10)
                                : cardBg,
                            borderRadius: AppRadius.allMd,
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : borderColor,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            m,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.primary
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── Bank details ──────────────────────────────────────────
              if (_method == 'UPI') ...[
                _label(context, 'UPI ID'),
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
                _bankField(context, 'Account Number',
                    _accountNumberController,
                    'Enter account number', TextInputType.number),
                const SizedBox(height: AppSpacing.lg),
                _bankField(context, 'IFSC Code', _ifscController,
                    'e.g. SBIN0001234', null),
                const SizedBox(height: AppSpacing.lg),
                _bankField(context, 'Account Holder Name',
                    _accountHolderController, 'Enter name', null),
              ],

              const SizedBox(height: 32),

              PremiumButton(
                label: 'Submit Withdrawal',
                loading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );

  Widget _bankField(
    BuildContext context,
    String label,
    TextEditingController controller,
    String hint,
    TextInputType? keyboardType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, label),
        PremiumTextField(
          controller: controller,
          hint: hint,
          keyboardType: keyboardType,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return '$label is required';
            return null;
          },
        ),
      ],
    );
  }
}
