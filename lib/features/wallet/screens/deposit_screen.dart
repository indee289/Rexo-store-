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
  final List<int> _quickAmounts = [100, 500, 1000, 5000];

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
      setState(() => _proofFile = image);
    }
  }

  Future<String?> _uploadProof() async {
    if (_proofFile == null) return null;
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    final bytes = await _proofFile!.readAsBytes();
    final fileName = '${const Uuid().v4()}.jpg';
    final filePath = 'deposit-proofs/${user.id}/$fileName';
    return R2StorageService.uploadFile(filePath, bytes, 'image/jpeg');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      String? proofUrl;
      if (_proofFile != null) proofUrl = await _uploadProof();

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
          const SnackBar(
            content: Text('Deposit request submitted successfully!'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Deposit',
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
              // ── Amount input ──────────────────────────────────────────
              _label(context, 'Amount'),
              PremiumTextField(
                controller: _amountController,
                hint: '0.00',
                prefixText: '₹ ',
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
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
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // ── Quick amounts ─────────────────────────────────────────
              Wrap(
                spacing: 8,
                children: _quickAmounts
                    .map((amt) => GestureDetector(
                          onTap: () {
                            _amountController.text = '$amt';
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withOpacity(isDark ? 0.16 : 0.10),
                              borderRadius: AppRadius.pillAll,
                            ),
                            child: Text(
                              '₹$amt',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 24),

              // ── Payment method ────────────────────────────────────────
              _label(context, 'Payment Method'),
              Wrap(
                spacing: 8,
                children: _paymentMethods
                    .map((m) => GestureDetector(
                          onTap: () =>
                              setState(() => _paymentMethod = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _paymentMethod == m
                                  ? AppColors.primary
                                      .withOpacity(isDark ? 0.16 : 0.10)
                                  : cardBg,
                              borderRadius: AppRadius.allMd,
                              border: Border.all(
                                color: _paymentMethod == m
                                    ? AppColors.primary
                                    : borderColor,
                                width: _paymentMethod == m ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              m,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _paymentMethod == m
                                    ? AppColors.primary
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 24),

              // ── Transaction ref ───────────────────────────────────────
              _label(context, 'Transaction Reference'),
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

              const SizedBox(height: 24),

              // ── Upload proof ──────────────────────────────────────────
              _label(context, 'Payment Proof (optional)'),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: surfaceAlt,
                    borderRadius: AppRadius.allMd,
                    border: Border.all(color: borderColor),
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
                            Icon(Iconsax.image,
                                size: 30, color: cs.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload screenshot',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────────────────────
              PremiumButton(
                label: 'Proceed',
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
