import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../services/r2_storage_service.dart';
import '../../../services/supabase_service.dart';
import '../providers/wallet_provider.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionRefController = TextEditingController();
  String _paymentMethod = 'UPI';
  XFile? _proofFile;
  bool _isSubmitting = false;

  final List<String> _paymentMethods = ['UPI', 'Bank Transfer', 'Other'];

  @override
  void dispose() {
    _amountController.dispose();
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
    final filePath = 'deposit-proofs/${user.id}/$fileName';

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

      final amount = double.parse(_amountController.text.trim());

      final success =
          await ref.read(walletActionsProvider.notifier).submitDeposit(
                amount: amount,
                paymentMethod: _paymentMethod,
                transactionRef: _transactionRefController.text.trim(),
                proofUrl: proofUrl,
              );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Deposit request submitted successfully!'),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Deposit Funds',
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
              // Amount field
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
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.xl - 4),

              // Payment method dropdown
              Text('Payment Method', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
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
                decoration: const InputDecoration(),
              ),

              const SizedBox(height: AppSpacing.xl - 4),

              // Transaction reference
              Text('Transaction Reference', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              PremiumTextField(
                controller: _transactionRefController,
                hint: 'Enter transaction ID or reference',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Transaction reference is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.xl - 4),

              // Upload proof
              Text('Payment Proof (optional)',
                  style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.allMd,
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: _proofFile != null
                      ? ClipRRect(
                          borderRadius: AppRadius.allMd,
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
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tap to upload screenshot',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Submit button
              PremiumButton(
                label: 'Submit Deposit',
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
