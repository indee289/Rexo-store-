import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

class AdminWalletsScreen extends ConsumerWidget {
  const AdminWalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return _buildAccessDenied(context);

    final walletsAsync = ref.watch(adminWalletsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Wallets & Escrow',
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
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return _buildEmpty();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return _buildWalletCard(context, ref, wallet);
            },
          );
        },
        loading: () => const ShimmerLoading(height: 400),
        error: (error, _) => _buildError(ref),
      ),
    );
  }

  Widget _buildWalletCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> wallet,
  ) {
    final userName = wallet['users']?['name'] ?? 'Unknown';
    final userEmail = wallet['users']?['email'] ?? '';
    final userId = wallet['user_id'] as String;
    final available = (wallet['available_balance'] as num?)?.toDouble() ?? 0;
    final escrow = (wallet['escrow_balance'] as num?)?.toDouble() ?? 0;
    final isFrozen = wallet['is_frozen'] == true;

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
                  backgroundColor: const Color(0xFF3F51B5).withOpacity(0.1),
                  child: const Icon(Iconsax.wallet_1, color: Color(0xFF3F51B5), size: 20),
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
                        userEmail,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFrozen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Frozen',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint),
                      ),
                      Text(
                        '\u20B9${available.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escrow',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint),
                      ),
                      Text(
                        '\u20B9${escrow.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAmountDialog(context, ref, userId, 'credit'),
                    icon: const Icon(Iconsax.add_circle, size: 16),
                    label: Text('Credit', style: GoogleFonts.poppins(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAmountDialog(context, ref, userId, 'debit'),
                    icon: const Icon(Iconsax.money_send, size: 16),
                    label: Text('Debit', style: GoogleFonts.poppins(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    ref.read(adminActionsProvider.notifier).freezeWallet(userId, !isFrozen);
                  },
                  icon: Icon(
                    isFrozen ? Iconsax.unlock : Iconsax.lock,
                    color: isFrozen ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  tooltip: isFrozen ? 'Unfreeze' : 'Freeze',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAmountDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String type,
  ) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          type == 'credit' ? 'Credit Wallet' : 'Debit Wallet',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                hintText: 'Amount',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textHint),
                prefixText: '\u20B9 ',
                border: const OutlineInputBorder(),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textHint),
                border: const OutlineInputBorder(),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
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
              bool success;
              if (type == 'credit') {
                success = await ref
                    .read(adminActionsProvider.notifier)
                    .creditWallet(userId, amount, reason: reasonController.text);
              } else {
                success = await ref
                    .read(adminActionsProvider.notifier)
                    .debitWallet(userId, amount, reason: reasonController.text);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '${type == 'credit' ? 'Credited' : 'Debited'} successfully' : 'Action failed'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              type == 'credit' ? 'Credit' : 'Debit',
              style: GoogleFonts.poppins(
                color: type == 'credit' ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Wallets & Escrow', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
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
          const Icon(Iconsax.wallet_1, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No wallets found', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
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
          Text('Failed to load wallets', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
          TextButton(
            onPressed: () => ref.invalidate(adminWalletsProvider),
            child: Text('Retry', style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
