import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/premium_sheet.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/kyc_provider.dart';

class KycUploadScreen extends ConsumerStatefulWidget {
  const KycUploadScreen({super.key});

  @override
  ConsumerState<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends ConsumerState<KycUploadScreen> {
  String _selectedDocType = 'aadhaar';
  File? _selectedFile;
  bool _isUploading = false;

  final _documentTypes = [
    {'value': 'aadhaar', 'label': 'Aadhaar Card'},
    {'value': 'pan', 'label': 'PAN Card'},
    {'value': 'passport', 'label': 'Passport'},
  ];

  @override
  Widget build(BuildContext context) {
    final kycAsync = ref.watch(kycDocumentsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'KYC Verification', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: AppRadius.allMd,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.shield_tick,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Complete KYC verification to unlock full platform features including withdrawals and campaign payments.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Document type selector
            Text(
              'Document Type',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: AppRadius.allMd,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDocType,
                  isExpanded: true,
                  icon: const Icon(Iconsax.arrow_down_1),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  items: _documentTypes
                      .map((type) => DropdownMenuItem<String>(
                            value: type['value'],
                            child: Text(type['label']!),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDocType = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Image picker area
            Text(
              'Upload Document',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _showImagePicker,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.allMd,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedFile != null
                    ? ClipRRect(
                        borderRadius: AppRadius.allMd,
                        child: Image.file(
                          _selectedFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.document_upload,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Tap to upload document',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Camera or Gallery',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Upload button
            PremiumButton(
              label: 'Upload Document',
              gradient: true,
              loading: _isUploading,
              onPressed: _selectedFile != null && !_isUploading
                  ? _uploadDocument
                  : null,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Previous submissions
            Text(
              'Submitted Documents',
              style: AppTextStyles.h6,
            ),
            const SizedBox(height: AppSpacing.md),
            kycAsync.when(
              data: (documents) {
                if (documents.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: EmptyState(
                      icon: Iconsax.document,
                      title: 'No documents submitted yet',
                    ),
                  );
                }
                return Column(
                  children: documents
                      .map((doc) => _buildDocumentCard(doc))
                      .toList(),
                );
              },
              loading: () => const ShimmerLoading(),
              error: (_, __) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(kycDocumentsProvider),
                  child: Text(
                    'Retry loading documents',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final status = doc['status'] as String? ?? 'pending';
    final docType = doc['document_type'] as String? ?? '';
    final createdAt = doc['created_at'] as String? ?? '';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
      case 'verified':
        statusColor = AppColors.success;
        statusIcon = Iconsax.tick_circle;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Iconsax.close_circle;
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Iconsax.clock;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(
              Iconsax.document_text,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docType.toUpperCase(),
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (createdAt.isNotEmpty)
                  Text(
                    'Submitted: ${_formatDate(createdAt)}',
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: AppRadius.pillAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  void _showImagePicker() {
    showPremiumSheet<void>(
      context: context,
      title: 'Select Image Source',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Iconsax.camera, color: AppColors.primary),
            title: Text('Camera', style: AppTextStyles.bodyMedium),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.gallery, color: AppColors.primary),
            title: Text('Gallery', style: AppTextStyles.bodyMedium),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    final success = await ref.read(kycActionsProvider.notifier).uploadDocument(
          file: _selectedFile!,
          documentType: _selectedDocType,
        );

    setState(() {
      _isUploading = false;
      if (success) _selectedFile = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Document uploaded successfully'
                : 'Failed to upload document. Try again.',
            style: AppTextStyles.bodyMedium,
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}
