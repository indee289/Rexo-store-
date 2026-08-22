import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

class AdminDisputesScreen extends ConsumerWidget {
  const AdminDisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return _buildAccessDenied(context);

    final disputesAsync = ref.watch(adminDisputesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Disputes',
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
      body: disputesAsync.when(
        data: (disputes) {
          if (disputes.isEmpty) {
            return _buildEmpty();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: disputes.length,
            itemBuilder: (context, index) {
              final dispute = disputes[index];
              return _buildDisputeCard(context, ref, dispute);
            },
          );
        },
        loading: () => const ShimmerLoading(height: 400),
        error: (error, _) => _buildError(ref),
      ),
    );
  }

  Widget _buildDisputeCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> dispute,
  ) {
    final disputeId = dispute['id'] as String;
    final status = dispute['status'] ?? 'open';
    final reason = dispute['reason'] ?? 'No reason provided';
    final userName = dispute['users']?['name'] ?? 'Unknown';
    final createdAt = dispute['created_at'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumCard(
        onTap: () => _showDisputeDetails(context, ref, dispute),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dispute by $userName',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                createdAt.toString().substring(0, 10),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'open':
        color = AppColors.warning;
        break;
      case 'investigating':
        color = const Color(0xFF2196F3);
        break;
      case 'resolved':
        color = AppColors.success;
        break;
      case 'closed':
        color = AppColors.textSecondary;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showDisputeDetails(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> dispute,
  ) {
    final disputeId = dispute['id'] as String;
    final status = dispute['status'] ?? 'open';
    final reason = dispute['reason'] ?? '';
    final userName = dispute['users']?['name'] ?? 'Unknown';
    final resolutionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dispute Details',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'User: $userName',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: $status',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: $reason',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
            ),
            if (status != 'resolved' && status != 'closed') ...[
              const SizedBox(height: 16),
              TextField(
                controller: resolutionController,
                decoration: InputDecoration(
                  hintText: 'Resolution notes...',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textHint),
                  border: const OutlineInputBorder(),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await ref
                        .read(adminActionsProvider.notifier)
                        .resolveDispute(disputeId, resolutionController.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Dispute resolved' : 'Action failed'),
                          backgroundColor: success ? AppColors.success : AppColors.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Resolve Dispute',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Disputes', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
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
          const Icon(Iconsax.message_question, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No disputes found', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
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
          Text('Failed to load disputes', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
          TextButton(
            onPressed: () => ref.invalidate(adminDisputesProvider),
            child: Text('Retry', style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
