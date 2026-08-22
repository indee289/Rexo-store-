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
import '../providers/subscriptions_provider.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final userSubsAsync = ref.watch(userSubscriptionsProvider);
    final actionState = ref.watch(subscriptionNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Subscriptions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active subscription section
            userSubsAsync.when(
              data: (subs) {
                final activeSubs = subs
                    .where((s) => s['status'] == 'active')
                    .toList();

                if (activeSubs.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Subscription', style: AppTextStyles.h6),
                      const SizedBox(height: 12),
                      ...activeSubs.map((sub) => _buildActiveSubCard(
                            context,
                            ref,
                            sub,
                            actionState.isProcessing,
                          )),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const ShimmerCard(height: 100),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Available plans
            Text('Available Plans', style: AppTextStyles.h6),
            const SizedBox(height: 12),
            plansAsync.when(
              data: (plans) {
                if (plans.isEmpty) {
                  return _buildEmptyState();
                }
                return Column(
                  children: plans
                      .map((plan) => _buildPlanCard(
                            context,
                            ref,
                            plan,
                            actionState.isProcessing,
                          ))
                      .toList(),
                );
              },
              loading: () => const ShimmerLoading(),
              error: (error, _) => _buildError(ref, ErrorUtils.sanitize(error)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> sub,
    bool isProcessing,
  ) {
    final status = sub['status'] as String? ?? 'active';
    final endsAt = sub['ends_at'] as String?;
    final subId = sub['id'] as String? ?? '';
    final planId = sub['plan_id'] as String? ?? '';

    String expiryLabel = '';
    if (endsAt != null) {
      final date = DateTime.tryParse(endsAt);
      if (date != null) {
        expiryLabel = DateFormat('dd MMM yyyy').format(date);
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.crown_1,
                  size: 20,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan: ${planId.substring(0, 8)}',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (expiryLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Expires: $expiryLabel',
              style: AppTextStyles.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                            'Cancel Subscription',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: const Text(
                            'Are you sure you want to cancel this subscription?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Yes, Cancel',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await ref
                            .read(subscriptionNotifierProvider.notifier)
                            .cancelSubscription(subId);
                        ref.invalidate(userSubscriptionsProvider);
                      }
                    },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Cancel Subscription',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> plan,
    bool isProcessing,
  ) {
    final name = plan['name'] as String? ?? 'Plan';
    final price = (plan['price'] as num?)?.toDouble() ?? 0.0;
    final features = plan['features'] as List<dynamic>? ?? [];
    final durationDays = plan['duration_days'] as int? ?? 30;
    final planId = plan['id'] as String? ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.crown_1,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.h6),
                    Text(
                      '$durationDays days',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Text(
                '\u20B9${price.toStringAsFixed(0)}',
                style: AppTextStyles.h4.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Features list
          if (features.isNotEmpty) ...[
            ...features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.tick_circle,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature.toString(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Subscribe button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      final success = await ref
                          .read(subscriptionNotifierProvider.notifier)
                          .subscribe(planId, durationDays);

                      if (success && context.mounted) {
                        ref.invalidate(userSubscriptionsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Subscribed successfully!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Subscribe', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Iconsax.crown_1,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No plans available yet',
              style: AppTextStyles.h5.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon!',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Iconsax.warning_2,
              size: 48,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text('Failed to load plans', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(subscriptionPlansProvider),
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
