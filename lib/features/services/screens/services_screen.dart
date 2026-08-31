import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/services_provider.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(activeServicesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Creator Services', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service tools grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
              children: [
                _buildServiceCard(
                  context,
                  icon: Iconsax.document_text,
                  title: 'Media Kit',
                  subtitle: 'Generate your media kit',
                  color: AppColors.roleBrand,
                  onTap: () => context.push('/services/media-kit'),
                ),
                _buildServiceCard(
                  context,
                  icon: Iconsax.calculator,
                  title: 'Rate Calculator',
                  subtitle: 'Find your ideal rate',
                  color: AppColors.success,
                  onTap: () => context.push('/services/rate-calculator'),
                ),
                _buildServiceCard(
                  context,
                  icon: Iconsax.shop,
                  title: 'UGC Marketplace',
                  subtitle: 'Creator services',
                  color: AppColors.primary,
                  onTap: null,
                ),
                _buildServiceCard(
                  context,
                  icon: Iconsax.chart_2,
                  title: 'Analytics',
                  subtitle: 'Campaign stats',
                  color: AppColors.roleAdmin,
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // UGC Marketplace listings
            Text('UGC Marketplace', style: AppTextStyles.h6),
            const SizedBox(height: AppSpacing.md),
            servicesAsync.when(
              data: (services) {
                if (services.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: EmptyState(
                      icon: Iconsax.shop,
                      title: 'No services listed yet',
                    ),
                  );
                }
                return Column(
                  children: services.take(10).map((service) {
                    return _buildServiceListingCard(context, service);
                  }).toList(),
                );
              },
              loading: () => const ShimmerCard(height: 120),
              error: (error, _) => EmptyState(
                icon: Iconsax.warning_2,
                title: 'Failed to load services',
                ctaLabel: 'Retry',
                ctaIcon: Iconsax.refresh,
                onCta: () => ref.invalidate(activeServicesProvider),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadius.allMd,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceListingCard(
      BuildContext context, Map<String, dynamic> service) {
    final title = service['title'] as String? ?? 'Service';
    final description = service['description'] as String? ?? '';
    final price = (service['price'] as num?)?.toDouble() ?? 0.0;
    final serviceType = service['service_type'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: AppRadius.allSm,
              ),
              child: const Icon(
                Iconsax.briefcase,
                size: 22,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (serviceType.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.08),
                        borderRadius: AppRadius.allSm,
                      ),
                      child: Text(
                        serviceType,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '\u20B9${price.toStringAsFixed(0)}',
              style: AppTextStyles.h6.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
