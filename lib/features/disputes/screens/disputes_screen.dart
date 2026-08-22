import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/disputes_provider.dart';

class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputesAsync = ref.watch(userDisputesProvider);

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
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/disputes/raise'),
            icon: const Icon(Iconsax.add, size: 18, color: AppColors.primary),
            label: Text(
              'Raise',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: disputesAsync.when(
        data: (disputes) {
          if (disputes.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(userDisputesProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: disputes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildDisputeCard(disputes[index]);
              },
            ),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => _buildErrorState(ref, ErrorUtils.sanitize(error)),
      ),
    );
  }

  Widget _buildDisputeCard(Map<String, dynamic> dispute) {
    final status = dispute['status'] as String? ?? 'open';
    final subject = dispute['subject'] as String? ?? 'No Subject';
    final createdAt = dispute['created_at'] as String?;

    String formattedDate = '';
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        formattedDate = DateFormat('dd MMM yyyy').format(date);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedDate,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'open':
        badgeColor = const Color(0xFF2196F3);
        break;
      case 'investigating':
        badgeColor = AppColors.warning;
        break;
      case 'resolved':
        badgeColor = AppColors.success;
        break;
      case 'closed':
        badgeColor = AppColors.textHint;
        break;
      default:
        badgeColor = AppColors.textHint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: AppTextStyles.caption.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.message_question,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No disputes',
            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no active disputes at the moment',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text('Failed to load disputes', style: AppTextStyles.h5),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(userDisputesProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
