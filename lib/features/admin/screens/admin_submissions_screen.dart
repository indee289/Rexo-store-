import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

class AdminSubmissionsScreen extends ConsumerWidget {
  const AdminSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return _buildAccessDenied(context);

    final submissionsAsync = ref.watch(adminSubmissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Submission Review',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: submissionsAsync.when(
        data: (submissions) {
          if (submissions.isEmpty) {
            return _buildEmpty();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index];
              return _buildSubmissionCard(context, ref, submission);
            },
          );
        },
        loading: () => const ShimmerLoading(height: 400),
        error: (error, _) => _buildError(ref),
      ),
    );
  }

  Widget _buildSubmissionCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> submission,
  ) {
    final campaignTitle = submission['campaigns']?['title'] ?? 'Unknown Campaign';
    final creatorName = submission['users']?['name'] ?? 'Unknown Creator';
    final submissionId = submission['id'] as String;
    final creatorId = submission['user_id'] as String;
    final content = submission['content_url'] ?? submission['content'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaignTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'By: $creatorName',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pending',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            if (content.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                content.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context, ref, submissionId),
                    icon: const Icon(Iconsax.close_circle, size: 16),
                    label: Text('Reject', style: GoogleFonts.poppins(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final success = await ref
                          .read(adminActionsProvider.notifier)
                          .approveSubmission(submissionId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Approved' : 'Failed'),
                            backgroundColor: success ? AppColors.success : AppColors.error,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Iconsax.tick_circle, size: 16),
                    label: Text('Approve', style: GoogleFonts.poppins(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showPayoutDialog(context, ref, submissionId, creatorId),
                  icon: const Icon(Iconsax.money_send, color: Color(0xFF2196F3)),
                  tooltip: 'Disburse Payout',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, String submissionId) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Submission', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(
            hintText: 'Reason for rejection...',
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textHint),
            border: const OutlineInputBorder(),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(adminActionsProvider.notifier)
                  .rejectSubmission(submissionId, notesController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Submission rejected' : 'Failed'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: Text('Reject', style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showPayoutDialog(BuildContext context, WidgetRef ref, String submissionId, String creatorId) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disburse Payout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: amountController,
          decoration: InputDecoration(
            hintText: 'Amount to pay',
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textHint),
            prefixText: '\u20B9 ',
            border: const OutlineInputBorder(),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              Navigator.pop(ctx);
              final success = await ref
                  .read(adminActionsProvider.notifier)
                  .disburseSubmissionPayout(submissionId, creatorId, amount);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Payout disbursed' : 'Failed'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: Text('Pay', style: GoogleFonts.poppins(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Submission Review', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.lock, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Access Denied', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.document_text, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No pending submissions', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.warning_2, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Failed to load submissions', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
          TextButton(
            onPressed: () => ref.invalidate(adminSubmissionsProvider),
            child: Text('Retry', style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
