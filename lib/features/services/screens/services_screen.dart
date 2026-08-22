import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/services_provider.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(activeServicesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Creator Services',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service tools grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                _buildServiceCard(
                  context,
                  icon: Iconsax.document_text,
                  title: 'Media Kit',
                  subtitle: 'Generate your media kit',
                  color: const Color(0xFF2196F3),
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
                  color: const Color(0xFF9C27B0),
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // UGC Marketplace listings
            Text('UGC Marketplace', style: AppTextStyles.h6),
            const SizedBox(height: 12),
            servicesAsync.when(
              data: (services) {
                if (services.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.shop,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No services listed yet',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
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
              error: (error, _) => Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      size: 32,
                      color: AppColors.error.withOpacity(0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load services',
                      style: AppTextStyles.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(activeServicesProvider),
                      child: Text(
                        'Retry',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceListingCard(BuildContext context, Map<String, dynamic> service) {
    final title = service['title'] as String? ?? 'Service';
    final description = service['description'] as String? ?? '';
    final price = (service['price'] as num?)?.toDouble() ?? 0.0;
    final serviceType = service['service_type'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Iconsax.briefcase,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      serviceType,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontSize: 10,
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
    );
  }
}
