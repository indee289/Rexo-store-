import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

class AdminDepositsScreen extends ConsumerWidget {
  const AdminDepositsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return _buildAccessDenied(context);

    final depositsAsync = ref.watch(adminDepositsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Deposit Queue',
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
      body: depositsAsync.when(
        data: (deposits) {
          if (deposits.isEmpty) {
            return _buildEmpty();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deposits.length,
            itemBuilder: (context, index) {
              final deposit = deposits[index];
              return _buildDepositCard(context, ref, deposit);
            },
          );
        },
        loading: () => const ShimmerLoading(height: 400),
        error: (error, _) => _buildError(ref),
      ),
    );
  }

  Widget _buildDepositCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> deposit,
  ) {
    final userName = deposit['users']?['name'] ?? 'Unknown';
    final amount = deposit['amount']?.toString() ?? '0';
    final method = deposit['payment_method'] ?? 'N/A';
    final depositId = deposit['id'] as String;
    final userId = deposit['user_id'] as String;
    final amountValue = (deposit['amount'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.warning.withOpacity(0.1),
                  child: const Icon(Iconsax.money_recive, color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Method: $method',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\u20B9$amount',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(context, ref, depositId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Reject', style: GoogleFonts.poppins(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmApprove(context, ref, depositId, userId, amountValue),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Approve', style: GoogleFonts.poppins(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmApprove(
    BuildContext context,
    WidgetRef ref,
    String depositId,
    String userId,
    double amount,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve Deposit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Approve deposit of \u20B9${amount.toStringAsFixed(2)} and credit user wallet?',
          style: GoogleFonts.poppins(fontSize: 14),
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
                  .approveDeposit(depositId, userId, amount);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Deposit approved' : 'Action failed'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: Text('Approve', style: GoogleFonts.poppins(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, String depositId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Deposit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: reasonController,
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
                  .rejectDeposit(depositId, reasonController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Deposit rejected' : 'Action failed'),
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

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Deposit Queue', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
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
          const Icon(Iconsax.money_recive, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No pending deposits', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
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
          Text('Failed to load deposits', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
          TextButton(
            onPressed: () => ref.invalidate(adminDepositsProvider),
            child: Text('Retry', style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
