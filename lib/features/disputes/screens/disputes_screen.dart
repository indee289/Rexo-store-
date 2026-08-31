import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/disputes_provider.dart';

class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputesAsync = ref.watch(userDisputesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Disputes',
        showBack: true,
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/disputes/raise'),
            icon: const Icon(Iconsax.add, size: 18, color: AppColors.primary),
            label: Text(
              'Raise',
              style: AppTextStyles.labelLarge.copyWith(
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: disputes.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return _buildDisputeCard(context, disputes[index]);
              },
            ),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => _buildErrorState(ref, ErrorUtils.sanitize(error)),
      ),
    );
  }

  Widget _buildDisputeCard(BuildContext context, Map<String, dynamic> dispute) {
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

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
              _buildStatusBadge(context, status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formattedDate,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'open':
        badgeColor = AppColors.roleBrand;
        break;
      case 'investigating':
        badgeColor = AppColors.warning;
        break;
      case 'resolved':
        badgeColor = AppColors.success;
        break;
      case 'closed':
        badgeColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
        break;
      default:
        badgeColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: AppRadius.pillAll,
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
    return const EmptyState(
      icon: Iconsax.message_question,
      title: 'No disputes',
      subtitle: 'You have no active disputes at the moment',
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error) {
    return EmptyState(
      icon: Iconsax.warning_2,
      title: 'Failed to load disputes',
      subtitle: error,
      ctaLabel: 'Retry',
      ctaIcon: Iconsax.refresh,
      onCta: () => ref.invalidate(userDisputesProvider),
    );
  }
}
