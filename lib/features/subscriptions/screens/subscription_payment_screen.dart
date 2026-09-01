import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../services/r2_storage_service.dart';
import '../../../services/supabase_service.dart';
import '../providers/subscriptions_provider.dart';

/// Manual subscription payment screen.
///
/// Mirrors the wallet deposit flow: shows the plan + amount to pay, the UPI /
/// bank details to pay to, a transaction-reference field and a payment-proof
/// image upload. On submit it records a row in `subscription_payments` with
/// status 'pending' (via [SubscriptionNotifier.submitSubscriptionPayment]).
/// It does NOT activate the subscription — an admin must approve the proof
/// first.
class SubscriptionPaymentScreen extends ConsumerStatefulWidget {
  const SubscriptionPaymentScreen({
    super.key,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.durationDays,
  });

  final String planId;
  final String planName;
  final double amount;
  final int durationDays;

  @override
  ConsumerState<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState
    extends ConsumerState<SubscriptionPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _transactionRefController = TextEditingController();
  String _paymentMethod = 'UPI';
  XFile? _proofFile;
  bool _isSubmitting = false;

  final List<String> _paymentMethods = ['UPI', 'Bank Transfer', 'Other'];

  // Merchant payment details users pay to. Kept in one place so it matches the
  // instructions shown for deposits.
  static const String _payUpiId = 'rexoagency@upi';
  static const String _payAccountName = 'Rexo Agency';
  static const String _payAccountNumber = '1234567890';
  static const String _payIfsc = 'HDFC0001234';
  static const String _payBankName = 'HDFC Bank';

  @override
  void dispose() {
    _transactionRefController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _proofFile = image;
      });
    }
  }

  Future<String?> _uploadProof() async {
    if (_proofFile == null) return null;

    final user = SupabaseService.currentUser;
    if (user == null) return null;

    final bytes = await _proofFile!.readAsBytes();
    final fileName = '${const Uuid().v4()}.jpg';
    final filePath = 'subscription-proofs/${user.id}/$fileName';

    final publicUrl = await R2StorageService.uploadFile(
      filePath,
      bytes,
      'image/jpeg',
    );

    return publicUrl;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      String? proofUrl;
      if (_proofFile != null) {
        proofUrl = await _uploadProof();
      }

      final success = await ref
          .read(subscriptionNotifierProvider.notifier)
          .submitSubscriptionPayment(
            planId: widget.planId,
            planName: widget.planName,
            durationDays: widget.durationDays,
            amount: widget.amount,
            paymentMethod: _paymentMethod,
            transactionRef: _transactionRefController.text.trim(),
            proofUrl: proofUrl,
          );

      if (!mounted) return;

      if (success) {
        ref.invalidate(userSubscriptionPaymentsProvider);
        // Show a confirmation dialog making it clear this is pending review.
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Payment submitted',
              style: AppTextStyles.h6,
            ),
            content: const Text(
              'Your subscription payment has been submitted and is pending '
              'admin approval. Your plan will activate once the payment proof '
              'is verified.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) context.pop();
      } else {
        final err = ref.read(subscriptionNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.sanitize(err)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Subscribe to ${widget.planName}',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Iconsax.crown_1,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.planName, style: AppTextStyles.h6),
                          Text('${widget.durationDays} days',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Text(
                      '\u20B9${widget.amount.toStringAsFixed(0)}',
                      style:
                          AppTextStyles.h4.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Payment instructions (UPI / bank details)
              Text('Pay to', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('UPI ID', _payUpiId),
                    const Divider(height: 20),
                    _detailRow('Account Name', _payAccountName),
                    _detailRow('Account Number', _payAccountNumber),
                    _detailRow('IFSC', _payIfsc),
                    _detailRow('Bank', _payBankName),
                    const SizedBox(height: 8),
                    Text(
                      'Pay the exact amount above, then enter your transaction '
                      'reference and upload the payment screenshot below.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Payment method dropdown
              Text('Payment Method', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                items: _paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
                decoration: _inputDecoration(theme),
              ),

              const SizedBox(height: 20),

              // Transaction reference
              Text('Transaction Reference', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _transactionRefController,
                decoration: _inputDecoration(
                  theme,
                  hintText: 'Enter transaction ID or reference',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Transaction reference is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Upload proof
              Text('Payment Proof', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: _proofFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_proofFile!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.image,
                              size: 32,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload screenshot',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Submit Payment', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.labelMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, {String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
    );
  }
}
